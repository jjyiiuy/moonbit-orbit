///|
fn assert_near(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Unit raise {
  if (actual - expected).abs() > tolerance {
    fail("expected \{expected}, got \{actual}")
  }
}

///|
test "wgs84 conversion round trip at mid latitude" {
  let original = Geodetic::new(radians(35.2), radians(139.7), 0.45)
  let recovered = ecef_to_geodetic_wgs84(geodetic_to_ecef_wgs84(original))
  assert_near(recovered.latitude_rad, original.latitude_rad, 1.0e-10)
  assert_near(recovered.longitude_rad, original.longitude_rad, 1.0e-10)
  assert_near(recovered.altitude_km, original.altitude_km, 1.0e-8)
}

///|
test "wgs84 pole and antimeridian boundaries" {
  let north = ecef_to_geodetic_wgs84(Vec3::new(0.0, 0.0, Wgs84B + 1.0))
  assert_near(north.latitude_rad, half_pi, 1.0e-12)
  let west = Geodetic::new(0.0, radians(179.9), 0.0)
  let east = Geodetic::new(0.0, radians(-179.9), 0.0)
  assert_true(geodesic_surface_distance_km(west, east) < 30.0)
  assert_true(initial_bearing_rad(west, east) >= 0.0)
}

///|
test "destination point is reversible on a sphere" {
  let start = Geodetic::new(radians(10.0), radians(20.0), 0.0)
  let destination = destination_point(start, radians(90.0), 100.0)
  assert_true(destination.longitude_rad > start.longitude_rad)
  assert_true(geodesic_surface_distance_km(start, destination) > 99.0)
}

///|
test "numerical roots cover valid and invalid brackets" {
  let root = bisect(x => x * x - 2.0, 0.0, 2.0)
  assert_true(root.status is Converged)
  assert_near(root.value, 2.0.sqrt(), 1.0e-8)
  let invalid = bisect(x => x * x + 1.0, -1.0, 1.0)
  assert_true(invalid.status is InvalidInput)
  let newton_root = newton(x => x * x - 2.0, x => 2.0 * x, 1.0)
  assert_near(newton_root.value, 2.0.sqrt(), 1.0e-8)
}

///|
test "sample statistics and integration handle empty input" {
  let empty = summarize_samples([])
  assert_true(empty.count == 0 && empty.mean == 0.0)
  let stats = summarize_samples([1.0, 2.0, 3.0, 4.0])
  assert_near(stats.mean, 2.5, 1.0e-12)
  assert_near(
    integrate_trapezoid([0.0, 1.0, 2.0], [0.0, 1.0, 4.0]),
    3.0,
    1.0e-12,
  )
}

///|
test "eclipse geometry distinguishes no eclipse and umbra" {
  let none = eclipse_geometry(
    Vec3::new(1.0e8, 0.0, 0.0),
    Vec3::new(0.0, 1.0e7, 0.0),
    earth_radius_km,
    SunRadiusKm,
  )
  assert_true(none.kind is None)
  let total = cylindrical_eclipse(
    Vec3::new(-earth_radius_km / 2.0, 0.0, 0.0),
    Vec3::new(1.0, 0.0, 0.0),
    earth_radius_km,
  )
  assert_true(eclipse_is_total(total))
  assert_near(sunlight_power_fraction(total), 0.0, 1.0e-12)
}

///|
test "lambert rejects degenerate input and returns finite transfer" {
  let invalid = lambert_universal(
    earth_mu_km3_s2,
    Vec3::zero(),
    Vec3::new(7000.0, 0.0, 0.0),
    1000.0,
  )
  assert_true(invalid.status is InvalidInput)
  let result = lambert_universal(
    earth_mu_km3_s2,
    Vec3::new(7000.0, 0.0, 0.0),
    Vec3::new(0.0, 8000.0, 0.0),
    3600.0,
  )
  assert_true(result.departure_velocity_km_s.norm() >= 0.0)
  assert_true(result.iterations > 0)
}

///|
test "mission timeline sorts and budgets events" {
  let timeline = MissionTimeline::new()
    .add(maneuver_event(50.0, "late", 0.2))
    .add(contact_event(10.0, "early", 20.0))
    .sort_by_time()
  assert_true(timeline.events[0].time_s == 10.0)
  assert_near(timeline.total_delta_v(), 0.2, 1.0e-12)
  let budget = make_delta_v_budget(1.0, reserve_fraction=0.25)
  assert_near(budget_remaining(budget, 1.0), 0.25, 1.0e-12)
  assert_true(!budget_is_exceeded(budget, 1.1))
}

///|
test "telemetry validation, resampling and health" {
  let raw = [
    TelemetrySample::new(0.0, "temperature", 20.0, "deg"),
    TelemetrySample::new(10.0, "temperature", 30.0, "deg"),
  ]
  let resampled = resample_linear(raw, [5.0])
  assert_true(resampled.length() == 1)
  assert_near(resampled[0].value, 25.0, 1.0e-12)
  let suspect = validate_range(resampled[0], 0.0, 10.0)
  assert_true(suspect.quality is Suspect)
  assert_near(telemetry_health(raw), 1.0, 1.0e-12)
}

///|
test "dynamics keeps zero-step state and finite acceleration" {
  let state = elements_to_state(earth_mu_km3_s2, circular_orbit(7000.0, 0.0))
  let model = AccelerationModel::earth()
  let same = rk4_step(model, state, 0.0)
  assert_near(same.position_km.distance(state.position_km), 0.0, 1.0e-12)
  let acceleration_value = acceleration(model, state)
  assert_true(!acceleration_value.x.is_nan() && acceleration_value.norm() > 0.0)
  assert_true(flight_path_angle(state).abs() < 1.0e-8)
}

///|
test "catalog filtering and merging are deterministic" {
  let leo = CatalogEntry::new(
    "A",
    "leo",
    circular_orbit(earth_radius_km + 500.0, 0.0),
    1.0,
  )
  let geo = CatalogEntry::new("B", "geo", circular_orbit(42164.0, 0.0), 1.0)
  let inactive = CatalogEntry::new(
    "C",
    "inactive",
    circular_orbit(earth_radius_km + 400.0, 0.0),
    1.0,
    active=false,
  )
  let entries = [geo, inactive, leo]
  assert_true(filter_catalog(entries, CatalogQuery::leo()).length() == 1)
  assert_true(catalog_merge([leo], [leo, geo]).length() == 2)
  assert_true(catalog_active_fraction(entries) < 1.0)
}

///|
test "attitude interpolation and conversion preserve identity" {
  let identity = Quaternion::identity()
  let halfway = quaternion_slerp(
    identity,
    Quaternion::from_axis_angle(Vec3::new(0.0, 0.0, 1.0), half_pi),
    0.5,
  )
  assert_true(quaternion_distance(identity, halfway) > 0.0)
  let angles = quaternion_to_euler(
    Quaternion::from_axis_angle(Vec3::new(1.0, 0.0, 0.0), 0.1),
  )
  assert_near(angles.roll_rad, 0.1, 1.0e-8)
}

///|
test "profiles and ground track have requested cardinality" {
  let elements = circular_orbit(7000.0, radians(51.6))
  let grid = anomaly_grid(elements, 24)
  assert_true(grid.length() == 24)
  assert_true(radial_profile(earth_mu_km3_s2, elements, 24).length() == 24)
  assert_true(
    ground_track(earth_mu_km3_s2, elements, Epoch::j2000(), 120.0, 30.0).length() ==
    5,
  )
}
