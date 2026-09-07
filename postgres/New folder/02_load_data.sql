-- =============================================================================
--  02_load_data.sql   Loads every table from the CSV exports.
--  Uses \copy (client side) so PostgreSQL needs no filesystem access.
--  Run from the repository root so the relative paths resolve:
--      psql -U postgres -d its_analytics -f postgres/02_load_data.sql
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

\echo 'Loading marts.agg_corridor_month (324 rows)...'
\copy marts.agg_corridor_month FROM 'powerbi/exports/agg_corridor_month.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.agg_data_quality_daily (59,481 rows)...'
\copy marts.agg_data_quality_daily FROM 'powerbi/exports/agg_data_quality_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.agg_network_daily (22,833 rows)...'
\copy marts.agg_network_daily FROM 'powerbi/exports/agg_network_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.agg_site_hour_profile (3,551 rows)...'
\copy marts.agg_site_hour_profile FROM 'powerbi/exports/agg_site_hour_profile.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.agg_site_risk_ranking (74 rows)...'
\copy marts.agg_site_risk_ranking FROM 'powerbi/exports/agg_site_risk_ranking.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_congestion (4 rows)...'
\copy marts.dim_congestion FROM 'powerbi/exports/dim_congestion.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_date (1,096 rows)...'
\copy marts.dim_date FROM 'powerbi/exports/dim_date.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_event (6 rows)...'
\copy marts.dim_event FROM 'powerbi/exports/dim_event.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_incident (6 rows)...'
\copy marts.dim_incident FROM 'powerbi/exports/dim_incident.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_model_metric (21 rows)...'
\copy marts.dim_model_metric FROM 'powerbi/exports/dim_model_metric.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_sensor_status (3 rows)...'
\copy marts.dim_sensor_status FROM 'powerbi/exports/dim_sensor_status.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_site (74 rows)...'
\copy marts.dim_site FROM 'powerbi/exports/dim_site.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_time (24 rows)...'
\copy marts.dim_time FROM 'powerbi/exports/dim_time.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.dim_weather (3 rows)...'
\copy marts.dim_weather FROM 'powerbi/exports/dim_weather.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.fct_data_quality (100,000 rows)...'
\copy marts.fct_data_quality FROM 'powerbi/exports/fct_data_quality.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.fct_risk_score (96,652 rows)...'
\copy marts.fct_risk_score FROM 'powerbi/exports/fct_risk_score.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading marts.fct_traffic_observation (96,652 rows)...'
\copy marts.fct_traffic_observation FROM 'powerbi/exports/fct_traffic_observation.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d1_executive (792 rows)...'
\copy report.rpt_d1_executive FROM 'powerbi/exports/rpt_d1_executive.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d2_congestion_profile (3,551 rows)...'
\copy report.rpt_d2_congestion_profile FROM 'powerbi/exports/rpt_d2_congestion_profile.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d2_delay_attribution (815 rows)...'
\copy report.rpt_d2_delay_attribution FROM 'powerbi/exports/rpt_d2_delay_attribution.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d2_hour_dow_matrix (3,696 rows)...'
\copy report.rpt_d2_hour_dow_matrix FROM 'powerbi/exports/rpt_d2_hour_dow_matrix.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d3_risk_band_capture (36 rows)...'
\copy report.rpt_d3_risk_band_capture FROM 'powerbi/exports/rpt_d3_risk_band_capture.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d3_safety_monthly (11,772 rows)...'
\copy report.rpt_d3_safety_monthly FROM 'powerbi/exports/rpt_d3_safety_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d4_aqi_matrix (12,089 rows)...'
\copy report.rpt_d4_aqi_matrix FROM 'powerbi/exports/rpt_d4_aqi_matrix.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d4_environment_monthly (1,548 rows)...'
\copy report.rpt_d4_environment_monthly FROM 'powerbi/exports/rpt_d4_environment_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d5_governance_daily (59,481 rows)...'
\copy report.rpt_d5_governance_daily FROM 'powerbi/exports/rpt_d5_governance_daily.csv' WITH (FORMAT csv, HEADER true, NULL '');
\echo 'Loading report.rpt_d5_rule_failures (52,224 rows)...'
\copy report.rpt_d5_rule_failures FROM 'powerbi/exports/rpt_d5_rule_failures.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo 'Load complete. Run 03_indexes_constraints.sql next.'
