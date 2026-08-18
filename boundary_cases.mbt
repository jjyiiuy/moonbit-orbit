///|
fn assert_near(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Unit raise {
  if (actual - expected).abs() > tolerance {
    fail("boundary value outside tolerance")
  }
}

///|
test "boundary angle normalization cases" {
  for value in [-10000.0, -two_pi, -pi, -0.0, 0.0, pi, two_pi, 10000.0] {
    assert_true(
      normalize_angle(value) >= 0.0 && normalize_angle(value) < two_pi,
    )
  }
}

///|
test "boundary clamp cases" {
  for value in [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0] {
    assert_true(clamp_unit(value) >= -1.0 && clamp_unit(value) <= 1.0)
  }
}

///|
test "boundary vector scales" {
  for value in [-1000.0, -1.0, 0.0, 1.0, 1000.0] {
    assert_near(Vec3::new(value, 0.0, 0.0).norm(), value.abs(), 1.0e-10)
  }
}

///|
test "boundary zero durations" {
  assert_true(
    integrate_dynamics(
      AccelerationModel::earth(),
      StateVector::new(Vec3::zero(), Vec3::zero()),
      -1.0,
      1.0,
    ).length() ==
    0,
  )
  assert_true(
    integrate_dynamics(
      AccelerationModel::earth(),
      StateVector::new(Vec3::zero(), Vec3::zero()),
      1.0,
      0.0,
    ).length() ==
    0,
  )
}

///|
test "boundary empty collections" {
  assert_true(catalog_names([]).length() == 0)
  assert_true(schedule_sort([]).length() == 0)
  assert_true(telemetry_channel_names([]).length() == 0)
  assert_true(coverage_grid(1.0, 1.0).length() > 0)
}

///|
test "boundary conversion inverses" {
  for value in [-100.0, -1.0, 0.0, 1.0, 100.0] {
    assert_near(
      meters_to_kilometers(kilometers_to_meters(value)),
      value,
      1.0e-10,
    )
    assert_near(degrees_to_radians(radians_to_degrees(value)), value, 1.0e-10)
  }
}

///|
test "boundary health limits" {
  let flags = [
    health_flag("a", 0.0, 0.0, 1.0),
    health_flag("b", 1.0, 0.0, 1.0),
    health_flag("c", 2.0, 0.0, 1.0),
  ]
  assert_true(healthy_fraction(flags) > 0.5 && healthy_fraction(flags) < 1.0)
  assert_true(!health_is_nominal(flags))
}

///|
test "boundary unit conversions" {
  assert_near(celsius_to_kelvin(kelvin_to_celsius(300.0)), 300.0, 1.0e-10)
  assert_near(meters_to_millimeters(millimeters_to_meters(12.0)), 12.0, 1.0e-10)
  assert_near(kilograms_to_pounds(pounds_to_kilograms(12.0)), 12.0, 1.0e-10)
}

///|
test "boundary interpolation" {
  assert_true(nearest_index([], 1.0) == -1)
  assert_true(
    nearest_value([1.0, 3.0, 5.0], 4.0) == 3.0 ||
    nearest_value([1.0, 3.0, 5.0], 4.0) == 5.0,
  )
  assert_near(interpolate_array([0.0, 1.0], [0.0, 10.0], 0.5), 5.0, 1.0e-10)
}

///|
test "boundary geometry" {
  assert_near(
    triangle_area(
      Vec3::zero(),
      Vec3::new(1.0, 0.0, 0.0),
      Vec3::new(0.0, 1.0, 0.0),
    ),
    0.5,
    1.0e-10,
  )
  assert_near(
    tetrahedron_volume(
      Vec3::zero(),
      Vec3::new(1.0, 0.0, 0.0),
      Vec3::new(0.0, 1.0, 0.0),
      Vec3::new(0.0, 0.0, 1.0),
    ),
    1.0 / 6.0,
    1.0e-10,
  )
}

///|
test "boundary safety" {
  let state = StateVector::new(Vec3::zero(), Vec3::zero())
  assert_true(closest_approach(state, state).minimum_distance_km == 0.0)
  assert_true(collision_probability_proxy(0.0, 0.0) == 1.0)
  assert_true(solar_escape_margin(earth_mu_km3_s2, 0.0, 0.0) == 0.0)
}

///|
test "boundary statistics" {
  assert_true(percentile([], 0.5) == 0.0)
  assert_true(histogram([], 0.0, 1.0, 4).counts.length() == 4)
  assert_true(outliers([1.0, 1.0, 1.0], 3.0).length() == 0)
}

///|
test "boundary communications" {
  assert_true(free_space_path_loss_db(0.0, 1.0) == 0.0)
  assert_true(contact_data_volume_mb(-1.0, 2.0) == 0.0)
  assert_true(link_availability([], 0.0) == 0.0)
}

///|
test "boundary operations" {
  let plan = OperationPlan::new("empty")
  assert_true(plan.is_ready())
  assert_true(plan.completion_fraction() == 0.0)
  assert_true(simulate_plan(plan, 1.0).remaining_steps().length() == 0)
}

///|
test "boundary planner" {
  let result = evaluate_design(
    earth_mu_km3_s2,
    circular_orbit(7000.0, 0.0),
    DesignConstraint::leo(),
  )
  assert_true(result.violations.length() == 0)
  assert_true(feasible_designs([result]).length() == 1)
}

///|
test "boundary reports" {
  assert_true(report_is_valid(OrbitReport::new("x")))
  assert_true(
    orbit_report(earth_mu_km3_s2, circular_orbit(7000.0, 0.0)).metric("missing")
    is None,
  )
  assert_true(benchmark_report_text([]).length() > 0)
}

///|
test "boundary numerical methods" {
  assert_true(find_bracket(x => x, 1.0, 2.0) is None)
  assert_near(quantize(1.24, 0.1), 1.2, 1.0e-10)
  assert_true(is_close(1.0, 1.0 + 1.0e-12))
}

///|
test "boundary mission events" {
  let kinds = all_mission_event_kinds()
  assert_true(kinds.length() == 7)
  assert_true(mission_event_kind_name(kinds[0]).length() > 0)
  assert_true(schedule_time_span([]) == 0.0)
}

///|
test "boundary pass windows" {
  let station = GroundStation::new("x", 0.0, 0.0)
  let windows = estimate_orbit_pass(
    station,
    circular_orbit(7000.0, 0.0),
    Epoch::j2000(),
    -1.0,
    1.0,
    0.0,
  )
  assert_true(windows.length() == 0)
}

///|
test "boundary ephemeris" {
  let site = Geodetic::new(half_pi, 0.0, 0.0)
  assert_true(sun_altitude(site, Epoch::j2000()).is_nan() == false)
  assert_true(moon_altitude(site, Epoch::j2000()).is_nan() == false)
}
