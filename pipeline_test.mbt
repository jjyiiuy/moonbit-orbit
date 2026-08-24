///|
test "ground track pipeline computes coverage and distance" {
  let elements = circular_orbit(7000.0, radians(51.6))
  let track = ground_track(
    earth_mu_km3_s2,
    elements,
    Epoch::j2000(),
    600.0,
    60.0,
  )
  let summary = ground_track_summary(track)
  assert_true(summary.points == 11)
  assert_true(summary.maximum_altitude_km > 500.0)
  assert_true(summary.path_length_km > 0.0)
  assert_true(track_is_contiguous(track, 120.0))
  assert_true(track_to_csv(track).length() > 30)
}

///|
test "ground track segmentation and resampling preserve endpoints" {
  let elements = circular_orbit(7000.0, radians(28.5))
  let track = ground_track(
    earth_mu_km3_s2,
    elements,
    Epoch::j2000(),
    300.0,
    60.0,
  )
  let segments = segment_ground_track(track, 120.0)
  assert_true(segments.length() == 1)
  let resampled = resample_ground_track(track, [0.0, 150.0, 300.0])
  assert_true(resampled.length() == 3)
  assert_true(resampled[0].time_s == 0.0)
  assert_true(resampled[2].time_s == 300.0)
}

///|
test "state comparison reports zero error for identical samples" {
  let elements = circular_orbit(7000.0, 0.0)
  let samples = propagate_state_samples(earth_mu_km3_s2, elements, [
    0.0, 60.0, 120.0,
  ])
  let comparison = compare_state_samples(samples, samples)
  assert_true(comparison.count == 3)
  assert_true(comparison.position_rms_km == 0.0)
  assert_true(comparison.velocity_rms_km_s == 0.0)
  assert_true(state_comparison_is_valid(comparison, 0.001, 0.001))
}
