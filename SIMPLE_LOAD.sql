-- =============================================================================
--  SIMPLE_LOAD.sql   -   Scotland ITS analytics platform
--  Rebuilds and reloads all 27 tables from C:/its_data/exports
--
--  SELF-HEALING: every table is DROPped and CREATEd from the CSV's own shape
--  before loading, so a changed export can never cause a column mismatch.
--
--  HOW TO RUN
--    1. Confirm the CSVs are current:
--         fct_traffic_observation.csv should be 43,681,265 bytes (96,652 rows)
--    2. Open this file in pgAdmin's Query Tool
--    3. Select ALL (Ctrl+A) and Execute (F5)
--    4. Run the verification query at the bottom
--
--  DIFFERENT FOLDER? Ctrl+H and replace  C:/its_data/exports  with yours.
--  Forward slashes only.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS marts;
CREATE SCHEMA IF NOT EXISTS report;


-- ---------- dim_congestion  (4 rows, 7 columns) ----------
DROP TABLE IF EXISTS marts.dim_congestion CASCADE;
CREATE TABLE marts.dim_congestion (
    congestion_key                     bigint,
    congestion_level                   text,
    jti_lower_bound                    double precision,
    jti_upper_bound                    double precision,
    display_colour_hex                 text,
    operational_response               text,
    is_target_breach                   bigint
);
COPY marts.dim_congestion FROM 'C:/its_data/exports/dim_congestion.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_date  (1,096 rows, 26 columns) ----------
DROP TABLE IF EXISTS marts.dim_date CASCADE;
CREATE TABLE marts.dim_date (
    date_key                           bigint,
    full_date                          date,
    calendar_year                      bigint,
    month_number                       bigint,
    month_name                         text,
    month_short_name                   text,
    year_month                         text,
    month_year_label                   text,
    calendar_quarter                   text,
    quarter_number                     bigint,
    iso_week_number                    bigint,
    week_start_date                    timestamp,
    month_start_date                   timestamp,
    day_of_month                       bigint,
    day_of_week_number                 bigint,
    day_name                           text,
    day_short_name                     text,
    is_weekend                         bigint,
    day_type                           text,
    fiscal_year                        text,
    fiscal_quarter                     text,
    meteorological_season              text,
    is_school_holiday                  bigint,
    school_period                      text,
    days_from_period_start             bigint,
    is_month_end                       bigint
);
COPY marts.dim_date FROM 'C:/its_data/exports/dim_date.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_event  (6 rows, 6 columns) ----------
DROP TABLE IF EXISTS marts.dim_event CASCADE;
CREATE TABLE marts.dim_event (
    event_key                          bigint,
    event_type                         text,
    event_category                     text,
    is_planned_event                   bigint,
    traffic_management_response        text,
    typical_demand_uplift              double precision
);
COPY marts.dim_event FROM 'C:/its_data/exports/dim_event.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_incident  (6 rows, 7 columns) ----------
DROP TABLE IF EXISTS marts.dim_incident CASCADE;
CREATE TABLE marts.dim_incident (
    incident_key                       bigint,
    incident_type                      text,
    incident_category                  text,
    is_disruptive                      bigint,
    is_reportable_casualty_event       bigint,
    response_owner                     text,
    severity_rank                      bigint
);
COPY marts.dim_incident FROM 'C:/its_data/exports/dim_incident.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_model_metric  (21 rows, 11 columns) ----------
DROP TABLE IF EXISTS marts.dim_model_metric CASCADE;
CREATE TABLE marts.dim_model_metric (
    metric_key                         bigint,
    model_name                         text,
    model_version                      text,
    data_split                         text,
    metric_name                        text,
    metric_value                       double precision,
    note                               text,
    training_rows                      bigint,
    test_rows                          bigint,
    trained_at                         timestamp,
    metric_family                      text
);
COPY marts.dim_model_metric FROM 'C:/its_data/exports/dim_model_metric.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_sensor_status  (3 rows, 6 columns) ----------
DROP TABLE IF EXISTS marts.dim_sensor_status CASCADE;
CREATE TABLE marts.dim_sensor_status (
    sensor_status_key                  bigint,
    sensor_status                      text,
    is_operational                     bigint,
    status_description                 text,
    maintenance_priority               text,
    display_colour_hex                 text
);
COPY marts.dim_sensor_status FROM 'C:/its_data/exports/dim_sensor_status.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_site  (74 rows, 24 columns) ----------
DROP TABLE IF EXISTS marts.dim_site CASCADE;
CREATE TABLE marts.dim_site (
    site_key                           text,
    site_natural_key                   text,
    site_code                          text,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    road_name                          text,
    corridor                           text,
    strategic_function                 text,
    operating_unit                     text,
    is_anglo_scottish                  bigint,
    design_capacity_band               text,
    road_type                          text,
    latitude                           double precision,
    longitude                          double precision,
    speed_limit_kmh                    bigint,
    speed_limit_mph                    double precision,
    segment_length_km                  double precision,
    km_from_city_centroid              double precision,
    urbanisation_band                  text,
    settlement_tier                    text,
    source_observation_count           bigint,
    first_observed_date                date,
    last_observed_date                 date
);
COPY marts.dim_site FROM 'C:/its_data/exports/dim_site.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_time  (24 rows, 11 columns) ----------
DROP TABLE IF EXISTS marts.dim_time CASCADE;
CREATE TABLE marts.dim_time (
    time_key                           bigint,
    hour_of_day                        bigint,
    hour_label                         time,
    hour_range_label                   text,
    time_band                          text,
    time_band_order                    bigint,
    is_peak                            bigint,
    peak_flag_label                    text,
    peak_direction                     text,
    operational_shift                  text,
    is_daytime                         bigint
);
COPY marts.dim_time FROM 'C:/its_data/exports/dim_time.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- dim_weather  (3 rows, 5 columns) ----------
DROP TABLE IF EXISTS marts.dim_weather CASCADE;
CREATE TABLE marts.dim_weather (
    weather_key                        bigint,
    weather_severity_band              text,
    band_description                   text,
    display_colour_hex                 text,
    triggers_winter_service            bigint
);
COPY marts.dim_weather FROM 'C:/its_data/exports/dim_weather.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- fct_data_quality  (100,000 rows, 24 columns) ----------
DROP TABLE IF EXISTS marts.fct_data_quality CASCADE;
CREATE TABLE marts.fct_data_quality (
    observation_id                     text,
    date_key                           bigint,
    time_key                           bigint,
    site_key                           text,
    sensor_status_key                  bigint,
    observation_date                   date,
    city_name                          text,
    road_id                            text,
    sensor_status                      text,
    dq_disposition                     text,
    dq_primary_failure                 text,
    is_quarantined                     bigint,
    has_warning                        bigint,
    is_fully_conformant                bigint,
    fail_dq01_traffic_null             bigint,
    fail_dq02_environment_null         bigint,
    fail_dq03_speed_invalid            bigint,
    fail_dq04_negative_count           bigint,
    fail_dq05_sum_mismatch             bigint,
    fail_dq06_dead_zero                bigint,
    fail_dq07_flow_spike               bigint,
    fail_dq08_duplicate                bigint,
    fail_dq10_out_of_window            bigint,
    record_count                       bigint
);
COPY marts.fct_data_quality FROM 'C:/its_data/exports/fct_data_quality.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- fct_risk_score  (96,652 rows, 22 columns) ----------
DROP TABLE IF EXISTS marts.fct_risk_score CASCADE;
CREATE TABLE marts.fct_risk_score (
    observation_id                     text,
    date_key                           bigint,
    time_key                           bigint,
    site_key                           text,
    actual_congestion_key              bigint,
    model_version                      text,
    data_split                         text,
    predicted_congestion_level         text,
    actual_congestion_level            text,
    prob_low                           double precision,
    prob_medium                        double precision,
    prob_high                          double precision,
    prob_severe                        double precision,
    prob_congested                     double precision,
    collision_risk_score               double precision,
    collision_risk_percentile          double precision,
    collision_risk_decile              bigint,
    collision_risk_band                text,
    is_congestion_prediction_correct   bigint,
    actual_accident_flag               bigint,
    is_priority_risk_hour              bigint,
    scored_at                          timestamp
);
COPY marts.fct_risk_score FROM 'C:/its_data/exports/fct_risk_score.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- fct_traffic_observation  (96,652 rows, 57 columns) ----------
DROP TABLE IF EXISTS marts.fct_traffic_observation CASCADE;
CREATE TABLE marts.fct_traffic_observation (
    observation_id                     text,
    date_key                           bigint,
    time_key                           bigint,
    site_key                           text,
    congestion_key                     bigint,
    incident_key                       bigint,
    event_key                          bigint,
    sensor_status_key                  bigint,
    weather_key                        bigint,
    observation_ts                     timestamp,
    observation_date                   date,
    vehicle_count                      bigint,
    car_count                          bigint,
    van_count                          bigint,
    hgv_count                          bigint,
    bus_count                          bigint,
    motorcycle_count                   bigint,
    freight_vehicle_count              bigint,
    pcu_count                          double precision,
    average_speed_kmh                  double precision,
    speed_limit_kmh                    bigint,
    journey_time_minutes               double precision,
    free_flow_journey_time_minutes     double precision,
    journey_time_index                 double precision,
    delay_minutes_per_vehicle          double precision,
    delay_vehicle_hours                double precision,
    speed_compliance_ratio             double precision,
    temperature_c                      double precision,
    rainfall_mm                        double precision,
    wind_speed_kmh                     double precision,
    visibility_km                      double precision,
    air_quality_index                  double precision,
    co2_emission_kg                    double precision,
    co2_tonnes                         double precision,
    accident_flag                      bigint,
    roadworks_flag                     bigint,
    lane_closure_flag                  bigint,
    public_event_flag                  bigint,
    school_holiday_flag                bigint,
    has_incident                       bigint,
    disruption_cause                   text,
    disruption_cause_order             bigint,
    is_disrupted                       bigint,
    is_weekend                         bigint,
    is_peak_hour                       bigint,
    is_environment_imputed             bigint,
    has_dq_warning                     bigint,
    delay_cost_gbp                     double precision,
    carbon_cost_gbp                    double precision,
    collision_cost_gbp                 double precision,
    breakdown_cost_gbp                 double precision,
    total_economic_cost_gbp            double precision,
    expansion_factor                   double precision,
    annualisation_factor               double precision,
    annualised_cost_gbp                double precision,
    annualised_delay_vehicle_hours     double precision,
    annualised_co2_tonnes              double precision
);
COPY marts.fct_traffic_observation FROM 'C:/its_data/exports/fct_traffic_observation.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- agg_corridor_month  (324 rows, 21 columns) ----------
DROP TABLE IF EXISTS marts.agg_corridor_month CASCADE;
CREATE TABLE marts.agg_corridor_month (
    year_month                         text,
    calendar_year                      bigint,
    month_number                       bigint,
    month_year_label                   text,
    fiscal_year                        text,
    corridor                           text,
    operating_unit                     text,
    road_type                          text,
    observation_count                  bigint,
    site_count                         bigint,
    total_vehicles                     bigint,
    mean_speed_kmh                     double precision,
    mean_journey_time_index            double precision,
    congested_hours                    bigint,
    congested_hours_pct                double precision,
    delay_vehicle_hours                double precision,
    accident_count                     bigint,
    accidents_per_100m_vehicle_km      double precision,
    co2_tonnes                         double precision,
    total_economic_cost_gbp            double precision,
    annualised_cost_gbp                double precision
);
COPY marts.agg_corridor_month FROM 'C:/its_data/exports/agg_corridor_month.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- agg_data_quality_daily  (59,481 rows, 23 columns) ----------
DROP TABLE IF EXISTS marts.agg_data_quality_daily CASCADE;
CREATE TABLE marts.agg_data_quality_daily (
    date_key                           bigint,
    full_date                          date,
    year_month                         text,
    site_key                           text,
    site_code                          text,
    city_name                          text,
    road_id                            text,
    operating_unit                     text,
    sensor_status                      text,
    records_received                   bigint,
    records_conformant                 bigint,
    records_quarantined                bigint,
    records_with_warning               bigint,
    conformance_rate_pct               double precision,
    quarantine_rate_pct                double precision,
    fail_dq01                          bigint,
    fail_dq02                          bigint,
    fail_dq03                          bigint,
    fail_dq04                          bigint,
    fail_dq05                          bigint,
    fail_dq06                          bigint,
    fail_dq07                          bigint,
    fail_dq08                          bigint
);
COPY marts.agg_data_quality_daily FROM 'C:/its_data/exports/agg_data_quality_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- agg_network_daily  (22,833 rows, 37 columns) ----------
DROP TABLE IF EXISTS marts.agg_network_daily CASCADE;
CREATE TABLE marts.agg_network_daily (
    date_key                           bigint,
    full_date                          date,
    calendar_year                      bigint,
    year_month                         text,
    day_type                           text,
    meteorological_season              text,
    is_school_holiday                  bigint,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    corridor                           text,
    road_type                          text,
    operating_unit                     text,
    observation_count                  bigint,
    active_site_count                  bigint,
    total_vehicles                     bigint,
    total_pcu                          double precision,
    total_hgv                          bigint,
    mean_speed_kmh                     double precision,
    harmonic_mean_speed_kmh            double precision,
    mean_journey_time_index            double precision,
    p95_journey_time_index             double precision,
    delay_vehicle_hours                double precision,
    congested_hour_count               bigint,
    accident_count                     bigint,
    incident_count                     bigint,
    roadworks_hour_count               bigint,
    lane_closure_hour_count            bigint,
    mean_air_quality_index             double precision,
    co2_tonnes                         double precision,
    delay_cost_gbp                     double precision,
    carbon_cost_gbp                    double precision,
    collision_cost_gbp                 double precision,
    total_economic_cost_gbp            double precision,
    annualised_cost_gbp                double precision,
    annualised_delay_vehicle_hours     double precision,
    annualised_co2_tonnes              double precision
);
COPY marts.agg_network_daily FROM 'C:/its_data/exports/agg_network_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- agg_site_hour_profile  (3,551 rows, 22 columns) ----------
DROP TABLE IF EXISTS marts.agg_site_hour_profile CASCADE;
CREATE TABLE marts.agg_site_hour_profile (
    site_key                           text,
    site_code                          text,
    city_name                          text,
    road_id                            text,
    corridor                           text,
    road_type                          text,
    urbanisation_band                  text,
    hour_of_day                        bigint,
    day_type                           text,
    observation_count                  bigint,
    mean_flow                          double precision,
    median_flow                        double precision,
    p95_flow                           double precision,
    mean_speed_kmh                     double precision,
    p15_speed_kmh                      double precision,
    mean_journey_time_index            double precision,
    p95_journey_time_index             double precision,
    buffer_index                       double precision,
    mean_delay_vehicle_hours           double precision,
    accident_count                     bigint,
    mean_air_quality_index             double precision,
    delay_cost_gbp                     double precision
);
COPY marts.agg_site_hour_profile FROM 'C:/its_data/exports/agg_site_hour_profile.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- agg_site_risk_ranking  (74 rows, 27 columns) ----------
DROP TABLE IF EXISTS marts.agg_site_risk_ranking CASCADE;
CREATE TABLE marts.agg_site_risk_ranking (
    site_key                           text,
    site_code                          text,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    road_name                          text,
    corridor                           text,
    operating_unit                     text,
    road_type                          text,
    urbanisation_band                  text,
    scored_hours                       bigint,
    mean_collision_risk                double precision,
    p95_collision_risk                 double precision,
    priority_risk_hours                bigint,
    observed_accidents                 bigint,
    mean_journey_time_index            double precision,
    congested_hours_pct                double precision,
    total_vehicles                     bigint,
    delay_vehicle_hours                double precision,
    delay_cost_gbp                     double precision,
    total_economic_cost_gbp            double precision,
    annualised_cost_gbp                double precision,
    co2_tonnes                         double precision,
    rank_by_economic_cost              bigint,
    rank_by_collision_risk             bigint,
    rank_by_congestion                 bigint,
    intervention_priority_score        double precision
);
COPY marts.agg_site_risk_ranking FROM 'C:/its_data/exports/agg_site_risk_ranking.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d1_executive  (792 rows, 41 columns) ----------
DROP TABLE IF EXISTS report.rpt_d1_executive CASCADE;
CREATE TABLE report.rpt_d1_executive (
    year_month                         text,
    month_year_label                   text,
    calendar_year                      bigint,
    month_number                       bigint,
    fiscal_year                        text,
    calendar_quarter                   text,
    corridor                           text,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    road_name                          text,
    road_type                          text,
    operating_unit                     text,
    observation_count                  bigint,
    site_count                         bigint,
    total_vehicles                     bigint,
    total_pcu                          double precision,
    total_hgv                          bigint,
    vehicle_km                         double precision,
    mean_journey_time_index            double precision,
    p95_journey_time_index             double precision,
    mean_speed_kmh                     double precision,
    harmonic_mean_speed_kmh            double precision,
    delay_vehicle_hours                double precision,
    annualised_delay_vehicle_hours     double precision,
    congested_hours                    bigint,
    collisions                         bigint,
    incidents                          bigint,
    co2_tonnes                         double precision,
    annualised_co2_tonnes              double precision,
    mean_air_quality_index             double precision,
    delay_cost_gbp                     double precision,
    carbon_cost_gbp                    double precision,
    collision_cost_gbp                 double precision,
    breakdown_cost_gbp                 double precision,
    total_economic_cost_gbp            double precision,
    annualised_delay_cost_gbp          double precision,
    annualised_carbon_cost_gbp         double precision,
    annualised_collision_cost_gbp      double precision,
    annualised_breakdown_cost_gbp      double precision,
    annualised_cost_gbp                double precision
);
COPY report.rpt_d1_executive FROM 'C:/its_data/exports/rpt_d1_executive.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d2_congestion_profile  (3,551 rows, 29 columns) ----------
DROP TABLE IF EXISTS report.rpt_d2_congestion_profile CASCADE;
CREATE TABLE report.rpt_d2_congestion_profile (
    site_key                           text,
    site_code                          text,
    city_name                          text,
    road_id                            text,
    corridor                           text,
    road_type                          text,
    urbanisation_band                  text,
    operating_unit                     text,
    hour_of_day                        bigint,
    hour_label                         time,
    time_band                          text,
    time_band_order                    bigint,
    is_peak                            bigint,
    day_type                           text,
    observation_count                  bigint,
    mean_flow                          double precision,
    median_flow                        double precision,
    p95_flow                           double precision,
    mean_speed_kmh                     double precision,
    harmonic_mean_speed_kmh            double precision,
    mean_journey_time_index            double precision,
    p95_journey_time_index             double precision,
    buffer_index                       double precision,
    delay_vehicle_hours                double precision,
    congested_hours                    bigint,
    severe_hours                       bigint,
    collisions                         bigint,
    delay_cost_gbp                     double precision,
    annualised_cost_gbp                double precision
);
COPY report.rpt_d2_congestion_profile FROM 'C:/its_data/exports/rpt_d2_congestion_profile.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d2_delay_attribution  (815 rows, 22 columns) ----------
DROP TABLE IF EXISTS report.rpt_d2_delay_attribution CASCADE;
CREATE TABLE report.rpt_d2_delay_attribution (
    disruption_cause                   text,
    disruption_cause_order             bigint,
    corridor                           text,
    operating_unit                     text,
    time_band                          text,
    time_band_order                    bigint,
    weather_severity_band              text,
    disrupted_hours                    bigint,
    mean_journey_time_index            double precision,
    mean_speed_kmh                     double precision,
    delay_vehicle_hours                double precision,
    delay_cost_gbp                     double precision,
    delay_cost_per_hour                double precision,
    total_economic_cost_gbp            double precision,
    annualised_cost_gbp                double precision,
    baseline_delay_cost_per_hour       double precision,
    baseline_annualised_cost_per_hour  double precision,
    baseline_jti                       double precision,
    excess_delay_cost_gbp              double precision,
    excess_annualised_cost_gbp         double precision,
    excess_journey_time_index          double precision,
    is_controllable                    bigint
);
COPY report.rpt_d2_delay_attribution FROM 'C:/its_data/exports/rpt_d2_delay_attribution.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d2_hour_dow_matrix  (3,696 rows, 18 columns) ----------
DROP TABLE IF EXISTS report.rpt_d2_hour_dow_matrix CASCADE;
CREATE TABLE report.rpt_d2_hour_dow_matrix (
    hour_of_day                        bigint,
    hour_label                         time,
    time_band                          text,
    day_of_week_number                 bigint,
    day_name                           text,
    day_short_name                     text,
    day_type                           text,
    corridor                           text,
    city_name                          text,
    road_id                            text,
    observation_count                  bigint,
    mean_journey_time_index            double precision,
    mean_flow                          double precision,
    mean_speed_kmh                     double precision,
    delay_cost_gbp                     double precision,
    congested_hours                    bigint,
    congested_hours_pct                double precision,
    collisions                         bigint
);
COPY report.rpt_d2_hour_dow_matrix FROM 'C:/its_data/exports/rpt_d2_hour_dow_matrix.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d3_risk_band_capture  (36 rows, 12 columns) ----------
DROP TABLE IF EXISTS report.rpt_d3_risk_band_capture CASCADE;
CREATE TABLE report.rpt_d3_risk_band_capture (
    collision_risk_band                text,
    band_order                         bigint,
    corridor                           text,
    operating_unit                     text,
    scored_hours                       bigint,
    collisions                         bigint,
    mean_risk_score                    double precision,
    share_of_hours_pct                 double precision,
    share_of_collisions_pct            double precision,
    lift                               double precision,
    cumulative_hours_pct               double precision,
    cumulative_capture_pct             double precision
);
COPY report.rpt_d3_risk_band_capture FROM 'C:/its_data/exports/rpt_d3_risk_band_capture.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d3_safety_monthly  (11,772 rows, 32 columns) ----------
DROP TABLE IF EXISTS report.rpt_d3_safety_monthly CASCADE;
CREATE TABLE report.rpt_d3_safety_monthly (
    year_month                         text,
    month_year_label                   text,
    calendar_year                      bigint,
    month_number                       bigint,
    meteorological_season              text,
    corridor                           text,
    city_name                          text,
    road_id                            text,
    road_type                          text,
    operating_unit                     text,
    weather_severity_band              text,
    weather_key                        bigint,
    time_band                          text,
    time_band_order                    bigint,
    is_peak                            bigint,
    observation_count                  bigint,
    total_vehicles                     bigint,
    vehicle_km                         double precision,
    collisions                         bigint,
    incidents                          bigint,
    breakdowns                         bigint,
    obstructions                       bigint,
    vehicle_fires                      bigint,
    weather_incidents                  bigint,
    roadworks_hours                    bigint,
    lane_closure_hours                 bigint,
    mean_journey_time_index            double precision,
    mean_speed_kmh                     double precision,
    mean_visibility_km                 double precision,
    mean_rainfall_mm                   double precision,
    collision_cost_gbp                 double precision,
    annualised_collision_cost_gbp      double precision
);
COPY report.rpt_d3_safety_monthly FROM 'C:/its_data/exports/rpt_d3_safety_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d4_aqi_matrix  (12,089 rows, 16 columns) ----------
DROP TABLE IF EXISTS report.rpt_d4_aqi_matrix CASCADE;
CREATE TABLE report.rpt_d4_aqi_matrix (
    hour_of_day                        bigint,
    hour_label                         time,
    time_band                          text,
    month_number                       bigint,
    month_short_name                   text,
    meteorological_season              text,
    corridor                           text,
    city_name                          text,
    urbanisation_band                  text,
    observation_count                  bigint,
    mean_air_quality_index             double precision,
    aqi_exceedance_hours               bigint,
    mean_wind_speed_kmh                double precision,
    wind_normalised_aqi                double precision,
    mean_flow                          double precision,
    co2_tonnes                         double precision
);
COPY report.rpt_d4_aqi_matrix FROM 'C:/its_data/exports/rpt_d4_aqi_matrix.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d4_environment_monthly  (1,548 rows, 31 columns) ----------
DROP TABLE IF EXISTS report.rpt_d4_environment_monthly CASCADE;
CREATE TABLE report.rpt_d4_environment_monthly (
    year_month                         text,
    month_year_label                   text,
    calendar_year                      bigint,
    month_number                       bigint,
    meteorological_season              text,
    corridor                           text,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    road_type                          text,
    urbanisation_band                  text,
    operating_unit                     text,
    observation_count                  bigint,
    total_vehicles                     bigint,
    vehicle_km                         double precision,
    co2_tonnes                         double precision,
    annualised_co2_tonnes              double precision,
    co2_tonnes_car                     double precision,
    co2_tonnes_van                     double precision,
    co2_tonnes_hgv                     double precision,
    co2_tonnes_bus                     double precision,
    co2_tonnes_motorcycle              double precision,
    mean_air_quality_index             double precision,
    p95_air_quality_index              double precision,
    aqi_exceedance_hours               bigint,
    mean_wind_speed_kmh                double precision,
    mean_temperature_c                 double precision,
    mean_journey_time_index            double precision,
    mean_speed_kmh                     double precision,
    carbon_cost_gbp                    double precision,
    annualised_carbon_cost_gbp         double precision
);
COPY report.rpt_d4_environment_monthly FROM 'C:/its_data/exports/rpt_d4_environment_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d5_governance_daily  (59,481 rows, 30 columns) ----------
DROP TABLE IF EXISTS report.rpt_d5_governance_daily CASCADE;
CREATE TABLE report.rpt_d5_governance_daily (
    date_key                           bigint,
    full_date                          date,
    year_month                         text,
    month_year_label                   text,
    calendar_year                      bigint,
    day_type                           text,
    site_key                           text,
    site_code                          text,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    corridor                           text,
    operating_unit                     text,
    sensor_status                      text,
    records_received                   bigint,
    records_conformant                 bigint,
    records_quarantined                bigint,
    records_with_warning               bigint,
    conformance_rate_pct               double precision,
    quarantine_rate_pct                double precision,
    conformance_vs_sla_pct             double precision,
    is_sla_breach                      bigint,
    fail_dq01_traffic_null             bigint,
    fail_dq02_environment_null         bigint,
    fail_dq03_speed_invalid            bigint,
    fail_dq04_negative_count           bigint,
    fail_dq05_sum_mismatch             bigint,
    fail_dq06_dead_zero                bigint,
    fail_dq07_flow_spike               bigint,
    fail_dq08_duplicate                bigint
);
COPY report.rpt_d5_governance_daily FROM 'C:/its_data/exports/rpt_d5_governance_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- ---------- rpt_d5_rule_failures  (52,224 rows, 19 columns) ----------
DROP TABLE IF EXISTS report.rpt_d5_rule_failures CASCADE;
CREATE TABLE report.rpt_d5_rule_failures (
    rule_id                            text,
    rule_name                          text,
    quality_dimension                  text,
    severity                           text,
    disposition                        text,
    rule_description                   text,
    expected_threshold_pct             double precision,
    year_month                         text,
    month_year_label                   text,
    calendar_year                      bigint,
    operating_unit                     text,
    city_name                          text,
    corridor                           text,
    site_code                          text,
    sensor_status                      text,
    failure_count                      bigint,
    records_evaluated                  bigint,
    failure_rate_pct                   double precision,
    is_above_threshold                 bigint
);
COPY report.rpt_d5_rule_failures FROM 'C:/its_data/exports/rpt_d5_rule_failures.csv' WITH (FORMAT csv, HEADER true, NULL '');


-- =============================================================================
--  VERIFICATION  -  run this after the load. Every row should say OK.
-- =============================================================================
SELECT name, expected, actual,
       CASE WHEN expected = actual THEN 'OK' ELSE '*** CHECK ***' END AS status
FROM (
  SELECT 'dim_congestion', 4, (SELECT count(*) FROM marts.dim_congestion)
  UNION ALL SELECT 'dim_date', 1096, (SELECT count(*) FROM marts.dim_date)
  UNION ALL SELECT 'dim_event', 6, (SELECT count(*) FROM marts.dim_event)
  UNION ALL SELECT 'dim_incident', 6, (SELECT count(*) FROM marts.dim_incident)
  UNION ALL SELECT 'dim_model_metric', 21, (SELECT count(*) FROM marts.dim_model_metric)
  UNION ALL SELECT 'dim_sensor_status', 3, (SELECT count(*) FROM marts.dim_sensor_status)
  UNION ALL SELECT 'dim_site', 74, (SELECT count(*) FROM marts.dim_site)
  UNION ALL SELECT 'dim_time', 24, (SELECT count(*) FROM marts.dim_time)
  UNION ALL SELECT 'dim_weather', 3, (SELECT count(*) FROM marts.dim_weather)
  UNION ALL SELECT 'fct_data_quality', 100000, (SELECT count(*) FROM marts.fct_data_quality)
  UNION ALL SELECT 'fct_risk_score', 96652, (SELECT count(*) FROM marts.fct_risk_score)
  UNION ALL SELECT 'fct_traffic_observation', 96652, (SELECT count(*) FROM marts.fct_traffic_observation)
  UNION ALL SELECT 'agg_corridor_month', 324, (SELECT count(*) FROM marts.agg_corridor_month)
  UNION ALL SELECT 'agg_data_quality_daily', 59481, (SELECT count(*) FROM marts.agg_data_quality_daily)
  UNION ALL SELECT 'agg_network_daily', 22833, (SELECT count(*) FROM marts.agg_network_daily)
  UNION ALL SELECT 'agg_site_hour_profile', 3551, (SELECT count(*) FROM marts.agg_site_hour_profile)
  UNION ALL SELECT 'agg_site_risk_ranking', 74, (SELECT count(*) FROM marts.agg_site_risk_ranking)
  UNION ALL SELECT 'rpt_d1_executive', 792, (SELECT count(*) FROM report.rpt_d1_executive)
  UNION ALL SELECT 'rpt_d2_congestion_profile', 3551, (SELECT count(*) FROM report.rpt_d2_congestion_profile)
  UNION ALL SELECT 'rpt_d2_delay_attribution', 815, (SELECT count(*) FROM report.rpt_d2_delay_attribution)
  UNION ALL SELECT 'rpt_d2_hour_dow_matrix', 3696, (SELECT count(*) FROM report.rpt_d2_hour_dow_matrix)
  UNION ALL SELECT 'rpt_d3_risk_band_capture', 36, (SELECT count(*) FROM report.rpt_d3_risk_band_capture)
  UNION ALL SELECT 'rpt_d3_safety_monthly', 11772, (SELECT count(*) FROM report.rpt_d3_safety_monthly)
  UNION ALL SELECT 'rpt_d4_aqi_matrix', 12089, (SELECT count(*) FROM report.rpt_d4_aqi_matrix)
  UNION ALL SELECT 'rpt_d4_environment_monthly', 1548, (SELECT count(*) FROM report.rpt_d4_environment_monthly)
  UNION ALL SELECT 'rpt_d5_governance_daily', 59481, (SELECT count(*) FROM report.rpt_d5_governance_daily)
  UNION ALL SELECT 'rpt_d5_rule_failures', 52224, (SELECT count(*) FROM report.rpt_d5_rule_failures)
) t (name, expected, actual)
ORDER BY status DESC, name;