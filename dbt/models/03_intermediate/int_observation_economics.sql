{{ config(materialized='table', tags=['intermediate','economics'],
   description='Monetises every clean observation using UK appraisal unit values held in the ref_appraisal_parameters seed: delay valued at journey-purpose weighted values of time, carbon at the DESNZ central non-traded value, and collisions at the DfT average value of prevention. Expansion factors convert observed cost into an annualised network estimate.') }}

with obs as (
    select * from {{ ref('int_observations_clean') }}
),

w as (
    select * from {{ ref('int_site_sample_weight') }}
),

p as (
    select
        max(case when parameter_code = 'VOT_CAR'          then parameter_value end) as vot_car,
        max(case when parameter_code = 'VOT_VAN'          then parameter_value end) as vot_van,
        max(case when parameter_code = 'VOT_HGV'          then parameter_value end) as vot_hgv,
        max(case when parameter_code = 'VOT_BUS'          then parameter_value end) as vot_bus,
        max(case when parameter_code = 'VOT_MOTORCYCLE'   then parameter_value end) as vot_moto,
        max(case when parameter_code = 'CARBON_VALUE'     then parameter_value end) as carbon_value,
        max(case when parameter_code = 'COLLISION_AVERAGE' then parameter_value end) as collision_cost,
        max(case when parameter_code = 'INCIDENT_BREAKDOWN' then parameter_value end) as breakdown_cost
    from {{ ref('ref_appraisal_parameters') }}
),

calc as (
    select
        o.record_id,
        o.site_natural_key,
        o.observation_date,
        o.observation_ts,

        -- ---- delay ------------------------------------------------------
        coalesce(o.delay_minutes_per_vehicle, 0) / 60.0                 as delay_hours_per_vehicle,
        o.vehicle_count * coalesce(o.delay_minutes_per_vehicle, 0) / 60.0
                                                                        as total_delay_vehicle_hours,

        -- class-weighted value of the delay
        (coalesce(o.delay_minutes_per_vehicle,0) / 60.0) * (
              o.car_count        * p.vot_car
            + o.van_count        * p.vot_van
            + o.hgv_count        * p.vot_hgv
            + o.bus_count        * p.vot_bus
            + o.motorcycle_count * p.vot_moto
        )                                                               as delay_cost_gbp,

        -- ---- carbon -----------------------------------------------------
        o.co2_emission_kg / 1000.0                                      as co2_tonnes,
        o.co2_emission_kg / 1000.0 * p.carbon_value                     as carbon_cost_gbp,

        -- ---- safety -----------------------------------------------------
        o.accident_flag * p.collision_cost                              as collision_cost_gbp,
        case when o.incident_type = 'Breakdown' then p.breakdown_cost else 0 end
                                                                        as breakdown_cost_gbp,

        w.expansion_factor,
        w.annualisation_factor
    from obs o
    cross join p
    left join w on o.site_natural_key = w.site_natural_key
)

select
    *,
    delay_cost_gbp + carbon_cost_gbp + collision_cost_gbp + breakdown_cost_gbp
                                                        as total_economic_cost_gbp,
    (delay_cost_gbp + carbon_cost_gbp + collision_cost_gbp + breakdown_cost_gbp)
        * annualisation_factor                          as annualised_cost_gbp,
    total_delay_vehicle_hours * annualisation_factor    as annualised_delay_vehicle_hours,
    co2_tonnes * annualisation_factor                   as annualised_co2_tonnes
from calc
