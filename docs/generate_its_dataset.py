"""
Synthetic Intelligent Transport System (ITS) dataset generator - Scotland
=========================================================================
Generates 100,000 hourly roadside-sensor observations for Jan 2023 - Dec 2025
across 7 Scottish cities and 9 strategic roads.

Design principles
-----------------
* Demand-driven: a latent hourly demand is built from base capacity x
  time-of-day x day-of-week x month x year-growth x event/holiday effects.
* Speed and journey time are derived from the volume/capacity ratio using a
  BPR-style (Bureau of Public Roads) congestion function, so speed falls
  monotonically as congestion rises.
* Weather is generated from month-specific climatology per city (west coast
  wetter, north/east colder) and feeds back into congestion, visibility,
  accident risk and speed.
* Vehicle mix varies by road type, hour and day type; the five vehicle class
  counts always sum exactly to Vehicle_Count (largest-remainder allocation).
* A controlled ~3.5% of records carry injected data-quality defects.

Author: senior transportation data science / synthetic data generation
"""

import csv
import math
import random
from datetime import datetime, timedelta, date

SEED = 20260809
random.seed(SEED)

N_RECORDS = 100_000
START = datetime(2023, 1, 1, 0, 0, 0)
END = datetime(2025, 12, 31, 23, 0, 0)
TOTAL_HOURS = int((END - START).total_seconds() // 3600) + 1

OUT_CSV = "scotland_its_dataset.csv"

# ---------------------------------------------------------------------------
# 1. Reference geography
# ---------------------------------------------------------------------------

COUNCIL = {
    "Glasgow": "Glasgow City",
    "Edinburgh": "City of Edinburgh",
    "Aberdeen": "Aberdeen City",
    "Dundee": "Dundee City",
    "Inverness": "Highland",
    "Stirling": "Stirling",
    "Perth": "Perth and Kinross",
}

# Relative traffic intensity of each city (Glasgow = 1.00)
CITY_INTENSITY = {
    "Glasgow": 1.00,
    "Edinburgh": 0.95,
    "Aberdeen": 0.71,
    "Dundee": 0.61,
    "Stirling": 0.57,
    "Perth": 0.54,
    "Inverness": 0.47,
}

# Share of all sensor observations by city (Glasgow / Edinburgh dominate)
CITY_SHARE = {
    "Glasgow": 0.245,
    "Edinburgh": 0.225,
    "Aberdeen": 0.135,
    "Dundee": 0.105,
    "Stirling": 0.100,
    "Perth": 0.100,
    "Inverness": 0.090,
}

# Rain propensity (west coast wettest) and temperature offset vs national mean
CITY_CLIMATE = {
    #            p_wet_mult, rain_mult, temp_offset_C, wind_mult
    "Glasgow":   (1.12, 1.20, +0.4, 0.95),
    "Edinburgh": (0.92, 0.80, +0.2, 1.05),
    "Aberdeen":  (0.90, 0.78, -0.7, 1.15),
    "Dundee":    (0.88, 0.75, -0.2, 1.05),
    "Inverness": (0.95, 0.85, -0.9, 1.00),
    "Stirling":  (1.02, 1.00, -0.1, 0.90),
    "Perth":     (0.98, 0.92, -0.2, 0.90),
}

# City centre coordinates (WGS84)
CITY_CENTRE = {
    "Glasgow":   (55.8642, -4.2518),
    "Edinburgh": (55.9533, -3.1883),
    "Aberdeen":  (57.1497, -2.0943),
    "Dundee":    (56.4620, -2.9707),
    "Inverness": (57.4778, -4.2247),
    "Stirling":  (56.1165, -3.9369),
    "Perth":     (56.3950, -3.4308),
}

ROAD_TYPE = {
    "M8": "Motorway", "M74": "Motorway", "M77": "Motorway", "M90": "Motorway",
    "A9": "Trunk Dual Carriageway", "A90": "Trunk Dual Carriageway",
    "A96": "Trunk Dual Carriageway", "A1": "Trunk Dual Carriageway",
    "A82": "Trunk Single Carriageway",
}

# Which roads serve which city, with a within-city weight
CITY_ROADS = {
    "Glasgow":   [("M8", 0.42), ("M74", 0.26), ("M77", 0.20), ("A82", 0.12)],
    "Edinburgh": [("M8", 0.34), ("A90", 0.26), ("A1", 0.22), ("M90", 0.18)],
    "Aberdeen":  [("A90", 0.52), ("A96", 0.48)],
    "Dundee":    [("A90", 0.62), ("A9", 0.20), ("A96", 0.18)],
    "Inverness": [("A9", 0.46), ("A96", 0.31), ("A82", 0.23)],
    "Stirling":  [("A9", 0.46), ("M90", 0.32), ("M8", 0.22)],
    "Perth":     [("A9", 0.44), ("M90", 0.34), ("A90", 0.22)],
}

# Speed limits in km/h converted from UK mph limits
LIMIT_BY_TYPE = {
    "Motorway": [(112, 0.72), (80, 0.20), (96, 0.08)],          # 70 / 50 (urban managed) / 60 mph
    "Trunk Dual Carriageway": [(112, 0.34), (96, 0.46), (64, 0.20)],
    "Trunk Single Carriageway": [(96, 0.55), (80, 0.25), (64, 0.20)],
}

# Freight intensity multiplier - M74/A9 are the strategic freight corridors
ROAD_FREIGHT = {"M74": 1.55, "A9": 1.35, "M90": 1.20, "A96": 1.15, "A90": 1.10,
                "M8": 1.05, "A1": 1.05, "A82": 0.80, "M77": 0.75}

LANE_CAPACITY = {  # passenger car units per lane per hour
    "Motorway": 2050,
    "Trunk Dual Carriageway": 1750,
    "Trunk Single Carriageway": 1150,
}


def weighted_choice(pairs):
    r = random.random() * sum(w for _, w in pairs)
    acc = 0.0
    for item, w in pairs:
        acc += w
        if r <= acc:
            return item
    return pairs[-1][0]


# ---------------------------------------------------------------------------
# 2. Build the sensor-site network
# ---------------------------------------------------------------------------

def build_sites():
    sites = []
    sid = 0
    for city, roads in CITY_ROADS.items():
        clat, clon = CITY_CENTRE[city]
        for road, road_w in roads:
            rtype = ROAD_TYPE[road]
            n_sites = 4 if city in ("Glasgow", "Edinburgh") else 3
            for k in range(n_sites):
                sid += 1
                limit = weighted_choice(LIMIT_BY_TYPE[rtype])
                if rtype == "Motorway":
                    lanes = random.choice([2, 3, 3, 4]) if limit >= 96 else random.choice([3, 4])
                elif rtype == "Trunk Dual Carriageway":
                    lanes = random.choice([2, 2, 3])
                else:
                    lanes = 1
                capacity = LANE_CAPACITY[rtype] * lanes
                # sensor sites sit along a corridor radiating from the city
                bearing = random.uniform(0, 2 * math.pi)
                dist_km = random.uniform(1.5, 22.0)
                dlat = (dist_km / 111.0) * math.cos(bearing)
                dlon = (dist_km / (111.0 * math.cos(math.radians(clat)))) * math.sin(bearing)
                urban = 1.0 if dist_km < 6 else (0.6 if dist_km < 13 else 0.3)
                peak_vc = (1.15 * CITY_INTENSITY[city]
                           * {"Motorway": 1.00,
                              "Trunk Dual Carriageway": 0.90,
                              "Trunk Single Carriageway": 0.86}[rtype]
                           * random.uniform(0.82, 1.16))
                sites.append({
                    "site_id": sid,
                    "city": city,
                    "road": road,
                    "road_type": rtype,
                    "lat": round(clat + dlat, 6),
                    "lon": round(clon + dlon, 6),
                    "speed_limit": limit,
                    "lanes": lanes,
                    "capacity": capacity,
                    "seg_km": round(random.uniform(3.5, 12.0), 2),
                    "urban": urban,
                    "peak_vc": peak_vc,
                    "hgv_bias": ROAD_FREIGHT.get(road, 1.0) * random.uniform(0.88, 1.18),
                    "weight": CITY_SHARE[city] * road_w / n_sites,
                    "roadworks_base": random.uniform(0.02, 0.10),
                })
    return sites


SITES = build_sites()
SITE_PICK = [(s, s["weight"]) for s in SITES]
_SITE_TOTAL = sum(w for _, w in SITE_PICK)
_SITE_CUM = []
_acc = 0.0
for s, w in SITE_PICK:
    _acc += w / _SITE_TOTAL
    _SITE_CUM.append((_acc, s))


def pick_site():
    r = random.random()
    lo, hi = 0, len(_SITE_CUM) - 1
    while lo < hi:
        mid = (lo + hi) // 2
        if _SITE_CUM[mid][0] < r:
            lo = mid + 1
        else:
            hi = mid
    return _SITE_CUM[lo][1]


# ---------------------------------------------------------------------------
# 3. Temporal profiles
# ---------------------------------------------------------------------------

WEEKDAY_HOUR = [0.10, 0.06, 0.05, 0.05, 0.08, 0.20, 0.50, 0.92, 1.00, 0.72,
                0.60, 0.62, 0.66, 0.66, 0.68, 0.78, 0.95, 1.00, 0.82, 0.55,
                0.42, 0.34, 0.26, 0.17]
WEEKEND_HOUR = [0.19, 0.15, 0.11, 0.07, 0.06, 0.08, 0.12, 0.20, 0.32, 0.46,
                0.60, 0.70, 0.76, 0.78, 0.78, 0.75, 0.72, 0.66, 0.58, 0.50,
                0.43, 0.37, 0.31, 0.25]

DOW_FACTOR = [0.98, 1.00, 1.01, 1.03, 1.09, 0.84, 0.72]      # Mon..Sun
MONTH_FACTOR = [0.88, 0.92, 0.97, 0.99, 1.02, 1.04, 1.03, 1.02,
                1.05, 1.00, 0.96, 0.90]                       # Jan..Dec
YEAR_FACTOR = {2023: 1.000, 2024: 1.028, 2025: 1.049}

DAY_NAME = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
            "Saturday", "Sunday"]

MONTH_TEMP = [4.0, 4.2, 5.8, 8.0, 11.0, 13.6, 15.3, 15.0, 12.7, 9.4, 6.3, 4.2]
MONTH_WET_P = [0.50, 0.44, 0.44, 0.38, 0.36, 0.36, 0.40, 0.42, 0.44, 0.50, 0.52, 0.52]
MONTH_WIND = [22.0, 21.0, 20.0, 17.5, 15.5, 14.5, 14.0, 14.5, 16.5, 19.0, 21.0, 22.5]


def scottish_school_holiday(d: date) -> int:
    m, day = d.month, d.day
    if m == 1 and day <= 5:
        return 1
    if m == 12 and day >= 21:
        return 1
    if m == 2 and 9 <= day <= 14:
        return 1
    if m == 4 and 1 <= day <= 14:
        return 1
    if m == 7:
        return 1
    if m == 8 and day <= 14:
        return 1
    if m == 10 and 12 <= day <= 20:
        return 1
    return 0


def iso_week(d: date) -> int:
    return d.isocalendar()[1]


# ---------------------------------------------------------------------------
# 4. Weather model
# ---------------------------------------------------------------------------

def weather_for(city, dt):
    m = dt.month - 1
    p_wet_mult, rain_mult, t_off, wind_mult = CITY_CLIMATE[city]

    # daily synoptic anomaly, persistent within a day via day-seeded RNG
    day_rng = random.Random(hash((city, dt.year, dt.month, dt.day, SEED)) & 0xFFFFFFFF)
    anomaly = day_rng.gauss(0, 2.6)
    diurnal = -3.2 * math.cos((dt.hour - 14) / 24 * 2 * math.pi)
    temp = MONTH_TEMP[m] + t_off + anomaly + diurnal + random.gauss(0, 0.7)

    wet_day = day_rng.random() < min(0.95, MONTH_WET_P[m] * p_wet_mult * 1.35)
    if wet_day and random.random() < 0.30:
        # gamma-distributed hourly rainfall intensity (mm/h)
        rain = random.gammavariate(1.3, 0.52) * rain_mult
        rain = round(min(rain, 22.0), 2)
    else:
        rain = 0.0

    base_wind = MONTH_WIND[m] * wind_mult
    wind = max(0.5, random.gammavariate(4.0, base_wind / 4.0) * (1.15 if rain > 2 else 1.0))
    wind = round(min(wind, 105.0), 1)

    # visibility: smooth seasonal cycle + fog + rain attenuation
    vis = 30.5 + 5.0 * math.cos((dt.month - 7.0) / 12 * 2 * math.pi)
    vis -= 9.0 * min(rain / 3.0, 1.2)
    if 0 <= dt.hour <= 8:
        vis -= 2.0                                # overnight haze / mist
    if dt.month in (10, 11, 12, 1, 2, 3):
        if temp < 4 and 0 <= dt.hour <= 9 and random.random() < 0.09:
            vis -= random.uniform(8, 24)          # radiation fog / freezing fog
    vis += random.gauss(0, 4.0)
    vis = round(max(0.15, min(vis, 45.0)), 2)
    return round(temp, 1), rain, wind, vis


# ---------------------------------------------------------------------------
# 5. Events
# ---------------------------------------------------------------------------

EVENT_TYPES = ["Football Match", "Concert", "Festival", "Marathon", "Public Gathering"]


def event_for(city, dt):
    dow, hour, month = dt.weekday(), dt.hour, dt.month
    p, kinds = 0.0, []
    if city in ("Glasgow", "Edinburgh", "Aberdeen", "Dundee"):
        if dow == 5 and 12 <= hour <= 19 and month not in (6, 7):
            p += 0.16 if city in ("Glasgow", "Edinburgh") else 0.09
            kinds.append(("Football Match", 3.0))
        if dow in (2, 3) and 18 <= hour <= 22 and month not in (6, 7):
            p += 0.05
            kinds.append(("Football Match", 1.2))
    if city == "Edinburgh" and month == 8:
        p += 0.30 if 10 <= hour <= 23 else 0.05
        kinds.append(("Festival", 4.0))
    if city == "Inverness" and month in (6, 7) and dow >= 4:
        p += 0.08
        kinds.append(("Festival", 1.0))
    if 18 <= hour <= 23 and city in ("Glasgow", "Edinburgh", "Aberdeen"):
        p += 0.05
        kinds.append(("Concert", 1.4))
    if dow == 6 and 8 <= hour <= 13 and month in (4, 5, 9, 10):
        p += 0.03
        kinds.append(("Marathon", 0.8))
    p += 0.012
    kinds.append(("Public Gathering", 0.6))

    if random.random() < min(p, 0.55):
        return 1, weighted_choice(kinds)
    return 0, "None"


# ---------------------------------------------------------------------------
# 6. Vehicle mix
# ---------------------------------------------------------------------------

def vehicle_mix(total, site, dt, is_weekend):
    hour, month = dt.hour, dt.month
    rtype = site["road_type"]

    hgv = 0.088 if rtype == "Motorway" else (0.070 if "Dual" in rtype else 0.050)
    hgv *= site["hgv_bias"]
    if is_weekend:
        hgv *= 0.45
    if 22 <= hour or hour <= 5:
        hgv *= 1.75
    if 7 <= hour <= 9 or 16 <= hour <= 18:
        hgv *= 0.72

    van = 0.115
    if is_weekend:
        van *= 0.62
    if 6 <= hour <= 16:
        van *= 1.20

    bus = 0.022 * (0.5 + site["urban"])
    if 6 <= hour <= 9 or 15 <= hour <= 18:
        bus *= 1.45
    if is_weekend:
        bus *= 0.68
    if 23 <= hour or hour <= 4:
        bus *= 0.30

    moto = 0.010
    if month in (5, 6, 7, 8, 9):
        moto *= 1.9
    if month in (12, 1, 2):
        moto *= 0.45
    if is_weekend:
        moto *= 1.25

    hgv = min(hgv, 0.22)
    shares = {"bus": bus, "hgv": hgv, "moto": moto, "van": van}
    non_car = sum(shares.values())
    shares["car"] = max(0.45, 1.0 - non_car)
    s = sum(shares.values())
    for k in shares:
        shares[k] /= s

    # largest-remainder allocation guarantees exact sum
    raw = {k: shares[k] * total for k in shares}
    alloc = {k: int(math.floor(v)) for k, v in raw.items()}
    rem = total - sum(alloc.values())
    order = sorted(raw, key=lambda k: raw[k] - alloc[k], reverse=True)
    for i in range(rem):
        alloc[order[i % len(order)]] += 1
    return alloc["car"], alloc["bus"], alloc["hgv"], alloc["moto"], alloc["van"]


# ---------------------------------------------------------------------------
# 7. Emissions
# ---------------------------------------------------------------------------

CO2_KG_PER_KM = {"car": 0.168, "van": 0.232, "bus": 0.822, "hgv": 0.905, "moto": 0.095}


def co2_kg(car, bus, hgv, moto, van, seg_km, speed, limit):
    base = (car * CO2_KG_PER_KM["car"] + van * CO2_KG_PER_KM["van"]
            + bus * CO2_KG_PER_KM["bus"] + hgv * CO2_KG_PER_KM["hgv"]
            + moto * CO2_KG_PER_KM["moto"]) * seg_km
    # congestion / stop-start penalty: worst at very low average speeds
    ratio = max(0.12, min(speed / max(limit, 1), 1.0))
    penalty = 1.0 + 0.62 * (1.0 - ratio) ** 1.7
    return round(base * penalty, 2)


# ---------------------------------------------------------------------------
# 8. Record generation
# ---------------------------------------------------------------------------

HEADER = ["Record_ID", "Date", "Time", "Year", "Month", "Quarter", "Week",
          "Day_of_Week", "Hour", "City", "Council_Area", "Road_ID", "Road_Type",
          "Latitude", "Longitude", "Vehicle_Count", "Car_Count", "Bus_Count",
          "HGV_Count", "Motorcycle_Count", "Van_Count", "Average_Speed_kmh",
          "Speed_Limit_kmh", "Congestion_Level", "Journey_Time_Minutes",
          "Journey_Time_Index", "Temperature_C", "Rainfall_mm", "Wind_Speed_kmh",
          "Visibility_km", "Accident_Flag", "Incident_Type", "Roadworks_Flag",
          "Lane_Closure_Flag", "Public_Event_Flag", "Event_Type",
          "School_Holiday_Flag", "Air_Quality_Index", "CO2_Emission_kg",
          "Traffic_Sensor_Status"]

MINUTES = [0, 15, 30, 45]


def make_record(dt, site):
    city = site["city"]
    dow = dt.weekday()
    is_weekend = dow >= 5
    hour = dt.hour
    d = dt.date()

    temp, rain, wind, vis = weather_for(city, dt)
    school_hol = scottish_school_holiday(d)
    event_flag, event_type = event_for(city, dt)

    # ---- roadworks -------------------------------------------------------
    rw_p = site["roadworks_base"]
    rw_p *= 1.6 if dt.month in (4, 5, 6, 7, 8, 9) else 0.7
    rw_p *= 2.3 if (hour >= 21 or hour <= 5) else 0.8      # night-time works
    roadworks = 1 if random.random() < min(rw_p, 0.35) else 0

    # ---- demand ----------------------------------------------------------
    hprof = WEEKEND_HOUR[hour] if is_weekend else WEEKDAY_HOUR[hour]
    if is_weekend:
        hprof *= 1.06 if 10 <= hour <= 17 else 1.0        # leisure travel
    demand = (site["capacity"] * site["peak_vc"] * hprof
              * DOW_FACTOR[dow] * MONTH_FACTOR[dt.month - 1]
              * YEAR_FACTOR[dt.year])

    if school_hol and not is_weekend and hour in (7, 8, 9, 15, 16, 17):
        demand *= 0.86
    if school_hol and 10 <= hour <= 14:
        demand *= 1.04
    if event_flag:
        demand *= random.uniform(1.10, 1.55)
    if rain > 0.5:
        demand *= random.uniform(0.96, 1.00)              # slight suppression
    demand *= math.exp(random.gauss(0, 0.115))            # lognormal noise

    # ---- incidents -------------------------------------------------------
    vc_demand = demand / site["capacity"]
    acc_p = 0.0018
    acc_p *= 1.0 + 1.15 * min(vc_demand, 1.4)
    if rain > 0.2:
        acc_p *= 1.45 + min(rain / 8.0, 0.9)
    if vis < 5:
        acc_p *= 1.9
    if dt.month in (11, 12, 1, 2):
        acc_p *= 1.35
        if temp <= 1.0:
            acc_p *= 1.5                                   # ice risk
    if hour in (7, 8, 16, 17):
        acc_p *= 1.30
    if roadworks:
        acc_p *= 1.20
    if wind > 60:
        acc_p *= 1.25
    accident = 1 if random.random() < min(acc_p, 0.16) else 0

    if accident:
        incident = weighted_choice([("Collision", 0.82), ("Vehicle Fire", 0.06),
                                    ("Debris", 0.07), ("Severe Weather", 0.05)])
    else:
        p_other = 0.020 + 0.010 * min(vc_demand, 1.2)
        if rain > 4 or wind > 65 or vis < 2:
            p_other += 0.05
        if random.random() < p_other:
            incident = weighted_choice([
                ("Breakdown", 0.58),
                ("Debris", 0.18),
                ("Severe Weather", 0.20 if (rain > 4 or wind > 65 or vis < 2) else 0.04),
                ("Vehicle Fire", 0.03)])
        else:
            incident = "None"

    lane_closure = 0
    if accident and random.random() < 0.62:
        lane_closure = 1
    elif roadworks and random.random() < 0.55:
        lane_closure = 1
    elif incident in ("Breakdown", "Debris") and random.random() < 0.22:
        lane_closure = 1

    # ---- capacity reduction ---------------------------------------------
    cap = site["capacity"]
    if lane_closure:
        cap *= (1 - 1.0 / max(site["lanes"], 1)) if site["lanes"] > 1 else 0.45
    elif roadworks:
        cap *= random.uniform(0.80, 0.93)
    if accident and not lane_closure:
        cap *= random.uniform(0.72, 0.90)
    if rain > 0.2:
        cap *= 1 - min(0.10, 0.02 + rain * 0.012)
    if vis < 3:
        cap *= 0.88
    if temp <= 0:
        cap *= 0.92
    cap = max(cap, 150)

    vc = demand / cap

    # observed throughput saturates when demand exceeds capacity (queuing)
    if vc <= 1.0:
        observed = demand
    else:
        observed = cap * (1.0 + 0.06 * (vc - 1.0))
    vehicle_count = max(0, int(round(observed)))

    # ---- speed / journey time (BPR) --------------------------------------
    limit = site["speed_limit"]
    free_flow = limit * random.uniform(0.96, 1.06)
    if hour >= 22 or hour <= 5:
        free_flow *= 1.02
    jti = 1.0 + 0.52 * (vc ** 2.9)
    if rain > 0.2:
        jti *= 1.0 + min(0.12, 0.02 + rain * 0.010)
    if vis < 4:
        jti *= 1.08
    if temp <= 0:
        jti *= 1.05
    if roadworks:
        jti *= random.uniform(1.05, 1.22)
    if accident:
        jti *= random.uniform(1.20, 2.10)
    # multiplicative noise on the *delay* component only, plus a small strictly
    # positive residual: keeps JTI continuous and strictly above 1.0 (no point
    # mass at the free-flow floor)
    jti = 1.0 + (jti - 1.0) * math.exp(random.gauss(0, 0.30)) \
              + abs(random.gauss(0, 0.022))
    jti = min(jti, 9.0)

    speed = free_flow / jti
    speed = max(3.0, min(speed, limit * 1.12))

    if jti < 1.15:
        congestion = "Low"
    elif jti < 1.45:
        congestion = "Medium"
    elif jti < 2.00:
        congestion = "High"
    else:
        congestion = "Severe"

    journey_time = site["seg_km"] / speed * 60.0

    car, bus, hgv, moto, van = vehicle_mix(vehicle_count, site, dt, is_weekend)
    co2 = co2_kg(car, bus, hgv, moto, van, site["seg_km"], speed, limit)

    # ---- air quality -----------------------------------------------------
    aqi = 16.0
    aqi += 34.0 * min(vc, 1.5)
    aqi += 14.0 * site["urban"]
    aqi += (hgv + bus) / max(vehicle_count, 1) * 45.0
    aqi *= 14.0 / (wind + 9.0) + 0.42
    if rain > 1.0:
        aqi *= 0.80                                        # wet deposition
    if dt.month in (12, 1, 2) and wind < 10:
        aqi *= 1.22                                        # winter inversion
    if dt.month in (6, 7, 8) and temp > 20:
        aqi *= 1.10                                        # photochemical ozone
    aqi *= math.exp(random.gauss(0, 0.16))
    aqi = int(round(max(5, min(aqi, 195))))

    # ---- sensor status ---------------------------------------------------
    r = random.random()
    if r < 0.9375:
        status = "Active"
    elif r < 0.9775:
        status = "Maintenance"
    else:
        status = "Faulty"

    return {
        "Record_ID": None,
        "Date": d.isoformat(),
        "Time": f"{hour:02d}:{random.choice(MINUTES):02d}:00",
        "Year": dt.year,
        "Month": dt.month,
        "Quarter": f"Q{(dt.month - 1)//3 + 1}",
        "Week": iso_week(d),
        "Day_of_Week": DAY_NAME[dow],
        "Hour": hour,
        "City": city,
        "Council_Area": COUNCIL[city],
        "Road_ID": site["road"],
        "Road_Type": site["road_type"],
        "Latitude": site["lat"],
        "Longitude": site["lon"],
        "Vehicle_Count": vehicle_count,
        "Car_Count": car,
        "Bus_Count": bus,
        "HGV_Count": hgv,
        "Motorcycle_Count": moto,
        "Van_Count": van,
        "Average_Speed_kmh": round(speed, 1),
        "Speed_Limit_kmh": limit,
        "Congestion_Level": congestion,
        "Journey_Time_Minutes": round(journey_time, 2),
        "Journey_Time_Index": round(jti, 3),
        "Temperature_C": temp,
        "Rainfall_mm": rain,
        "Wind_Speed_kmh": wind,
        "Visibility_km": vis,
        "Accident_Flag": accident,
        "Incident_Type": incident,
        "Roadworks_Flag": roadworks,
        "Lane_Closure_Flag": lane_closure,
        "Public_Event_Flag": event_flag,
        "Event_Type": event_type,
        "School_Holiday_Flag": school_hol,
        "Air_Quality_Index": aqi,
        "CO2_Emission_kg": co2,
        "Traffic_Sensor_Status": status,
    }


# ---------------------------------------------------------------------------
# 9. Anomaly injection (~3.5% of records)
# ---------------------------------------------------------------------------

ANOMALY_LOG = {"sensor_failure_zero": 0, "impossible_speed": 0,
               "missing_traffic": 0, "missing_weather": 0,
               "traffic_spike": 0, "negative_value": 0,
               "duplicate_timestamp": 0}


def inject_anomaly(rec):
    kind = weighted_choice([
        ("sensor_failure_zero", 0.20),
        ("impossible_speed", 0.18),
        ("missing_traffic", 0.20),
        ("missing_weather", 0.22),
        ("traffic_spike", 0.15),
        ("negative_value", 0.05),
    ])
    if kind == "sensor_failure_zero":
        rec["Vehicle_Count"] = 0
        for c in ("Car_Count", "Bus_Count", "HGV_Count",
                  "Motorcycle_Count", "Van_Count"):
            rec[c] = 0
        rec["CO2_Emission_kg"] = 0.0
        rec["Traffic_Sensor_Status"] = "Faulty"
    elif kind == "impossible_speed":
        rec["Average_Speed_kmh"] = round(random.choice([
            random.uniform(190, 320),      # physically implausible
            0.0,                            # zero speed with flowing traffic
            random.uniform(-15, -1),        # negative reading
        ]), 1)
        rec["Traffic_Sensor_Status"] = random.choice(["Faulty", "Maintenance"])
    elif kind == "missing_traffic":
        for c in random.sample(["Vehicle_Count", "Car_Count", "Bus_Count",
                                "HGV_Count", "Motorcycle_Count", "Van_Count",
                                "Average_Speed_kmh", "Journey_Time_Minutes"],
                               k=random.randint(1, 3)):
            rec[c] = ""
        rec["Traffic_Sensor_Status"] = random.choice(["Faulty", "Maintenance", "Active"])
    elif kind == "missing_weather":
        for c in random.sample(["Temperature_C", "Rainfall_mm",
                                "Wind_Speed_kmh", "Visibility_km",
                                "Air_Quality_Index"],
                               k=random.randint(1, 2)):
            rec[c] = ""
    elif kind == "traffic_spike":
        mult = random.uniform(3.0, 6.5)
        rec["Vehicle_Count"] = int(rec["Vehicle_Count"] * mult)
        for c in ("Car_Count", "Bus_Count", "HGV_Count",
                  "Motorcycle_Count", "Van_Count"):
            rec[c] = int(rec[c] * mult)
        rec["Vehicle_Count"] = (rec["Car_Count"] + rec["Bus_Count"] +
                                rec["HGV_Count"] + rec["Motorcycle_Count"] +
                                rec["Van_Count"])
    elif kind == "negative_value":
        rec[random.choice(["Vehicle_Count", "Car_Count", "Van_Count"])] = \
            -random.randint(1, 40)
    ANOMALY_LOG[kind] += 1
    return rec


# ---------------------------------------------------------------------------
# 10. Main
# ---------------------------------------------------------------------------

def main():
    n_dupes = 900                     # duplicated (site, timestamp) pairs
    n_base = N_RECORDS - n_dupes

    records = []
    for _ in range(n_base):
        dt = START + timedelta(hours=random.randrange(TOTAL_HOURS))
        site = pick_site()
        records.append((make_record(dt, site), site, dt))

    # duplicate timestamps: same road + date + time appearing more than once
    for _ in range(n_dupes):
        rec, site, dt = random.choice(records)
        clone = dict(rec)
        if random.random() < 0.55:
            # near-identical replica (classic double-reporting)
            pass
        else:
            # same timestamp/road, slightly different sensor readings
            if isinstance(clone["Vehicle_Count"], int) and clone["Vehicle_Count"] > 0:
                delta = random.randint(-25, 25)
                clone["Car_Count"] = max(0, clone["Car_Count"] + delta)
                clone["Vehicle_Count"] = (clone["Car_Count"] + clone["Bus_Count"]
                                          + clone["HGV_Count"]
                                          + clone["Motorcycle_Count"]
                                          + clone["Van_Count"])
            if isinstance(clone["Average_Speed_kmh"], float):
                clone["Average_Speed_kmh"] = round(
                    max(3.0, clone["Average_Speed_kmh"] + random.gauss(0, 2.5)), 1)
        records.append((clone, site, dt))
        ANOMALY_LOG["duplicate_timestamp"] += 1

    random.shuffle(records)

    # anomaly injection on ~3.2% of non-duplicate records
    target = int(0.032 * N_RECORDS)
    idxs = random.sample(range(len(records)), target)
    for i in idxs:
        rec, site, dt = records[i]
        records[i] = (inject_anomaly(rec), site, dt)

    # chronological ordering, then assign sequential Record_IDs
    records.sort(key=lambda t: (t[2], t[0]["Road_ID"], t[0]["City"]))

    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=HEADER)
        w.writeheader()
        for i, (rec, _, _) in enumerate(records, start=1):
            rec["Record_ID"] = f"ITS-{i:06d}"
            w.writerow(rec)

    print(f"Wrote {len(records):,} records to {OUT_CSV}")
    print("Anomaly log:", ANOMALY_LOG)
    print("Sensor sites:", len(SITES))


if __name__ == "__main__":
    main()
