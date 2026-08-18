///|
test "mission service metrics are internally consistent" {
  let elements = circular_orbit(earth_radius_km + 600.0, radians(45.0))
  let state = elements_to_state(earth_mu_km3_s2, elements)
  let history = integrate_dynamics(
    AccelerationModel::vacuum(earth_mu_km3_s2),
    state,
    120.0,
    30.0,
  )
  let metrics = trajectory_metrics(history)
  assert_true(metrics.samples == 5)
  assert_true(
    metrics.max_altitude_km > 500.0 && metrics.min_altitude_km < 700.0,
  )
  let resource = resource_profile(100.0, 0.6, 200.0, 64.0, 365.0)
  assert_near(resource_data_volume_mb(resource), 252288.0, 1.0)
}

///|
test "communications model handles zero distance safely" {
  let budget = link_budget(2.2, 0.0, 10.0, 5.0, 2.0, 3.0)
  assert_true(budget.margin_db == 10.0)
  assert_true(round_trip_delay_s(0.0) == 0.0)
  assert_true(packet_error_rate(-10.0, 0.0) == 1.0)
}

///|
test "control commands obey rate limits" {
  let target = make_pointing_target(Vec3::new(0.0, 1.0, 0.0), 0.0, 0.01)
  let command = control_command(
    Quaternion::identity(),
    target,
    Vec3::new(1.0, 0.0, 0.0),
    0.5,
  )
  assert_true(command.angle_rad > 1.0)
  assert_true(command.duration_s > 0.0)
  assert_true(slew_time(0.0, 1.0, 1.0) == 0.0)
}

///|
test "validation reports errors rather than crashing" {
  let invalid = ClassicalElements::new(-1.0, 1.2, 0.0, 0.0, 0.0, 0.0)
  let report = validate_elements(invalid)
  assert_true(!report.valid)
  assert_true(validation_error_count(report) >= 1)
  let empty = validate_telemetry([])
  assert_true(empty.valid)
  assert_true(validation_warning_count(empty) == 1)
}

///|
test "report rendering includes measured metrics" {
  let elements = circular_orbit(7000.0, 0.0)
  let report = orbit_report(earth_mu_km3_s2, elements)
  assert_true(report.metric("period_s") is Some(_))
  assert_true(report.render().length() > 20)
}

///|
test "ephemeris outputs finite directions" {
  let epoch = Epoch::j2000()
  let sun = sun_position(epoch)
  let moon = moon_position(epoch)
  assert_true(sun.position_eci_km.norm() > 1.0e8)
  assert_true(moon.distance_km > 300000.0)
  assert_true(!solar_declination(epoch).is_nan())
}

///|
test "safety assessment recognizes close conjunction" {
  let a = StateVector::new(
    Vec3::new(7000.0, 0.0, 0.0),
    Vec3::new(0.0, 7.5, 0.0),
  )
  let b = StateVector::new(
    Vec3::new(7001.0, 0.0, 0.0),
    Vec3::new(0.0, 7.5, 0.0),
  )
  let assessment = closest_approach(a, b)
  assert_true(is_collision_risk(assessment, 10.0))
  assert_true(collision_probability_proxy(0.0, 1.0) == 1.0)
}

///|
test "optimization and statistics return deterministic values" {
  let optimum = grid_search_1d(x => (x - 2.0) * (x - 2.0), 0.0, 4.0, 101)
  assert_near(optimum.0, 2.0, 0.05)
  assert_near(percentile([1.0, 2.0, 3.0, 4.0, 5.0], 0.5), 3.0, 1.0e-12)
  assert_true(correlation([1.0, 2.0, 3.0], [2.0, 4.0, 6.0]) > 0.99)
}

///|
test "operation plans track completion and resource use" {
  let plan = OperationPlan::new("demo")
    .append(nominal_step(0, "boot", 10.0, 1.0))
    .append(contingency_step(1, "safe", 20.0, 2.0))
  assert_true(plan.remaining_steps().length() == 2)
  let completed = plan.complete_step(0)
  assert_near(completed.completion_fraction(), 0.5, 1.0e-12)
  assert_true(completed.resource_remaining(10.0) == 7.0)
}

///|
test "coverage grid and interpolation cover boundary inputs" {
  assert_true(coverage_grid(0.0, 0.1).length() == 0)
  assert_true(coverage_cells_for_track([], 0.1, 0.1) == 0)
  let a = StateVector::new(Vec3::zero(), Vec3::zero())
  let b = StateVector::new(Vec3::new(2.0, 0.0, 0.0), Vec3::new(0.0, 2.0, 0.0))
  assert_near(interpolate_state(a, b, 0.5).position_km.x, 1.0, 1.0e-12)
}

///|
test "benchmark report has fixed workloads" {
  let results = benchmark_report(32)
  assert_true(results.length() == 3)
  for result in results {
    assert_true(result.iterations == 32)
  }
  assert_true(benchmark_report_text(results).length() > 30)
}
