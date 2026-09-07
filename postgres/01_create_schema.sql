-- =============================================================================
--  Scotland ITS Analytics Platform  ->  PostgreSQL
--  01_create_schema.sql   Creates the schemas and all 27 warehouse tables.
--  Run:  psql -U postgres -d its_analytics -f 01_create_schema.sql
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS marts;
CREATE SCHEMA IF NOT EXISTS report;

COMMENT ON SCHEMA marts  IS 'Gold layer: Kimball star schema - dimensions, facts and aggregates.';
COMMENT ON SCHEMA report IS 'Dashboard serving layer: one pre-aggregate set per Power BI page.';


-- marts.agg_corridor_month  (324 rows)
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
    total_vehicles                     numeric,
    mean_speed_kmh                     double precision,
    mean_journey_time_index            double precision,
    congested_hours                    numeric,
    congested_hours_pct                double precision,
    delay_vehicle_hours                double precision,
    accident_count                     numeric,
    accidents_per_100m_vehicle_km      double precision,
    co2_tonnes                         double precision,
    total_economic_cost_gbp            double precision,
    annualised_cost_gbp                double precision
);

-- marts.agg_data_quality_daily  (59,481 rows)
DROP TABLE IF EXISTS marts.agg_data_quality_daily CASCADE;
CREATE TABLE marts.agg_data_quality_daily (
    date_key                           integer,
    full_date                          date,
    year_month                         text,
    site_key                           text,
    site_code                          text,
    city_name                          text,
    road_id                            text,
    operating_unit                     text,
    sensor_status                      text,
    records_received                   bigint,
    records_conformant                 numeric,
    records_quarantined                numeric,
    records_with_warning               numeric,
    conformance_rate_pct               double precision,
    quarantine_rate_pct                double precision,
    fail_dq01                          numeric,
    fail_dq02                          numeric,
    fail_dq03                          numeric,
    fail_dq04                          numeric,
    fail_dq05                          numeric,
    fail_dq06                          numeric,
    fail_dq07                          numeric,
    fail_dq08                          numeric
);

-- marts.agg_network_daily  (22,833 rows)
DROP TABLE IF EXISTS marts.agg_network_daily CASCADE;
CREATE TABLE marts.agg_network_daily (
    date_key                           integer,
    full_date                          date,
    calendar_year                      bigint,
    year_month                         text,
    day_type                           text,
    meteorological_season              text,
    is_school_holiday                  integer,
    city_name                          text,
    council_area                       text,
    road_id                            text,
    corridor                           text,
    road_type                          text,
    operating_unit                     text,
    observation_count                  bigint,
    active_site_count                  bigint,
    total_vehicles                     numeric,
    total_pcu                          decimal(38,1),
    total_hgv                          numeric,
    mean_speed_kmh                     double precision,
    harmonic_mean_speed_kmh            double precision,
    mean_journey_time_index            double precision,
    p95_journey_time_index             double precision,
    delay_vehicle_hours                double precision,
    congested_hour_count               numeric,
    accident_count                     numeric,
    incident_count                     numeric,
    roadworks_hour_count               numeric,
    lane_closure_hour_count            numeric,
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

-- marts.agg_site_hour_profile  (3,551 rows)
DROP TABLE IF EXISTS marts.agg_site_hour_profile CASCADE;
CREATE TABLE marts.agg_site_hour_profile (
    site_key                           text,
    site_code                          text,
    city_name                          text,
    road_id                            text,
    corridor                           text,
    road_type                          text,
    urbanisation_band                  text,
    hour_of_day                        integer,
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
    accident_count                     numeric,
    mean_air_quality_index             double precision,
    delay_cost_gbp                     double precision
);

-- marts.agg_site_risk_ranking  (74 rows)
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
    priority_risk_hours                numeric,
    observed_accidents                 numeric,
    mean_journey_time_index            double precision,
    congested_hours_pct                double precision,
    total_vehicles                     numeric,
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

-- marts.dim_congestion  (4 rows)
DROP TABLE IF EXISTS marts.dim_congestion CASCADE;
CREATE TABLE marts.dim_congestion (
    congestion_key                     integer,
    congestion_level                   text,
    jti_lower_bound                    decimal(3,2),
    jti_upper_bound                    decimal(4,2),
    display_colour_hex                 text,
    operational_response               text,
    is_target_breach                   integer
);

-- marts.dim_date  (1,096 rows)
DROP TABLE IF EXISTS marts.dim_date CASCADE;
CREATE TABLE marts.dim_date (
    date_key                           integer,
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
    is_weekend                         integer,
    day_type                           text,
    fiscal_year                        text,
    fiscal_quarter                     text,
    meteorological_season              text,
    is_school_holiday                  integer,
    school_period                      text,
    days_from_period_start             bigint,
    is_month_end                       integer
);

-- marts.dim_event  (6 rows)
DROP TABLE IF EXISTS marts.dim_event CASCADE;
CREATE TABLE marts.dim_event (
    event_key                          integer,
    event_type                         text,
    event_category                     text,
    is_planned_event                   integer,
    traffic_management_response        text,
    typical_demand_uplift              decimal(3,2)
);

-- marts.dim_incident  (6 rows)
DROP TABLE IF EXISTS marts.dim_incident CASCADE;
CREATE TABLE marts.dim_incident (
    incident_key                       integer,
    incident_type                      text,
    incident_category                  text,
    is_disruptive                      integer,
    is_reportable_casualty_event       integer,
    response_owner                     text,
    severity_rank                      integer
);

-- marts.dim_model_metric  (21 rows)
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
    trained_at                         timestamptz,
    metric_family                      text
);

-- marts.dim_sensor_status  (3 rows)
DROP TABLE IF EXISTS marts.dim_sensor_status CASCADE;
CREATE TABLE marts.dim_sensor_status (
    sensor_status_key                  integer,
    sensor_status                      text,
    is_operational                     integer,
    status_description                 text,
    maintenance_priority               text,
    display_colour_hex                 text
);

-- marts.dim_site  (74 rows)
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
    is_anglo_scottish                  integer,
    design_capacity_band               text,
    road_type                          text,
    latitude                           double precision,
    longitude                          double precision,
    speed_limit_kmh                    integer,
    speed_limit_mph                    double precision,
    segment_length_km                  double precision,
    km_from_city_centroid              double precision,
    urbanisation_band                  text,
    settlement_tier                    text,
    source_observation_count           bigint,
    first_observed_date                date,
    last_observed_date                 date
);

-- marts.dim_time  (24 rows)
DROP TABLE IF EXISTS marts.dim_time CASCADE;
CREATE TABLE marts.dim_time (
    time_key                           integer,
    hour_of_day                        integer,
    hour_label                         text,
    hour_range_label                   text,
    time_band                          text,
    time_band_order                    integer,
    is_peak                            integer,
    peak_flag_label                    text,
    peak_direction                     text,
    operational_shift                  text,
    is_daytime                         integer
);

-- marts.dim_weather  (3 rows)
DROP TABLE IF EXISTS marts.dim_weather CASCADE;
CREATE TABLE marts.dim_weather (
    weather_key                        integer,
    weather_severity_band              text,
    band_description                   text,
    display_colour_hex                 text,
    triggers_winter_service            integer
);

-- marts.fct_data_quality  (100,000 rows)
DROP TABLE IF EXISTS marts.fct_data_quality CASCADE;
CREATE TABLE marts.fct_data_quality (
    observation_id                     text,
    date_key                           integer,
    time_key                           integer,
    site_key                           text,
    sensor_status_key                  integer,
    observation_date                   date,
    city_name                          text,
    road_id                            text,
    sensor_status                      text,
    dq_disposition                     text,
    dq_primary_failure                 text,
    is_quarantined                     integer,
    has_warning                        integer,
    is_fully_conformant                integer,
    fail_dq01_traffic_null             integer,
    fail_dq02_environment_null         integer,
    fail_dq03_speed_invalid            integer,
    fail_dq04_negative_count           integer,
    fail_dq05_sum_mismatch             integer,
    fail_dq06_dead_zero                integer,
    fail_dq07_flow_spike               integer,
    fail_dq08_duplicate                integer,
    fail_dq10_out_of_window            integer,
    record_count                       integer
);

-- marts.fct_risk_score  (96,652 rows)
DROP TABLE IF EXISTS marts.fct_risk_score CASCADE;
CREATE TABLE marts.fct_risk_score (
    observation_id                     text,
    date_key                           integer,
    time_key                           integer,
    site_key                           text,
    actual_congestion_key              integer,
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
    actual_accident_flag               integer,
    is_priority_risk_hour              integer,
    scored_at                          timestamptz
);

-- marts.fct_traffic_observation  (96,652 rows)
DROP TABLE IF EXISTS marts.fct_traffic_observation CASCADE;
CREATE TABLE marts.fct_traffic_observation (
    observation_id                     text,
    date_key                           integer,
    time_key                           integer,
    site_key                           text,
    congestion_key                     integer,
    incident_key                       integer,
    event_key                          integer,
    sensor_status_key                  integer,
    weather_key                        integer,
    observation_ts                     timestamp,
    observation_date                   date,
    vehicle_count                      integer,
    car_count                          integer,
    van_count                          integer,
    hgv_count                          integer,
    bus_count                          integer,
    motorcycle_count                   integer,
    freight_vehicle_count              integer,
    pcu_count                          decimal(14,1),
    average_speed_kmh                  double precision,
    speed_limit_kmh                    integer,
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
    accident_flag                      integer,
    roadworks_flag                     integer,
    lane_closure_flag                  integer,
    public_event_flag                  integer,
    school_holiday_flag                integer,
    has_incident                       integer,
    disruption_cause                   text,
    disruption_cause_order             integer,
    is_disrupted                       integer,
    is_weekend                         integer,
    is_peak_hour                       integer,
    is_environment_imputed             integer,
    has_dq_warning                     integer,
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

-- report.rpt_d1_executive  (792 rows)
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
    total_vehicles                     numeric,
    total_pcu                          decimal(38,1),
    total_hgv                          numeric,
    vehicle_km                         double precision,
    mean_journey_time_index            double precision,
    p95_journey_time_index             double precision,
    mean_speed_kmh                     double precision,
    harmonic_mean_speed_kmh            double precision,
    delay_vehicle_hours                double precision,
    annualised_delay_vehicle_hours     double precision,
    congested_hours                    numeric,
    collisions                         numeric,
    incidents                          numeric,
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

-- report.rpt_d2_congestion_profile  (3,551 rows)
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
    hour_of_day                        integer,
    hour_label                         text,
    time_band                          text,
    time_band_order                    integer,
    is_peak                            integer,
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
    congested_hours                    numeric,
    severe_hours                       numeric,
    collisions                         numeric,
    delay_cost_gbp                     double precision,
    annualised_cost_gbp                double precision
);

-- report.rpt_d2_delay_attribution  (815 rows)
DROP TABLE IF EXISTS report.rpt_d2_delay_attribution CASCADE;
CREATE TABLE report.rpt_d2_delay_attribution (
    disruption_cause                   text,
    disruption_cause_order             integer,
    corridor                           text,
    operating_unit                     text,
    time_band                          text,
    time_band_order                    integer,
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
    is_controllable                    integer
);

-- report.rpt_d2_hour_dow_matrix  (3,696 rows)
DROP TABLE IF EXISTS report.rpt_d2_hour_dow_matrix CASCADE;
CREATE TABLE report.rpt_d2_hour_dow_matrix (
    hour_of_day                        integer,
    hour_label                         text,
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
    congested_hours                    numeric,
    congested_hours_pct                double precision,
    collisions                         numeric
);

-- report.rpt_d3_risk_band_capture  (36 rows)
DROP TABLE IF EXISTS report.rpt_d3_risk_band_capture CASCADE;
CREATE TABLE report.rpt_d3_risk_band_capture (
    collision_risk_band                text,
    band_order                         integer,
    corridor                           text,
    operating_unit                     text,
    scored_hours                       bigint,
    collisions                         numeric,
    mean_risk_score                    double precision,
    share_of_hours_pct                 double precision,
    share_of_collisions_pct            double precision,
    lift                               double precision,
    cumulative_hours_pct               double precision,
    cumulative_capture_pct             double precision
);

-- report.rpt_d3_safety_monthly  (11,772 rows)
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
    weather_key                        integer,
    time_band                          text,
    time_band_order                    integer,
    is_peak                            integer,
    observation_count                  bigint,
    total_vehicles                     numeric,
    vehicle_km                         double precision,
    collisions                         numeric,
    incidents                          numeric,
    breakdowns                         numeric,
    obstructions                       numeric,
    vehicle_fires                      numeric,
    weather_incidents                  numeric,
    roadworks_hours                    numeric,
    lane_closure_hours                 numeric,
    mean_journey_time_index            double precision,
    mean_speed_kmh                     double precision,
    mean_visibility_km                 double precision,
    mean_rainfall_mm                   double precision,
    collision_cost_gbp                 double precision,
    annualised_collision_cost_gbp      double precision
);

-- report.rpt_d4_aqi_matrix  (12,089 rows)
DROP TABLE IF EXISTS report.rpt_d4_aqi_matrix CASCADE;
CREATE TABLE report.rpt_d4_aqi_matrix (
    hour_of_day                        integer,
    hour_label                         text,
    time_band                          text,
    month_number                       bigint,
    month_short_name                   text,
    meteorological_season              text,
    corridor                           text,
    city_name                          text,
    urbanisation_band                  text,
    observation_count                  bigint,
    mean_air_quality_index             double precision,
    aqi_exceedance_hours               numeric,
    mean_wind_speed_kmh                double precision,
    wind_normalised_aqi                double precision,
    mean_flow                          double precision,
    co2_tonnes                         double precision
);

-- report.rpt_d4_environment_monthly  (1,548 rows)
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
    total_vehicles                     numeric,
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
    aqi_exceedance_hours               numeric,
    mean_wind_speed_kmh                double precision,
    mean_temperature_c                 double precision,
    mean_journey_time_index            double precision,
    mean_speed_kmh                     double precision,
    carbon_cost_gbp                    double precision,
    annualised_carbon_cost_gbp         double precision
);

-- report.rpt_d5_governance_daily  (59,481 rows)
DROP TABLE IF EXISTS report.rpt_d5_governance_daily CASCADE;
CREATE TABLE report.rpt_d5_governance_daily (
    date_key                           integer,
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
    records_conformant                 numeric,
    records_quarantined                numeric,
    records_with_warning               numeric,
    conformance_rate_pct               double precision,
    quarantine_rate_pct                double precision,
    conformance_vs_sla_pct             double precision,
    is_sla_breach                      integer,
    fail_dq01_traffic_null             numeric,
    fail_dq02_environment_null         numeric,
    fail_dq03_speed_invalid            numeric,
    fail_dq04_negative_count           numeric,
    fail_dq05_sum_mismatch             numeric,
    fail_dq06_dead_zero                numeric,
    fail_dq07_flow_spike               numeric,
    fail_dq08_duplicate                numeric
);

-- report.rpt_d5_rule_failures  (52,224 rows)
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
    failure_count                      numeric,
    records_evaluated                  bigint,
    failure_rate_pct                   double precision,
    is_above_threshold                 integer
);
