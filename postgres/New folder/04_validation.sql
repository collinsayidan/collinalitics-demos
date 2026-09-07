-- =============================================================================
--  04_validation.sql
--  Proves the PostgreSQL copy matches the verified warehouse. Every expected
--  value comes from the dbt build that passes 120/120 tests.
--      psql -U postgres -d its_analytics -f postgres/04_validation.sql
-- =============================================================================

\timing off
\echo '=== ROW COUNTS ==='
SELECT 'fct_traffic_observation' AS table_name, count(*) AS actual, 96652 AS expected FROM marts.fct_traffic_observation
UNION ALL SELECT 'fct_data_quality',   count(*), 100000 FROM marts.fct_data_quality
UNION ALL SELECT 'fct_risk_score',     count(*),  96652 FROM marts.fct_risk_score
UNION ALL SELECT 'dim_site',           count(*),     74 FROM marts.dim_site
UNION ALL SELECT 'dim_date',           count(*),   1096 FROM marts.dim_date
UNION ALL SELECT 'rpt_d1_executive',   count(*),    792 FROM report.rpt_d1_executive
UNION ALL SELECT 'rpt_d5_rule_failures', count(*), 52224 FROM report.rpt_d5_rule_failures;

\echo ''
\echo '=== HEADLINE MEASURES  (compare against ITS-BI-003 section 12) ==='
SELECT
    round(avg(journey_time_index)::numeric, 3)                                   AS journey_time_index,   -- 1.167
    round((100.0 * sum(CASE WHEN congestion_key >= 3 THEN 1 ELSE 0 END) / count(*))::numeric, 2)
                                                                                 AS congested_hours_pct,  -- 8.14
    round((sum(annualised_cost_gbp) / 1e6)::numeric, 1)                          AS annual_cost_gbp_m,    -- 1353.3
    round((100.0 * sum(carbon_cost_gbp * annualisation_factor) / sum(annualised_cost_gbp))::numeric, 1)
                                                                                 AS carbon_share_pct,     -- 44.3
    sum(accident_flag)                                                           AS collisions            -- 344
FROM marts.fct_traffic_observation;

SELECT
    round((100.0 * sum(is_fully_conformant) / count(*))::numeric, 2) AS conformance_pct,  -- 95.70
    round((100.0 * sum(is_quarantined)      / count(*))::numeric, 2) AS quarantine_pct    -- 3.35
FROM marts.fct_data_quality;

\echo ''
\echo '=== BUSINESS RULE: class counts must reconcile (expect 0 rows) ==='
SELECT count(*) AS rule1_violations
FROM marts.fct_traffic_observation
WHERE vehicle_count IS NULL OR car_count IS NULL OR bus_count IS NULL
   OR hgv_count IS NULL OR motorcycle_count IS NULL OR van_count IS NULL
   OR vehicle_count <> car_count + bus_count + hgv_count + motorcycle_count + van_count;

\echo ''
\echo '=== BUSINESS RULE: speed must fall as congestion rises ==='
SELECT c.congestion_level,
       count(*)                                        AS hours,
       round(avg(f.average_speed_kmh)::numeric, 1)     AS mean_speed_kmh,
       round(avg(f.journey_time_index)::numeric, 3)    AS mean_jti
FROM marts.fct_traffic_observation f
JOIN marts.dim_congestion c USING (congestion_key)
GROUP BY c.congestion_level, c.congestion_key
ORDER BY c.congestion_key;   -- 94.6 -> 80.8 -> 62.9 -> 40.4

\echo ''
\echo '=== SERVING LAYER RECONCILIATION (all should equal 96,652) ==='
SELECT 'rpt_d1_executive' AS serving_table, sum(observation_count) AS observations FROM report.rpt_d1_executive
UNION ALL SELECT 'rpt_d2_congestion_profile', sum(observation_count) FROM report.rpt_d2_congestion_profile
UNION ALL SELECT 'rpt_d2_delay_attribution',  sum(disrupted_hours)   FROM report.rpt_d2_delay_attribution
UNION ALL SELECT 'rpt_d2_hour_dow_matrix',    sum(observation_count) FROM report.rpt_d2_hour_dow_matrix
UNION ALL SELECT 'rpt_d3_safety_monthly',     sum(observation_count) FROM report.rpt_d3_safety_monthly
UNION ALL SELECT 'rpt_d4_environment_monthly',sum(observation_count) FROM report.rpt_d4_environment_monthly
UNION ALL SELECT 'rpt_d4_aqi_matrix',         sum(observation_count) FROM report.rpt_d4_aqi_matrix;

\echo ''
\echo '=== THE HEADLINE: where the money is ==='
SELECT s.city_name,
       round((sum(f.annualised_cost_gbp) / 1e6)::numeric, 1) AS annual_cost_gbp_m,
       round(avg(f.journey_time_index)::numeric, 3)          AS jti,
       round((100.0 * sum(CASE WHEN f.congestion_key >= 3 THEN 1 ELSE 0 END) / count(*))::numeric, 2)
                                                             AS congested_pct
FROM marts.fct_traffic_observation f
JOIN marts.dim_site s USING (site_key)
GROUP BY s.city_name
ORDER BY annual_cost_gbp_m DESC;
