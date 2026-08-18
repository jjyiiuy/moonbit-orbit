///|
pub struct SafetyAssessment {
  minimum_distance_km : Double
  relative_speed_km_s : Double
  closing_speed_km_s : Double
  time_to_closest_s : Double
  collision_probability_proxy : Double
  safe : Bool
} derive(Debug, Eq)

///|
pub struct PerigeeApogee {
  perigee_km : Double
  apogee_km : Double
  perigee_altitude_km : Double
  apogee_altitude_km : Double
} derive(Debug, Eq)

///|
pub fn perigee_apogee(elements : ClassicalElements) -> PerigeeApogee {
  let peri = elements.semi_major_axis_km * (1.0 - elements.eccentricity)
  let apo = elements.semi_major_axis_km * (1.0 + elements.eccentricity)
  {
    perigee_km: peri,
    apogee_km: apo,
    perigee_altitude_km: peri - earth_radius_km,
    apogee_altitude_km: apo - earth_radius_km,
  }
}

///|
pub fn orbit_intersects_body(
  elements : ClassicalElements,
  body_radius_km : Double,
) -> Bool {
  elements.semi_major_axis_km * (1.0 - elements.eccentricity) <= body_radius_km
}

///|
pub fn relative_state(a : StateVector, b : StateVector) -> StateVector {
  StateVector::new(
    a.position_km.sub(b.position_km),
    a.velocity_km_s.sub(b.velocity_km_s),
  )
}

///|
pub fn closest_approach(a : StateVector, b : StateVector) -> SafetyAssessment {
  let relative = relative_state(a, b)
  let speed2 = relative.velocity_km_s.norm_squared()
  let time = if speed2 == 0.0 {
    0.0
  } else {
    -relative.position_km.dot(relative.velocity_km_s) / speed2
  }
  let closest = relative.position_km.add(
    relative.velocity_km_s.scale(time.max(0.0)),
  )
  let distance = closest.norm()
  let closing = if relative.position_km.norm() == 0.0 {
    0.0
  } else {
    -relative.position_km.dot(relative.velocity_km_s) /
    relative.position_km.norm()
  }
  {
    minimum_distance_km: distance,
    relative_speed_km_s: relative.velocity_km_s.norm(),
    closing_speed_km_s: closing.max(0.0),
    time_to_closest_s: time.max(0.0),
    collision_probability_proxy: @math.exp(-distance / 10.0),
    safe: distance > 10.0,
  }
}

///|
pub fn safety_margin_km(
  assessment : SafetyAssessment,
  required_distance_km : Double,
) -> Double {
  assessment.minimum_distance_km - required_distance_km
}

///|
pub fn is_collision_risk(
  assessment : SafetyAssessment,
  threshold_km : Double,
) -> Bool {
  assessment.minimum_distance_km <= threshold_km
}

///|
pub fn atmospheric_reentry_altitude_km() -> Double {
  120.0
}

///|
pub fn is_reentry_risk(elements : ClassicalElements) -> Bool {
  perigee_apogee(elements).perigee_altitude_km <
  atmospheric_reentry_altitude_km()
}

///|
pub fn solar_escape_margin(
  mu : Double,
  radius_km : Double,
  speed_km_s : Double,
) -> Double {
  escape_velocity(mu, radius_km) - speed_km_s
}

///|
pub fn orbit_eccentricity_limit(elements : ClassicalElements) -> Double {
  (1.0 - elements.eccentricity).max(0.0)
}

///|
pub fn assess_orbit(elements : ClassicalElements) -> Array[String] {
  let issues : Array[String] = []
  if is_reentry_risk(elements) {
    issues.push("reentry")
  }
  if elements.eccentricity >= 1.0 {
    issues.push("escape")
  }
  if elements.semi_major_axis_km <= 0.0 {
    issues.push("invalid-axis")
  }
  issues
}

///|
pub fn conjunction_screen(
  reference : StateVector,
  objects : Array[StateVector],
  threshold_km : Double,
) -> Array[SafetyAssessment] {
  objects
  .map(object => closest_approach(reference, object))
  .filter(item => item.minimum_distance_km <= threshold_km)
}

///|
pub fn relative_motion_distance(
  a : StateVector,
  b : StateVector,
  delta_t_s : Double,
) -> Double {
  let relative = relative_state(a, b)
  relative.position_km.add(relative.velocity_km_s.scale(delta_t_s)).norm()
}

///|
pub fn collision_probability_proxy(
  distance_km : Double,
  covariance_radius_km : Double,
) -> Double {
  if covariance_radius_km <= 0.0 {
    if distance_km <= 0.0 {
      1.0
    } else {
      0.0
    }
  } else {
    @math.exp(
      -0.5 *
      distance_km *
      distance_km /
      (covariance_radius_km * covariance_radius_km),
    )
  }
}
