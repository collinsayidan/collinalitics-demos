import pandas as pd, numpy as np, sys
df = pd.read_csv("scotland_its_dataset.csv", keep_default_na=False, na_values=[""], parse_dates=["Date"])
C=["Car_Count","Bus_Count","HGV_Count","Motorcycle_Count","Van_Count"]
ok=True
def check(name, cond, detail=""):
    global ok
    print(("PASS  " if cond else "FAIL  ")+name+("  "+str(detail) if detail else ""))
    ok = ok and cond

check("exactly 100,000 records", len(df)==100000, len(df))
check("40 columns", df.shape[1]==40)
check("Record_ID unique", df.Record_ID.nunique()==100000)
check("Record_ID no nulls", df.Record_ID.notna().all())
check("period 2023-01-01..2025-12-31", str(df.Date.min().date())=="2023-01-01" and str(df.Date.max().date())=="2025-12-31")
check("all 36 months present", df.groupby([df.Date.dt.year,df.Date.dt.month]).ngroups==36)
check("7 cities", set(df.City)=={"Glasgow","Edinburgh","Aberdeen","Dundee","Inverness","Stirling","Perth"})
check("9 roads", set(df.Road_ID)=={"M8","M74","M77","M90","A9","A90","A82","A1","A96"})
check("congestion 4 levels", set(df.Congestion_Level)=={"Low","Medium","High","Severe"})
check("sensor 3 states", set(df.Traffic_Sensor_Status)=={"Active","Maintenance","Faulty"})
check("incident 6 types", set(df.Incident_Type)=={"None","Collision","Breakdown","Debris","Severe Weather","Vehicle Fire"})
check("event 6 types", set(df.Event_Type)=={"None","Football Match","Concert","Festival","Marathon","Public Gathering"})

m = df[["Vehicle_Count"]+C].notna().all(axis=1)
r1 = (df.loc[m,C].sum(axis=1)==df.loc[m,"Vehicle_Count"])
check("Rule 1 sum identity >=99.8% of complete rows", r1.mean()>=0.998, f"{r1.mean()*100:.2f}% ({(~r1).sum()} fails)")
check("Rule 1 fails are all negative-value defects", ((df.loc[m][~r1][["Vehicle_Count"]+C]<0).any(axis=1)).all())

cl = df[(df.Traffic_Sensor_Status=="Active")&df.Vehicle_Count.notna()&(df.Vehicle_Count>0)&df.Average_Speed_kmh.between(3,160)]
sp = cl.groupby("Congestion_Level").Average_Speed_kmh.mean()
check("Rule 6 speed strictly decreasing Low>Med>High>Severe",
      sp["Low"]>sp["Medium"]>sp["High"]>sp["Severe"], sp.round(1).to_dict())
jt = cl.groupby("Congestion_Level").Journey_Time_Minutes.mean()
check("journey time strictly increasing", jt["Low"]<jt["Medium"]<jt["High"]<jt["Severe"], jt.round(2).to_dict())

h = cl.groupby("Hour").Vehicle_Count.mean()
check("Rule 2 AM peak 07-09 above 06 and 10", h[7]>h[6] and h[8]>h[10])
check("Rule 2 PM peak 16-18 is daily max", h.idxmax() in (16,17))
check("peak/offpeak ratio > 4x", h[[7,8,17]].mean()/h[[1,2,3,22,23]].mean()>4, round(h[[7,8,17]].mean()/h[[1,2,3,22,23]].mean(),2))

we = cl.Day_of_Week.isin(["Saturday","Sunday"])
pk_wd, pk_we = cl[~we&cl.Hour.isin([7,8,17])].Vehicle_Count.mean(), cl[we&cl.Hour.isin([7,8,17])].Vehicle_Count.mean()
md_wd, md_we = cl[~we&cl.Hour.isin([11,12,13,14])].Vehicle_Count.mean(), cl[we&cl.Hour.isin([11,12,13,14])].Vehicle_Count.mean()
check("Rule 3 weekend commuter traffic much lower", pk_we < 0.5*pk_wd, f"{pk_we:.0f} vs {pk_wd:.0f}")
check("Rule 3 weekend leisure retained midday", md_we > 0.85*md_wd, f"{md_we:.0f} vs {md_wd:.0f}")
check("Rule 3 weekend peak/midday shape flips", (md_we/pk_we) > (md_wd/pk_wd))

fl = cl.groupby("City").Vehicle_Count.mean().sort_values(ascending=False)
check("Rule 4 Glasgow & Edinburgh top 2 by volume", set(fl.index[:2])=={"Glasgow","Edinburgh"}, fl.round(0).to_dict())

wet, dry = cl[cl.Rainfall_mm>0], cl[cl.Rainfall_mm==0]
check("Rule 7 rain raises congestion", wet.Congestion_Level.isin(["High","Severe"]).mean() > dry.Congestion_Level.isin(["High","Severe"]).mean())
check("Rule 7 rain raises accident rate", df[df.Rainfall_mm>0].Accident_Flag.mean() > df[df.Rainfall_mm==0].Accident_Flag.mean())

w,s = df[df.Month.isin([12,1,2])], df[df.Month.isin([6,7,8])]
check("Rule 8 winter visibility lower", w.Visibility_km.mean() < s.Visibility_km.mean(), f"{w.Visibility_km.mean():.1f} vs {s.Visibility_km.mean():.1f}")
check("Rule 8 winter accidents higher", w.Accident_Flag.mean() > s.Accident_Flag.mean(), f"{w.Accident_Flag.mean()*100:.3f}% vs {s.Accident_Flag.mean()*100:.3f}%")

check("Rule 9 roadworks raise JTI", cl[cl.Roadworks_Flag==1].Journey_Time_Index.mean() > cl[cl.Roadworks_Flag==0].Journey_Time_Index.mean()*1.15)
check("Rule 9 roadworks raise congestion", cl[cl.Roadworks_Flag==1].Congestion_Level.isin(["High","Severe"]).mean() > 2*cl[cl.Roadworks_Flag==0].Congestion_Level.isin(["High","Severe"]).mean())
check("Rule 10 accidents raise JTI", cl[cl.Accident_Flag==1].Journey_Time_Index.mean() > 2*cl[cl.Accident_Flag==0].Journey_Time_Index.mean())
check("Rule 10 accidents raise travel time", cl[cl.Accident_Flag==1].Journey_Time_Minutes.mean() > 2*cl[cl.Accident_Flag==0].Journey_Time_Minutes.mean())

sp_all=df.Average_Speed_kmh; vc=df.Vehicle_Count
site_hour = df.groupby(["Road_ID","Latitude","Hour"]).Vehicle_Count.transform("median")
dup = df.duplicated(subset=["Date","Time","Road_ID","Latitude","Longitude"])
anom = (df[["Vehicle_Count","Average_Speed_kmh"]+C+["Temperature_C","Rainfall_mm","Wind_Speed_kmh","Visibility_km","Air_Quality_Index"]].isna().any(axis=1)
        | (sp_all>150) | (sp_all<=0) | (vc<0) | (vc==0) | (vc>4*site_hour) | dup)
check("Rule 12 anomaly rate within 2-5%", 0.02 <= anom.mean() <= 0.05, f"{anom.mean()*100:.2f}%")
check("Rule 12 all five anomaly classes present",
      all([(sp_all>150).any(), df.Vehicle_Count.isna().any(), dup.any(), (vc==0).any(), (vc>4*site_hour).any()]))

check("no null in key dims", df[["Date","Time","City","Council_Area","Road_ID","Road_Type","Latitude","Longitude","Congestion_Level"]].notna().all().all())
check("City->Council 1:1", (df.groupby("City").Council_Area.nunique()==1).all())
check("Road->Road_Type 1:1", (df.groupby("Road_ID").Road_Type.nunique()==1).all())
check("Collision implies Accident_Flag", ((df.Incident_Type=="Collision")&(df.Accident_Flag==0)).sum()==0)
check("Event flag <-> Event type", (((df.Public_Event_Flag==1)!=(df.Event_Type!="None")).sum())==0)
check("coords inside Scotland bbox", df.Latitude.between(54.6,58.7).all() and df.Longitude.between(-7.7,-0.7).all())
check("JTI >= 1 always", (df.Journey_Time_Index>=1.0).all())
check("no JTI point mass at 1.000", (df.Journey_Time_Index==1.0).mean()<0.01, f"{(df.Journey_Time_Index==1.0).sum()} rows")
check("temperature plausible", df.Temperature_C.min()>-25 and df.Temperature_C.max()<35)
check("flags binary", all(set(df[c].unique())<= {0,1} for c in ["Accident_Flag","Roadworks_Flag","Lane_Closure_Flag","Public_Event_Flag","School_Holiday_Flag"]))
check("year growth present 2023<2025 flow", cl[cl.Year==2025].Vehicle_Count.mean() > cl[cl.Year==2023].Vehicle_Count.mean())
print()
print("OVERALL:", "ALL CHECKS PASSED" if ok else "FAILURES PRESENT")
sys.exit(0 if ok else 1)
