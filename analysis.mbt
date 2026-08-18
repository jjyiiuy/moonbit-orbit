///|
pub struct OrbitAnalysis {
  elements : ClassicalElements
  state : StateVector
  altitude_km : Double
  speed_km_s : Double
  radial_speed_km_s : Double
  flight_path_angle_rad : Double
  energy_km2_s2 : Double
  angular_momentum_km2_s : Double
} derive(Debug, Eq)

///|
pub struct GroundTrackPoint {
  time_s : Double
  latitude_rad : Double
  longitude_rad : Double
  altitude_km : Double
} derive(Debug, Eq)

///|
pub struct CoverageReport {
  points : Int
  visible_points : Int
  visibility_fraction : Double
  minimum_elevation_rad : Double
  maximum_elevation_rad : Double
} derive(Debug, Eq)

///|
pub fn analyze_orbit(
  mu : Double,
  elements : ClassicalElements,
) -> OrbitAnalysis {
  let state = elements_to_state(mu, elements)
  {
    elements,
    state,
    altitude_km: state.position_km.norm() - earth_radius_km,
    speed_km_s: state.velocity_km_s.norm(),
    radial_speed_km_s: radial_velocity(state),
    flight_path_angle_rad: flight_path_angle(state),
    energy_km2_s2: orbit_state_energy(mu, state),
    angular_momentum_km2_s: orbit_state_angular_momentum(state),
  }
}

///|
pub fn ground_track(
  mu : Double,
  elements : ClassicalElements,
  epoch : Epoch,
  duration_s : Double,
  step_s : Double,
) -> Array[GroundTrackPoint] {
  let result : Array[GroundTrackPoint] = []
  if duration_s < 0.0 || step_s <= 0.0 {
    return result
  }
  let mut t = 0.0
  while t <= duration_s {
    let state = elements_to_state(mu, propagate_kepler(mu, elements, t))
    let ecef = eci_to_ecef(epoch, state.position_km)
    let geo = ecef_to_geodetic_spherical(ecef)
    result.push({
      time_s: t,
      latitude_rad: geo.latitude_rad,
      longitude_rad: geo.longitude_rad,
      altitude_km: geo.altitude_km,
    })
    t += step_s
  }
  result
}

///|
pub fn coverage_report(
  station : GroundStation,
  points : Array[GroundTrackPoint],
  epoch : Epoch,
  elements : ClassicalElements,
  min_elevation_rad : Double,
) -> CoverageReport {
  if points.length() == 0 {
    return {
      points: 0,
      visible_points: 0,
      visibility_fraction: 0.0,
      minimum_elevation_rad: 0.0,
      maximum_elevation_rad: 0.0,
    }
  }
  let mut visible = 0
  let mut minimum = half_pi
  let mut maximum = -half_pi
  for point in points {
    let state = elements_to_state(
      earth_mu_km3_s2,
      propagate_kepler(earth_mu_km3_s2, elements, point.time_s),
    )
    let look = look_angle_from_eci(station.location, epoch, state.position_km)
    minimum = minimum.min(look.elevation_rad)
    maximum = maximum.max(look.elevation_rad)
    if look.elevation_rad >= min_elevation_rad {
      visible += 1
    }
  }
  {
    points: points.length(),
    visible_points: visible,
    visibility_fraction: Double::from_int(visible) /
    Double::from_int(points.length()),
    minimum_elevation_rad: minimum,
    maximum_elevation_rad: maximum,
  }
}

///|
pub fn find_equator_crossings(
  track : Array[GroundTrackPoint],
) -> Array[GroundTrackPoint] {
  let result : Array[GroundTrackPoint] = []
  if track.length() < 2 {
    return result
  }
  for i in 0..<(track.length() - 1) {
    if track[i].latitude_rad == 0.0 ||
      track[i].latitude_rad * track[i + 1].latitude_rad < 0.0 {
      result.push(track[i])
    }
  }
  result
}

///|
pub fn ascending_node_longitude(track : Array[GroundTrackPoint]) -> Double {
  let crossings = find_equator_crossings(track)
  if crossings.length() == 0 {
    0.0
  } else {
    crossings[0].longitude_rad
  }
}

///|
pub fn mean_altitude(track : Array[GroundTrackPoint]) -> Double {
  mean(track.map(point => point.altitude_km))
}

///|
pub fn maximum_latitude(track : Array[GroundTrackPoint]) -> Double {
  track.fold(init=0.0, (value, point) => value.max(point.latitude_rad.abs()))
}

///|
pub fn longitude_span(track : Array[GroundTrackPoint]) -> Double {
  if track.length() < 2 {
    0.0
  } else {
    longitude_difference_rad(
      track[0].longitude_rad,
      track[track.length() - 1].longitude_rad,
    ).abs()
  }
}

///|
pub fn anomaly_grid(
  elements : ClassicalElements,
  count : Int,
) -> Array[ClassicalElements] {
  let result : Array[ClassicalElements] = []
  if count <= 0 {
    return result
  }
  for i in 0..<count {
    result.push({
      ..elements,
      true_anomaly_rad: two_pi * Double::from_int(i) / Double::from_int(count),
    })
  }
  result
}

///|
pub fn radial_profile(
  mu : Double,
  elements : ClassicalElements,
  count : Int,
) -> Array[Double] {
  anomaly_grid(elements, count).map(item => {
    elements_to_state(mu, item).position_km.norm()
  })
}

///|
pub fn speed_profile(
  mu : Double,
  elements : ClassicalElements,
  count : Int,
) -> Array[Double] {
  anomaly_grid(elements, count).map(item => {
    elements_to_state(mu, item).velocity_km_s.norm()
  })
}

///|
pub fn profile_minimum(values : Array[Double]) -> Double {
  summarize_samples(values).minimum
}

///|
pub fn profile_maximum(values : Array[Double]) -> Double {
  summarize_samples(values).maximum
}

///|
pub fn profile_range(values : Array[Double]) -> Double {
  profile_maximum(values) - profile_minimum(values)
}
