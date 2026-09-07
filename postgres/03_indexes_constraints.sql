-- =============================================================================
--  03_indexes_constraints.sql
--  Primary keys, foreign keys and query indexes.
--  Run AFTER loading - constraints on an empty table slow the load down and
--  add nothing, whereas validating them after the load proves the data is sound.
--      psql -U postgres -d its_analytics -f postgres/03_indexes_constraints.sql
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

-- ---------------------------------------------------------------- dimensions
ALTER TABLE marts.dim_date          ADD PRIMARY KEY (date_key);
ALTER TABLE marts.dim_time          ADD PRIMARY KEY (time_key);
ALTER TABLE marts.dim_site          ADD PRIMARY KEY (site_key);
ALTER TABLE marts.dim_congestion    ADD PRIMARY KEY (congestion_key);
ALTER TABLE marts.dim_incident      ADD PRIMARY KEY (incident_key);
ALTER TABLE marts.dim_event         ADD PRIMARY KEY (event_key);
ALTER TABLE marts.dim_sensor_status ADD PRIMARY KEY (sensor_status_key);
ALTER TABLE marts.dim_weather       ADD PRIMARY KEY (weather_key);
ALTER TABLE marts.dim_model_metric  ADD PRIMARY KEY (metric_key);

CREATE UNIQUE INDEX ux_dim_site_natural ON marts.dim_site (site_natural_key);
CREATE UNIQUE INDEX ux_dim_date_full    ON marts.dim_date (full_date);

-- --------------------------------------------------------------------- facts
ALTER TABLE marts.fct_traffic_observation ADD PRIMARY KEY (observation_id);
ALTER TABLE marts.fct_data_quality        ADD PRIMARY KEY (observation_id);
ALTER TABLE marts.fct_risk_score          ADD PRIMARY KEY (observation_id);
ALTER TABLE marts.agg_site_risk_ranking   ADD PRIMARY KEY (site_key);

-- Referential integrity. If any of these fail, the load is wrong - the dbt
-- suite already proves they hold in the source warehouse.
ALTER TABLE marts.fct_traffic_observation
    ADD CONSTRAINT fk_fto_date       FOREIGN KEY (date_key)          REFERENCES marts.dim_date (date_key),
    ADD CONSTRAINT fk_fto_time       FOREIGN KEY (time_key)          REFERENCES marts.dim_time (time_key),
    ADD CONSTRAINT fk_fto_site       FOREIGN KEY (site_key)          REFERENCES marts.dim_site (site_key),
    ADD CONSTRAINT fk_fto_congestion FOREIGN KEY (congestion_key)    REFERENCES marts.dim_congestion (congestion_key),
    ADD CONSTRAINT fk_fto_incident   FOREIGN KEY (incident_key)      REFERENCES marts.dim_incident (incident_key),
    ADD CONSTRAINT fk_fto_event      FOREIGN KEY (event_key)         REFERENCES marts.dim_event (event_key),
    ADD CONSTRAINT fk_fto_sensor     FOREIGN KEY (sensor_status_key) REFERENCES marts.dim_sensor_status (sensor_status_key),
    ADD CONSTRAINT fk_fto_weather    FOREIGN KEY (weather_key)       REFERENCES marts.dim_weather (weather_key);

ALTER TABLE marts.fct_risk_score
    ADD CONSTRAINT fk_frs_obs  FOREIGN KEY (observation_id) REFERENCES marts.fct_traffic_observation (observation_id),
    ADD CONSTRAINT fk_frs_site FOREIGN KEY (site_key)       REFERENCES marts.dim_site (site_key);

-- ------------------------------------------------------------------- indexes
-- Foreign key columns are not indexed automatically in PostgreSQL, and every
-- star-schema join uses one. These are the difference between a 40 ms and a
-- 4 s dashboard query.
CREATE INDEX ix_fto_date       ON marts.fct_traffic_observation (date_key);
CREATE INDEX ix_fto_site       ON marts.fct_traffic_observation (site_key);
CREATE INDEX ix_fto_time       ON marts.fct_traffic_observation (time_key);
CREATE INDEX ix_fto_congestion ON marts.fct_traffic_observation (congestion_key);
CREATE INDEX ix_fto_site_date  ON marts.fct_traffic_observation (site_key, date_key);
CREATE INDEX ix_fto_cause      ON marts.fct_traffic_observation (disruption_cause);

CREATE INDEX ix_fdq_date   ON marts.fct_data_quality (date_key);
CREATE INDEX ix_fdq_site   ON marts.fct_data_quality (site_key);
CREATE INDEX ix_fdq_disp   ON marts.fct_data_quality (dq_disposition);

CREATE INDEX ix_frs_band   ON marts.fct_risk_score (collision_risk_band);
CREATE INDEX ix_frs_prio   ON marts.fct_risk_score (is_priority_risk_hour);

CREATE INDEX ix_and_date   ON marts.agg_network_daily (date_key);
CREATE INDEX ix_and_city   ON marts.agg_network_daily (city_name);

-- serving layer: filtered by their own slicers, so index the slicer columns
CREATE INDEX ix_d1_month    ON report.rpt_d1_executive (year_month);
CREATE INDEX ix_d1_corridor ON report.rpt_d1_executive (corridor);
CREATE INDEX ix_d2_site     ON report.rpt_d2_congestion_profile (site_key);
CREATE INDEX ix_d2_hour     ON report.rpt_d2_congestion_profile (hour_of_day);
CREATE INDEX ix_d2_cause    ON report.rpt_d2_delay_attribution (disruption_cause);
CREATE INDEX ix_d3_month    ON report.rpt_d3_safety_monthly (year_month);
CREATE INDEX ix_d4_month    ON report.rpt_d4_environment_monthly (year_month);
CREATE INDEX ix_d5_date     ON report.rpt_d5_governance_daily (date_key);
CREATE INDEX ix_d5_site     ON report.rpt_d5_governance_daily (site_key);
CREATE INDEX ix_d5_rule     ON report.rpt_d5_rule_failures (rule_id);

-- Refresh planner statistics. Without this the optimiser plans against an
-- empty table and picks nested loops over hash joins.
ANALYZE;

\echo 'Constraints and indexes applied. Run 04_validation.sql to verify.'
