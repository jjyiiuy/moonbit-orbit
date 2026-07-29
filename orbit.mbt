///|
pub struct StateVector {
  position_km : Vec3
  velocity_km_s : Vec3
} derive(Debug, Eq)

///|
pub struct ClassicalElements {
  semi_major_axis_km : Double
  eccentricity : Double
  inclination_rad : Double
  raan_rad : Double
  arg_periapsis_rad : Double
  true_anomaly_rad : Double
} derive(Debug, Eq)

///|
pub struct OrbitSummary {
  radius_periapsis_km : Double
  radius_apoapsis_km : Double
  period_s : Double
  mean_motion_rad_s : Double
  specific_energy_km2_s2 : Double
} derive(Debug, Eq)

///|
pub fn StateVector::new(position_km : Vec3, velocity_km_s : Vec3) -> StateVector {
  { position_km, velocity_km_s }
}

///|
pub fn ClassicalElements::new(
  semi_major_axis_km : Double,
  eccentricity : Double,
  inclination_rad : Double,
  raan_rad : Double,
  arg_periapsis_rad : Double,
  true_anomaly_rad : Double
) -> ClassicalElements {
  {
    semi_major_axis_km,
    eccentricity,
    inclination_rad,
    raan_rad: normalize_angle(raan_rad),
    arg_periapsis_rad: normalize_angle(arg_periapsis_rad),
    true_anomaly_rad: normalize_angle(true_anomaly_rad),
  }
}

///|
pub fn circular_orbit(radius_km : Double, inclination_rad : Double) -> ClassicalElements {
  ClassicalElements::new(radius_km, 0.0, inclination_rad, 0.0, 0.0, 0.0)
}

///|
pub fn mean_motion(mu : Double, semi_major_axis_km : Double) -> Double {
  (mu / (semi_major_axis_km * semi_major_axis_km * semi_major_axis_km)).sqrt()
}

///|
pub fn orbital_period(mu : Double, semi_major_axis_km : Double) -> Double {
  two_pi / mean_motion(mu, semi_major_axis_km)
}

///|
pub fn specific_orbital_energy(mu : Double, semi_major_axis_km : Double) -> Double {
  -mu / (2.0 * semi_major_axis_km)
}

///|
pub fn summarize_orbit(mu : Double, elements : ClassicalElements) -> OrbitSummary {
  {
    radius_periapsis_km: elements.semi_major_axis_km * (1.0 - elements.eccentricity),
    radius_apoapsis_km: elements.semi_major_axis_km * (1.0 + elements.eccentricity),
    period_s: orbital_period(mu, elements.semi_major_axis_km),
    mean_motion_rad_s: mean_motion(mu, elements.semi_major_axis_km),
    specific_energy_km2_s2: specific_orbital_energy(mu, elements.semi_major_axis_km),
  }
}

///|
pub fn eccentric_anomaly_from_true(true_anomaly_rad : Double, eccentricity : Double) -> Double {
  let e = eccentricity
  if e == 0.0 {
    normalize_angle(true_anomaly_rad)
  } else {
    let factor = ((1.0 - e) / (1.0 + e)).sqrt()
    normalize_angle(2.0 * @math.atan(factor * @math.tan(true_anomaly_rad / 2.0)))
  }
}

///|
pub fn true_anomaly_from_eccentric(eccentric_anomaly_rad : Double, eccentricity : Double) -> Double {
  let e = eccentricity
  if e == 0.0 {
    normalize_angle(eccentric_anomaly_rad)
  } else {
    let factor = ((1.0 + e) / (1.0 - e)).sqrt()
    normalize_angle(2.0 * @math.atan(factor * @math.tan(eccentric_anomaly_rad / 2.0)))
  }
}

///|
pub fn mean_anomaly_from_eccentric(eccentric_anomaly_rad : Double, eccentricity : Double) -> Double {
  normalize_angle(eccentric_anomaly_rad - eccentricity * @math.sin(eccentric_anomaly_rad))
}

///|
pub fn solve_kepler(
  mean_anomaly_rad : Double,
  eccentricity : Double,
  tolerance? : Double = 1.0e-10,
  max_iterations? : Int = 32
) -> Double {
  let m = normalize_angle(mean_anomaly_rad)
  let start = if eccentricity < 0.8 { m } else { pi }
  for estimate = start, i = 0; i < max_iterations; {
    let f = estimate - eccentricity * @math.sin(estimate) - m
    let fp = 1.0 - eccentricity * @math.cos(estimate)
    let next = estimate - f / fp
    if (next - estimate).abs() <= tolerance {
      break next
    } else {
      continue next, i + 1
    }
  } nobreak {
    estimate
  }
}

///|
pub fn elements_to_state(mu : Double, elements : ClassicalElements) -> StateVector {
  let a = elements.semi_major_axis_km
  let e = elements.eccentricity
  let i = elements.inclination_rad
  let raan = elements.raan_rad
  let w = elements.arg_periapsis_rad
  let nu = elements.true_anomaly_rad
  let p = a * (1.0 - e * e)
  let r = p / (1.0 + e * @math.cos(nu))
  let perifocal_r = Vec3::new(r * @math.cos(nu), r * @math.sin(nu), 0.0)
  let v_scale = (mu / p).sqrt()
  let perifocal_v = Vec3::new(-v_scale * @math.sin(nu), v_scale * (e + @math.cos(nu)), 0.0)
  let cos_o = @math.cos(raan)
  let sin_o = @math.sin(raan)
  let cos_i = @math.cos(i)
  let sin_i = @math.sin(i)
  let cos_w = @math.cos(w)
  let sin_w = @math.sin(w)
  let m11 = cos_o * cos_w - sin_o * sin_w * cos_i
  let m12 = -cos_o * sin_w - sin_o * cos_w * cos_i
  let m21 = sin_o * cos_w + cos_o * sin_w * cos_i
  let m22 = -sin_o * sin_w + cos_o * cos_w * cos_i
  let m31 = sin_w * sin_i
  let m32 = cos_w * sin_i
  {
    position_km: Vec3::new(
      m11 * perifocal_r.x + m12 * perifocal_r.y,
      m21 * perifocal_r.x + m22 * perifocal_r.y,
      m31 * perifocal_r.x + m32 * perifocal_r.y,
    ),
    velocity_km_s: Vec3::new(
      m11 * perifocal_v.x + m12 * perifocal_v.y,
      m21 * perifocal_v.x + m22 * perifocal_v.y,
      m31 * perifocal_v.x + m32 * perifocal_v.y,
    ),
  }
}

///|
pub fn propagate_kepler(mu : Double, elements : ClassicalElements, delta_t_s : Double) -> ClassicalElements {
  let e0 = eccentric_anomaly_from_true(elements.true_anomaly_rad, elements.eccentricity)
  let m0 = mean_anomaly_from_eccentric(e0, elements.eccentricity)
  let m = m0 + mean_motion(mu, elements.semi_major_axis_km) * delta_t_s
  let e_anom = solve_kepler(m, elements.eccentricity)
  {
    ..elements,
    true_anomaly_rad: true_anomaly_from_eccentric(e_anom, elements.eccentricity),
  }
}
