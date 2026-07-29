///|
fn assert_close(actual : Double, expected : Double, eps : Double) -> Unit raise {
  if (actual - expected).abs() > eps {
    fail("expected \{expected}, got \{actual}")
  }
}

///|
test "vector algebra keeps basic invariants" {
  let x = Vec3::new(1.0, 0.0, 0.0)
  let y = Vec3::new(0.0, 1.0, 0.0)
  let z = x.cross(y)
  assert_close(z.z, 1.0, 1.0e-12)
  assert_close(x.angle_between(y), half_pi, 1.0e-12)
  assert_close(Vec3::new(3.0, 4.0, 0.0).norm(), 5.0, 1.0e-12)
}

///|
test "kepler solver residual is small" {
  let mean = radians(42.0)
  let ecc = 0.12
  let e = solve_kepler(mean, ecc)
  let residual = e - ecc * @math.sin(e) - mean
  assert_close(residual, 0.0, 1.0e-9)
}

///|
test "circular low earth orbit summary is plausible" {
  let orbit = circular_orbit(earth_radius_km + 500.0, radians(51.6))
  let summary = summarize_orbit(earth_mu_km3_s2, orbit)
  assert_close(summary.radius_periapsis_km, earth_radius_km + 500.0, 1.0e-9)
  assert_true(summary.period_s > 5600.0 && summary.period_s < 5700.0)
}

///|
test "element to state preserves circular radius and speed" {
  let elements = ClassicalElements::new(
    7000.0,
    0.0,
    radians(28.5),
    radians(40.0),
    0.0,
    radians(90.0),
  )
  let state = elements_to_state(earth_mu_km3_s2, elements)
  assert_close(state.position_km.norm(), 7000.0, 1.0e-8)
  assert_close(
    state.velocity_km_s.norm(),
    circular_speed(earth_mu_km3_s2, 7000.0),
    1.0e-10,
  )
}

///|
test "hohmann transfer from leo to geo sized orbit" {
  let transfer = hohmann_transfer(
    earth_mu_km3_s2,
    earth_radius_km + 300.0,
    42164.0,
  )
  assert_true(
    transfer.delta_v_total_km_s > 3.8 && transfer.delta_v_total_km_s < 4.0,
  )
  assert_true(transfer.time_of_flight_s > 18000.0)
}

///|
test "attitude quaternion rotates z axis around x" {
  let q = Quaternion::from_axis_angle(Vec3::new(1.0, 0.0, 0.0), half_pi)
  let rotated = q.rotate(Vec3::new(0.0, 1.0, 0.0))
  assert_close(rotated.z, 1.0, 1.0e-12)
}

///|
test "ground station sees overhead satellite" {
  let station = GroundStation::new("equator", 0.0, 0.0, min_elevation_rad=0.0)
  let site = geodetic_to_ecef(station.location)
  let sat = site.unit().scale(earth_radius_km + 500.0)
  let sample = sample_visibility(
    station,
    Epoch::j2000(),
    ecef_to_eci(Epoch::j2000(), sat),
  )
  assert_true(sample.visible)
  assert_close(sample.look.elevation_rad, half_pi, 1.0e-8)
}

///|
test "tle parser extracts mean elements" {
  let line1 = "1 25544U 98067A   24001.50000000  .00016717  00000+0  10270-3 0  9000"
  let line2 = "2 25544  51.6416 247.4627 0006703 130.5360 325.0288 15.50000000  9000"
  match parse_tle("ISS", line1, line2) {
    Ok(tle) => {
      let elements = tle_to_mean_elements(earth_mu_km3_s2, tle)
      assert_true(
        elements.semi_major_axis_km > 6700.0 &&
        elements.semi_major_axis_km < 6900.0,
      )
      assert_close(tle.eccentricity, 0.0006703, 1.0e-10)
    }
    Err(e) => fail("unexpected TLE error: \{to_repr(e)}")
  }
}

///|
test "j2 rates are finite for sun synchronous class orbit" {
  let elements = ClassicalElements::new(
    earth_radius_km + 700.0,
    0.001,
    radians(98.0),
    0.0,
    0.0,
    0.0,
  )
  let rates = j2_secular_rates(earth_mu_km3_s2, earth_radius_km, j2, elements)
  assert_true(!rates.raan_rate_rad_s.is_nan())
  assert_true(rates.mean_anomaly_rate_rad_s > 0.0)
}
