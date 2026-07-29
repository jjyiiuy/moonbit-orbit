///|
pub struct J2Rates {
  raan_rate_rad_s : Double
  arg_periapsis_rate_rad_s : Double
  mean_anomaly_rate_rad_s : Double
} derive(Debug, Eq)

///|
pub fn semi_latus_rectum(elements : ClassicalElements) -> Double {
  elements.semi_major_axis_km *
  (1.0 - elements.eccentricity * elements.eccentricity)
}

///|
pub fn j2_secular_rates(
  mu : Double,
  radius_body_km : Double,
  j2_value : Double,
  elements : ClassicalElements,
) -> J2Rates {
  let p = semi_latus_rectum(elements)
  let n = mean_motion(mu, elements.semi_major_axis_km)
  let factor = 1.5 * j2_value * n * (radius_body_km / p) * (radius_body_km / p)
  let cos_i = @math.cos(elements.inclination_rad)
  {
    raan_rate_rad_s: -factor * cos_i,
    arg_periapsis_rate_rad_s: 0.5 * factor * (5.0 * cos_i * cos_i - 1.0),
    mean_anomaly_rate_rad_s: n +
    0.5 *
    factor *
    (3.0 * cos_i * cos_i - 1.0) *
    (1.0 - elements.eccentricity * elements.eccentricity).sqrt(),
  }
}

///|
pub fn propagate_j2_mean_elements(
  mu : Double,
  radius_body_km : Double,
  j2_value : Double,
  elements : ClassicalElements,
  delta_t_s : Double,
) -> ClassicalElements {
  let rates = j2_secular_rates(mu, radius_body_km, j2_value, elements)
  {
    ..propagate_kepler(mu, elements, delta_t_s),
    raan_rad: normalize_angle(
      elements.raan_rad + rates.raan_rate_rad_s * delta_t_s,
    ),
    arg_periapsis_rad: normalize_angle(
      elements.arg_periapsis_rad + rates.arg_periapsis_rate_rad_s * delta_t_s,
    ),
  }
}

///|
pub fn sun_synchronous_inclination(
  mu : Double,
  radius_body_km : Double,
  j2_value : Double,
  semi_major_axis_km : Double,
  eccentricity : Double,
  desired_raan_rate_rad_s : Double,
) -> Double {
  let p = semi_major_axis_km * (1.0 - eccentricity * eccentricity)
  let n = mean_motion(mu, semi_major_axis_km)
  let denom = -1.5 * j2_value * n * (radius_body_km / p) * (radius_body_km / p)
  @math.acos(clamp(desired_raan_rate_rad_s / denom, -1.0, 1.0))
}
