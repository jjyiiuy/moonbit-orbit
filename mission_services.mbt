///|
pub struct TrajectoryMetrics {
  duration_s : Double
  samples : Int
  distance_km : Double
  max_speed_km_s : Double
  min_altitude_km : Double
  max_altitude_km : Double
} derive(Debug, Eq)

///|
pub struct ResourceProfile {
  mass_kg : Double
  propellant_kg : Double
  power_w : Double
  data_rate_kbps : Double
  lifetime_days : Double
} derive(Debug, Eq)

///|
pub struct MissionScore {
  safety : Double
  coverage : Double
  cost : Double
  science : Double
  total : Double
} derive(Debug, Eq)

///|
pub fn trajectory_metrics(states : Array[DynamicsState]) -> TrajectoryMetrics {
  if states.length() == 0 {
    {
      duration_s: 0.0,
      samples: 0,
      distance_km: 0.0,
      max_speed_km_s: 0.0,
      min_altitude_km: 0.0,
      max_altitude_km: 0.0,
    }
  } else {
    let mut distance = 0.0
    let mut speed = 0.0
    let mut minimum = 1.0e300
    let mut maximum = -1.0e300
    for i in 0..<states.length() {
      let state = states[i].state
      speed = speed.max(state.velocity_km_s.norm())
      let altitude = state.position_km.norm() - earth_radius_km
      minimum = minimum.min(altitude)
      maximum = maximum.max(altitude)
      if i > 0 {
        distance += state.position_km.distance(states[i - 1].state.position_km)
      }
    }
    {
      duration_s: states[states.length() - 1].elapsed_s - states[0].elapsed_s,
      samples: states.length(),
      distance_km: distance,
      max_speed_km_s: speed,
      min_altitude_km: minimum,
      max_altitude_km: maximum,
    }
  }
}

///|
pub fn resource_profile(
  mass_kg : Double,
  dry_mass_fraction : Double,
  power_w : Double,
  data_rate_kbps : Double,
  lifetime_days : Double,
) -> ResourceProfile {
  {
    mass_kg: mass_kg.max(0.0),
    propellant_kg: mass_kg.max(0.0) * (1.0 - clamp(dry_mass_fraction, 0.0, 1.0)),
    power_w: power_w.max(0.0),
    data_rate_kbps: data_rate_kbps.max(0.0),
    lifetime_days: lifetime_days.max(0.0),
  }
}

///|
pub fn resource_mass_fraction(profile : ResourceProfile) -> Double {
  if profile.mass_kg == 0.0 {
    0.0
  } else {
    profile.propellant_kg / profile.mass_kg
  }
}

///|
pub fn resource_end_of_life_power(
  profile : ResourceProfile,
  degradation_fraction : Double,
) -> Double {
  profile.power_w * (1.0 - clamp(degradation_fraction, 0.0, 1.0))
}

///|
pub fn resource_data_volume_mb(profile : ResourceProfile) -> Double {
  profile.data_rate_kbps * profile.lifetime_days * 86400.0 / 8000.0
}

///|
pub fn score_mission(
  safety : Double,
  coverage : Double,
  cost : Double,
  science : Double,
  weights : Array[Double],
) -> MissionScore {
  let w = normalize_weights(weights)
  let a = if w.length() > 0 { w[0] } else { 0.25 }
  let b = if w.length() > 1 { w[1] } else { 0.25 }
  let c = if w.length() > 2 { w[2] } else { 0.25 }
  let d = if w.length() > 3 { w[3] } else { 0.25 }
  {
    safety,
    coverage,
    cost,
    science,
    total: a * safety + b * coverage + c * (1.0 - cost) + d * science,
  }
}

///|
pub fn coverage_grid(
  latitude_step_rad : Double,
  longitude_step_rad : Double,
) -> Array[Geodetic] {
  let result : Array[Geodetic] = []
  if latitude_step_rad <= 0.0 || longitude_step_rad <= 0.0 {
    return result
  }
  let mut lat = -half_pi
  while lat <= half_pi {
    let mut lon = -pi
    while lon < pi {
      result.push(Geodetic::new(lat, lon, 0.0))
      lon += longitude_step_rad
    }
    lat += latitude_step_rad
  }
  result
}

///|
pub fn coverage_cells_for_track(
  track : Array[GroundTrackPoint],
  latitude_step_rad : Double,
  longitude_step_rad : Double,
) -> Int {
  if latitude_step_rad <= 0.0 || longitude_step_rad <= 0.0 {
    0
  } else {
    let cells : Array[String] = []
    for point in track {
      let lat = (point.latitude_rad / latitude_step_rad).floor().to_int()
      let lon = (point.longitude_rad / longitude_step_rad).floor().to_int()
      let key = "\{lat}:\{lon}"
      if !cells.contains(key) {
        cells.push(key)
      }
    }
    cells.length()
  }
}

///|
pub fn payload_data_generated(
  profile : ResourceProfile,
  utilization : Double,
) -> Double {
  profile.data_rate_kbps *
  profile.lifetime_days *
  86400.0 *
  clamp(utilization, 0.0, 1.0) /
  8000.0
}

///|
pub fn battery_energy_wh(
  power_w : Double,
  eclipse_fraction : Double,
  orbit_period_s : Double,
) -> Double {
  power_w.max(0.0) *
  orbit_period_s.max(0.0) *
  clamp(eclipse_fraction, 0.0, 1.0) /
  3600.0
}

///|
pub fn solar_array_area_m2(
  power_w : Double,
  efficiency : Double,
  flux_w_m2 : Double,
) -> Double {
  if efficiency <= 0.0 || flux_w_m2 <= 0.0 {
    0.0
  } else {
    power_w.max(0.0) / (efficiency * flux_w_m2)
  }
}

///|
pub fn antenna_link_margin_db(
  tx_power_dbw : Double,
  gains_db : Double,
  path_loss_db : Double,
  system_loss_db : Double,
  required_db : Double,
) -> Double {
  tx_power_dbw + gains_db - path_loss_db - system_loss_db - required_db
}

///|
pub fn free_space_path_loss_db(
  distance_km : Double,
  frequency_ghz : Double,
) -> Double {
  if distance_km <= 0.0 || frequency_ghz <= 0.0 {
    0.0
  } else {
    92.45 + 20.0 * @math.log10(distance_km) + 20.0 * @math.log10(frequency_ghz)
  }
}

///|
pub fn doppler_shift_hz(
  carrier_hz : Double,
  radial_speed_km_s : Double,
) -> Double {
  carrier_hz * radial_speed_km_s / 299792.458
}

///|
pub fn contact_data_volume_mb(
  rate_kbps : Double,
  duration_s : Double,
) -> Double {
  rate_kbps.max(0.0) * duration_s.max(0.0) / 8000.0
}

///|
pub fn thermal_power_margin(
  power_budget_w : Double,
  power_load_w : Double,
) -> Double {
  power_budget_w - power_load_w
}

///|
pub fn lifetime_margin_days(
  lifetime_days : Double,
  planned_days : Double,
) -> Double {
  lifetime_days - planned_days
}

///|
pub fn mission_success_probability(probabilities : Array[Double]) -> Double {
  probabilities.fold(init=1.0, (total, probability) => {
    total * clamp(probability, 0.0, 1.0)
  })
}

///|
pub fn risk_weighted_cost(
  cost : Double,
  probability : Double,
  consequence : Double,
) -> Double {
  cost + clamp(probability, 0.0, 1.0) * consequence.max(0.0)
}

///|
pub fn schedule_finish_time(events : Array[MissionEvent]) -> Double {
  events.fold(init=0.0, (finish, event) => {
    finish.max(event.time_s + event.duration_s)
  })
}

///|
pub fn schedule_overlap_count(events : Array[MissionEvent]) -> Int {
  let mut count = 0
  for i in 0..<events.length() {
    for j in (i + 1)..<events.length() {
      if events[i].time_s < events[j].time_s + events[j].duration_s &&
        events[j].time_s < events[i].time_s + events[i].duration_s {
        count += 1
      }
    }
  }
  count
}

///|
pub fn schedule_idle_time(events : Array[MissionEvent]) -> Double {
  let ordered = events
    .fold(init=MissionTimeline::new(), (timeline, event) => timeline.add(event))
    .sort_by_time()
  if ordered.events.length() < 2 {
    0.0
  } else {
    let mut idle = 0.0
    for i in 0..<(ordered.events.length() - 1) {
      idle += (ordered.events[i + 1].time_s -
      (ordered.events[i].time_s + ordered.events[i].duration_s)).max(0.0)
    }
    idle
  }
}

///|
pub fn state_position_error(
  reference : StateVector,
  estimate : StateVector,
) -> Double {
  reference.position_km.distance(estimate.position_km)
}

///|
pub fn state_velocity_error(
  reference : StateVector,
  estimate : StateVector,
) -> Double {
  reference.velocity_km_s.distance(estimate.velocity_km_s)
}

///|
pub fn state_relative_error(
  reference : StateVector,
  estimate : StateVector,
) -> Double {
  state_position_error(reference, estimate) +
  state_velocity_error(reference, estimate)
}

///|
pub fn interpolate_state(
  a : StateVector,
  b : StateVector,
  t : Double,
) -> StateVector {
  StateVector::new(
    a.position_km.lerp(b.position_km, t),
    a.velocity_km_s.lerp(b.velocity_km_s, t),
  )
}
