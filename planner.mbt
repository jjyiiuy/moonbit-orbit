///|
pub struct DesignConstraint {
  minimum_altitude_km : Double
  maximum_altitude_km : Double
  maximum_eccentricity : Double
  maximum_delta_v_km_s : Double
  minimum_period_s : Double
  maximum_period_s : Double
} derive(Debug, Eq)

///|
pub struct DesignCandidate {
  elements : ClassicalElements
  score : Double
  feasible : Bool
  violations : Array[String]
} derive(Debug, Eq)

///|
pub struct LaunchWindow {
  epoch_day : Double
  duration_s : Double
  azimuth_rad : Double
  inclination_error_rad : Double
  feasible : Bool
} derive(Debug, Eq)

///|
pub fn DesignConstraint::leo() -> DesignConstraint {
  {
    minimum_altitude_km: 160.0,
    maximum_altitude_km: 2000.0,
    maximum_eccentricity: 0.1,
    maximum_delta_v_km_s: 10.0,
    minimum_period_s: 4000.0,
    maximum_period_s: 10000.0,
  }
}

///|
pub fn DesignConstraint::any() -> DesignConstraint {
  {
    minimum_altitude_km: -earth_radius_km,
    maximum_altitude_km: 1.0e9,
    maximum_eccentricity: 0.99,
    maximum_delta_v_km_s: 1.0e9,
    minimum_period_s: 0.0,
    maximum_period_s: 1.0e12,
  }
}

///|
pub fn evaluate_design(
  mu : Double,
  elements : ClassicalElements,
  constraint : DesignConstraint,
) -> DesignCandidate {
  let violations : Array[String] = []
  let altitude = elements.semi_major_axis_km * (1.0 - elements.eccentricity) -
    earth_radius_km
  let period = orbital_period(mu, elements.semi_major_axis_km)
  if altitude < constraint.minimum_altitude_km {
    violations.push("periapsis-altitude")
  }
  if altitude > constraint.maximum_altitude_km {
    violations.push("periapsis-altitude-high")
  }
  if elements.eccentricity > constraint.maximum_eccentricity {
    violations.push("eccentricity")
  }
  if period < constraint.minimum_period_s {
    violations.push("period-short")
  }
  if period > constraint.maximum_period_s {
    violations.push("period-long")
  }
  let score = altitude / constraint.maximum_altitude_km +
    (1.0 - elements.eccentricity) +
    @math.cos(elements.inclination_rad)
  { elements, score, feasible: violations.length() == 0, violations }
}

///|
pub fn rank_designs(
  candidates : Array[DesignCandidate],
) -> Array[DesignCandidate] {
  let result = candidates.copy()
  for i in 0..<result.length() {
    for j in (i + 1)..<result.length() {
      if result[j].score > result[i].score {
        let item = result[i]
        result[i] = result[j]
        result[j] = item
      }
    }
  }
  result
}

///|
pub fn feasible_designs(
  candidates : Array[DesignCandidate],
) -> Array[DesignCandidate] {
  candidates.filter(candidate => candidate.feasible)
}

///|
pub fn launch_azimuth(
  latitude_rad : Double,
  inclination_rad : Double,
) -> Double {
  if @math.cos(latitude_rad).abs() < 1.0e-12 {
    0.0
  } else {
    @math.asin(clamp_unit(@math.cos(inclination_rad) / @math.cos(latitude_rad)))
  }
}

///|
pub fn evaluate_launch_window(
  latitude_rad : Double,
  target_inclination_rad : Double,
  epoch_day : Double,
  duration_s : Double,
) -> LaunchWindow {
  let azimuth = launch_azimuth(latitude_rad, target_inclination_rad)
  let error = (target_inclination_rad - latitude_rad.abs()).abs()
  {
    epoch_day,
    duration_s: duration_s.max(0.0),
    azimuth_rad: azimuth,
    inclination_error_rad: error,
    feasible: error <= half_pi && duration_s > 0.0,
  }
}

///|
pub fn repeat_ground_track_period(
  mu : Double,
  semi_major_axis_km : Double,
  earth_rotation_s : Double,
  revolutions : Int,
) -> Double {
  if revolutions <= 0 {
    0.0
  } else {
    let orbit_period = orbital_period(mu, semi_major_axis_km)
    earth_rotation_s *
    Double::from_int(revolutions) /
    (Double::from_int(revolutions) + earth_rotation_s / orbit_period)
  }
}

///|
pub fn phasing_delta_v(
  mu : Double,
  radius_km : Double,
  phase_angle_rad : Double,
  cycles : Int,
) -> Double {
  if radius_km <= 0.0 || cycles <= 0 {
    0.0
  } else {
    let period = orbital_period(mu, radius_km)
    let desired = period *
      (1.0 + phase_angle_rad / two_pi / Double::from_int(cycles))
    let a = @math.pow(mu * desired * desired / (4.0 * pi * pi), 1.0 / 3.0)
    (vis_viva_velocity(mu, radius_km, a) -
    vis_viva_velocity(mu, radius_km, radius_km)).abs() *
    2.0
  }
}

///|
pub fn plane_change_delta_v(speed_km_s : Double, angle_rad : Double) -> Double {
  2.0 * speed_km_s.abs() * @math.sin(angle_rad.abs() / 2.0)
}

///|
pub fn combined_plane_change_delta_v(
  before_speed : Double,
  after_speed : Double,
  angle_rad : Double,
) -> Double {
  (before_speed * before_speed +
  after_speed * after_speed -
  2.0 * before_speed * after_speed * @math.cos(angle_rad))
  .max(0.0)
  .sqrt()
}

///|
pub fn inclination_change_cost(
  mu : Double,
  radius_km : Double,
  from_rad : Double,
  to_rad : Double,
) -> Double {
  plane_change_delta_v(
    vis_viva_velocity(mu, radius_km, radius_km),
    to_rad - from_rad,
  )
}

///|
pub fn circularize_cost(
  mu : Double,
  radius_km : Double,
  eccentricity : Double,
) -> Double {
  if radius_km <= 0.0 {
    0.0
  } else {
    let apoapsis = radius_km * (1.0 + eccentricity)
    (vis_viva_velocity(mu, radius_km, radius_km) -
    vis_viva_velocity(mu, radius_km, (radius_km + apoapsis) / 2.0)).abs()
  }
}

///|
pub fn transfer_time_estimate(
  mu : Double,
  first_radius_km : Double,
  second_radius_km : Double,
) -> Double {
  hohmann_transfer(mu, first_radius_km, second_radius_km).time_of_flight_s
}

///|
pub fn launch_window_sequence(
  start_day : Double,
  count : Int,
  spacing_s : Double,
  latitude_rad : Double,
  inclination_rad : Double,
) -> Array[LaunchWindow] {
  let result : Array[LaunchWindow] = []
  for i in 0..<count.max(0) {
    result.push(
      evaluate_launch_window(
        latitude_rad,
        inclination_rad,
        start_day + Double::from_int(i) * spacing_s / 86400.0,
        spacing_s,
      ),
    )
  }
  result
}

///|
pub fn best_launch_window(windows : Array[LaunchWindow]) -> LaunchWindow? {
  let mut best : LaunchWindow? = None
  for window in windows {
    if window.feasible &&
      (
        best is None ||
        window.inclination_error_rad < best.unwrap().inclination_error_rad
      ) {
      best = Some(window)
    }
  }
  best
}
