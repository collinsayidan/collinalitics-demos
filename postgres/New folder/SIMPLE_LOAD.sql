-- =============================================================================
--  SIMPLE_LOAD.sql   -   the beginner-friendly version
--
--  No DO block, no variables, no loops. Just 27 plain COPY statements.
--  If one fails, you know exactly which table, and the others are unaffected.
--
--  IF YOUR CSVs ARE SOMEWHERE ELSE: use Find and Replace (Ctrl+H) to swap
--      C:/its_data/exports
--  for your folder. Forward slashes only.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1  Am I in the right place?  Should say: its_analytics
-- -----------------------------------------------------------------------------
SELECT current_database();


-- -----------------------------------------------------------------------------
-- STEP 2  Try ONE small table first. Run just these two lines.
--         If this works, everything else will work the same way.
-- -----------------------------------------------------------------------------
TRUNCATE TABLE marts.dim_time CASCADE;
COPY marts.dim_time FROM 'C:/its_data/exports/dim_time.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Check it: should return 24
SELECT count(*) FROM marts.dim_time;


-- -----------------------------------------------------------------------------
-- STEP 3  That worked?  Now run everything below in one go.
--         Empty all the tables first.
-- -----------------------------------------------------------------------------
TRUNCATE TABLE report.rpt_d5_rule_failures CASCADE;
TRUNCATE TABLE report.rpt_d5_governance_daily CASCADE;
TRUNCATE TABLE report.rpt_d4_aqi_matrix CASCADE;
TRUNCATE TABLE report.rpt_d4_environment_monthly CASCADE;
TRUNCATE TABLE report.rpt_d3_risk_band_capture CASCADE;
TRUNCATE TABLE report.rpt_d3_safety_monthly CASCADE;
TRUNCATE TABLE report.rpt_d2_hour_dow_matrix CASCADE;
TRUNCATE TABLE report.rpt_d2_delay_attribution CASCADE;
TRUNCATE TABLE report.rpt_d2_congestion_profile CASCADE;
TRUNCATE TABLE report.rpt_d1_executive CASCADE;
TRUNCATE TABLE marts.agg_site_risk_ranking CASCADE;
TRUNCATE TABLE marts.agg_data_quality_daily CASCADE;
TRUNCATE TABLE marts.agg_corridor_month CASCADE;
TRUNCATE TABLE marts.agg_site_hour_profile CASCADE;
TRUNCATE TABLE marts.agg_network_daily CASCADE;
TRUNCATE TABLE marts.fct_risk_score CASCADE;
TRUNCATE TABLE marts.fct_data_quality CASCADE;
TRUNCATE TABLE marts.fct_traffic_observation CASCADE;
TRUNCATE TABLE marts.dim_model_metric CASCADE;
TRUNCATE TABLE marts.dim_weather CASCADE;
TRUNCATE TABLE marts.dim_sensor_status CASCADE;
TRUNCATE TABLE marts.dim_event CASCADE;
TRUNCATE TABLE marts.dim_incident CASCADE;
TRUNCATE TABLE marts.dim_congestion CASCADE;
TRUNCATE TABLE marts.dim_site CASCADE;
TRUNCATE TABLE marts.dim_time CASCADE;
TRUNCATE TABLE marts.dim_date CASCADE;


-- -----------------------------------------------------------------------------
-- STEP 4  Load every table. Dimensions first, then facts, then the rest.
-- -----------------------------------------------------------------------------
COPY marts.dim_date FROM 'C:/its_data/exports/dim_date.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 1,096 rows
COPY marts.dim_time FROM 'C:/its_data/exports/dim_time.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 24 rows
COPY marts.dim_site FROM 'C:/its_data/exports/dim_site.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 74 rows
COPY marts.dim_congestion FROM 'C:/its_data/exports/dim_congestion.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 4 rows
COPY marts.dim_incident FROM 'C:/its_data/exports/dim_incident.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 6 rows
COPY marts.dim_event FROM 'C:/its_data/exports/dim_event.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 6 rows
COPY marts.dim_sensor_status FROM 'C:/its_data/exports/dim_sensor_status.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 3 rows
COPY marts.dim_weather FROM 'C:/its_data/exports/dim_weather.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 3 rows
COPY marts.dim_model_metric FROM 'C:/its_data/exports/dim_model_metric.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 21 rows
COPY marts.fct_traffic_observation FROM 'C:/its_data/exports/fct_traffic_observation.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 96,652 rows
COPY marts.fct_data_quality FROM 'C:/its_data/exports/fct_data_quality.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 100,000 rows
COPY marts.fct_risk_score FROM 'C:/its_data/exports/fct_risk_score.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 96,652 rows
COPY marts.agg_network_daily FROM 'C:/its_data/exports/agg_network_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 22,838 rows
COPY marts.agg_site_hour_profile FROM 'C:/its_data/exports/agg_site_hour_profile.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 3,551 rows
COPY marts.agg_corridor_month FROM 'C:/its_data/exports/agg_corridor_month.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 324 rows
COPY marts.agg_data_quality_daily FROM 'C:/its_data/exports/agg_data_quality_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 59,481 rows
COPY marts.agg_site_risk_ranking FROM 'C:/its_data/exports/agg_site_risk_ranking.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 74 rows
COPY report.rpt_d1_executive FROM 'C:/its_data/exports/rpt_d1_executive.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 792 rows
COPY report.rpt_d2_congestion_profile FROM 'C:/its_data/exports/rpt_d2_congestion_profile.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 3,551 rows
COPY report.rpt_d2_delay_attribution FROM 'C:/its_data/exports/rpt_d2_delay_attribution.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 816 rows
COPY report.rpt_d2_hour_dow_matrix FROM 'C:/its_data/exports/rpt_d2_hour_dow_matrix.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 3,696 rows
COPY report.rpt_d3_safety_monthly FROM 'C:/its_data/exports/rpt_d3_safety_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 11,779 rows
COPY report.rpt_d3_risk_band_capture FROM 'C:/its_data/exports/rpt_d3_risk_band_capture.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 36 rows
COPY report.rpt_d4_environment_monthly FROM 'C:/its_data/exports/rpt_d4_environment_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 1,548 rows
COPY report.rpt_d4_aqi_matrix FROM 'C:/its_data/exports/rpt_d4_aqi_matrix.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 12,090 rows
COPY report.rpt_d5_governance_daily FROM 'C:/its_data/exports/rpt_d5_governance_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 59,481 rows
COPY report.rpt_d5_rule_failures FROM 'C:/its_data/exports/rpt_d5_rule_failures.csv' WITH (FORMAT csv, HEADER true, NULL '');   -- expect 52,224 rows


-- -----------------------------------------------------------------------------
-- STEP 5  Check every table loaded. Compare against the expected counts above.
-- -----------------------------------------------------------------------------
SELECT schemaname AS schema, relname AS table_name, n_live_tup AS rows
FROM pg_stat_user_tables
WHERE schemaname IN ('marts','report')
ORDER BY n_live_tup DESC;


-- -----------------------------------------------------------------------------
-- STEP 6  Does the data make sense?  Compare to the values in the comments.
-- -----------------------------------------------------------------------------
SELECT count(*)                                          AS observations,   -- 96652
       round(avg(journey_time_index)::numeric, 3)        AS jti,            -- about 1.167
       sum(accident_flag)                                AS collisions      -- about 344
FROM marts.fct_traffic_observation;

SELECT city_name,
       count(*) AS observations,
       round(avg(journey_time_index)::numeric, 3) AS jti
FROM marts.fct_traffic_observation f
JOIN marts.dim_site s USING (site_key)
GROUP BY city_name
ORDER BY observations DESC;


DROP TABLE IF EXISTS marts.fct_traffic_observation CASCADE;
SELECT count(*) FROM information_schema.tables WHERE table_name = 'fct_traffic_observation';
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

SELECT count(*) FROM information_schema.columns WHERE table_name = 'fct_traffic_observation';


SELECT schemaname, relname AS table_name, n_live_tup AS rows
FROM pg_stat_user_tables
WHERE schemaname IN ('marts','report')
ORDER BY n_live_tup DESC;

SELECT s.city_name,
       count(*)                                    AS observations,
       round(avg(f.journey_time_index)::numeric,3) AS journey_time_index,
       round((sum(f.annualised_cost_gbp)/1e6)::numeric,1) AS annual_cost_gbp_m
FROM marts.fct_traffic_observation f
JOIN marts.dim_site s USING (site_key)
GROUP BY s.city_name
ORDER BY annual_cost_gbp_m DESC;