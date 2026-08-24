///|
fn observation_assert_near(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Unit raise {
  if (actual - expected).abs() > tolerance {
    fail("observation value outside tolerance")
  }
}

///|
test "observation model predicts range and angles" {
  let station = GroundStation::new("test", 0.0, 0.0)
  let state = StateVector::new(
    Vec3::new(earth_radius_km + 500.0, 0.0, 0.0),
    Vec3::new(0.0, 7.6, 0.0),
  )
  let range = observe_state(
    station,
    Epoch::j2000(),
    state,
    all_observation_kinds()[0],
    bias=0.0,
    sigma=0.1,
  )
  let elevation = observe_state(
    station,
    Epoch::j2000(),
    state,
    all_observation_kinds()[3],
    bias=0.0,
    sigma=0.01,
  )
  assert_true(range.quality is ObservationQuality::Good)
  assert_true(range.value > 400.0)
  assert_true(elevation.value.is_nan() == false)
  observation_assert_near(range.predicted, range.value, 1.0e-12)
}

///|
test "observation batches sort and filter invalid data" {
  let station = GroundStation::new("test", 0.0, 0.0)
  let a = Observation::new(
    Epoch::from_seconds(20.0),
    station,
    all_observation_kinds()[0],
    10.0,
    1.0,
  )
  let b = Observation::new(
    Epoch::from_seconds(5.0),
    station,
    all_observation_kinds()[0],
    12.0,
    1.0,
  )
  let invalid = a.with_quality(invalid_observation_quality())
  let batch = ObservationBatch::new("test")
    .add(a)
    .add(b)
    .add(invalid)
    .sort_by_epoch()
  assert_true(batch.observations[0].epoch.seconds_since_j2000 == 5.0)
  assert_true(batch.valid_count() == 2)
  assert_true(batch.by_kind(all_observation_kinds()[0]).length() == 3)
  assert_true(batch.span_s() == 15.0)
}

///|
test "weighted residual estimate handles gates and empty input" {
  let station = GroundStation::new("test", 0.0, 0.0)
  let first = Observation::new(
    Epoch::from_seconds(0.0),
    station,
    all_observation_kinds()[0],
    100.0,
    2.0,
  )
  let second = Observation::new(
    Epoch::from_seconds(1.0),
    station,
    all_observation_kinds()[0],
    104.0,
    1.0,
  )
  let estimate = weighted_scalar_estimate([first, second])
  assert_true(estimate.status is EstimateStatus::Converged)
  assert_true(estimate.value > 102.0 && estimate.value < 104.0)
  assert_true(estimate.used == 2)
  assert_true(innovation_is_acceptable(estimate, 10.0))
  let empty = weighted_scalar_estimate([])
  assert_true(empty.status is EstimateStatus::InsufficientData)
}

///|
test "visibility planner rejects short and distant windows" {
  let good = make_visibility_window(
    Epoch::from_seconds(0.0),
    Epoch::from_seconds(120.0),
    radians(45.0),
    1000.0,
  )
  let short = make_visibility_window(
    Epoch::from_seconds(0.0),
    Epoch::from_seconds(5.0),
    radians(60.0),
    1000.0,
  )
  let constraint = WindowConstraint::new(radians(10.0), 3000.0, 30.0)
  assert_true(window_is_acceptable(good, constraint))
  assert_true(!window_is_acceptable(short, constraint))
  let schedule = plan_windows([good, short], constraint, 512.0)
  assert_true(schedule.windows.length() == 1)
  assert_true(schedule.total_duration_s == 120.0)
  assert_true(schedule.total_volume_mb > 0.0)
}

///|
test "scenario summary validates phases and resource limits" {
  let scenario = MissionScenario::new("demo")
    .add_phase(mission_phase("commissioning", 0.0, 600.0, 0.1))
    .add_phase(mission_phase("operations", 600.0, 3600.0, 0.4))
  let summary = summarize_scenario(scenario, 1.0)
  assert_true(summary.valid)
  assert_true(summary.phase_count == 2)
  assert_true(summary.total_delta_v_km_s == 0.5)
  let invalid = MissionScenario::new("invalid")
    .add_phase(mission_phase("overlap", 0.0, 100.0, 0.1))
    .add_phase(mission_phase("overlap", 50.0, 200.0, 0.1))
  assert_true(!summarize_scenario(invalid, 1.0).valid)
}
