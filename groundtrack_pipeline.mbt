///|
pub struct GroundTrackSummary {
  points : Int
  duration_s : Double
  minimum_altitude_km : Double
  maximum_altitude_km : Double
  mean_altitude_km : Double
  maximum_latitude_rad : Double
  longitude_span_rad : Double
  path_length_km : Double
  gap_count : Int
} derive(Debug, Eq)

///|
pub struct GroundTrackSegment {
  points : Array[GroundTrackPoint]
  start_time_s : Double
  end_time_s : Double
  path_length_km : Double
} derive(Debug, Eq)

///|
pub struct GroundTrackBounds {
  minimum_latitude_rad : Double
  maximum_latitude_rad : Double
  minimum_longitude_rad : Double
  maximum_longitude_rad : Double
  minimum_altitude_km : Double
  maximum_altitude_km : Double
} derive(Debug, Eq)

///|
pub struct StateSample {
  time_s : Double
  state : StateVector
} derive(Debug, Eq)

///|
pub struct StateComparison {
  count : Int
  position_rms_km : Double
  velocity_rms_km_s : Double
  position_max_km : Double
  velocity_max_km_s : Double
  time_span_s : Double
} derive(Debug, Eq)

///|
fn track_geodetic(point : GroundTrackPoint) -> Geodetic {
  Geodetic::new(point.latitude_rad, point.longitude_rad, point.altitude_km)
}

///|
fn track_pair_distance(a : GroundTrackPoint, b : GroundTrackPoint) -> Double {
  geodesic_surface_distance_km(track_geodetic(a), track_geodetic(b))
}

///|
pub fn ground_track_path_length(track : Array[GroundTrackPoint]) -> Double {
  if track.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for i in 0..<(track.length() - 1) {
      total += track_pair_distance(track[i], track[i + 1])
    }
    total
  }
}

///|
pub fn ground_track_gap_count(
  track : Array[GroundTrackPoint],
  maximum_gap_s : Double,
) -> Int {
  if track.length() < 2 {
    0
  } else {
    let mut count = 0
    for i in 0..<(track.length() - 1) {
      if track[i + 1].time_s - track[i].time_s > maximum_gap_s.max(0.0) {
        count += 1
      }
    }
    count
  }
}

///|
pub fn ground_track_summary(
  track : Array[GroundTrackPoint],
) -> GroundTrackSummary {
  if track.length() == 0 {
    {
      points: 0,
      duration_s: 0.0,
      minimum_altitude_km: 0.0,
      maximum_altitude_km: 0.0,
      mean_altitude_km: 0.0,
      maximum_latitude_rad: 0.0,
      longitude_span_rad: 0.0,
      path_length_km: 0.0,
      gap_count: 0,
    }
  } else {
    let altitudes = track.map(point => point.altitude_km)
    let first = track[0]
    let last = track[track.length() - 1]
    let stats = summarize_samples(altitudes)
    {
      points: track.length(),
      duration_s: last.time_s - first.time_s,
      minimum_altitude_km: stats.minimum,
      maximum_altitude_km: stats.maximum,
      mean_altitude_km: stats.mean,
      maximum_latitude_rad: maximum_latitude(track),
      longitude_span_rad: longitude_span(track),
      path_length_km: ground_track_path_length(track),
      gap_count: ground_track_gap_count(track, 120.0),
    }
  }
}

///|
pub fn ground_track_bounds(
  track : Array[GroundTrackPoint],
) -> GroundTrackBounds {
  if track.length() == 0 {
    {
      minimum_latitude_rad: 0.0,
      maximum_latitude_rad: 0.0,
      minimum_longitude_rad: 0.0,
      maximum_longitude_rad: 0.0,
      minimum_altitude_km: 0.0,
      maximum_altitude_km: 0.0,
    }
  } else {
    let first = track[0]
    let mut min_lat = first.latitude_rad
    let mut max_lat = first.latitude_rad
    let mut min_lon = first.longitude_rad
    let mut max_lon = first.longitude_rad
    let mut min_alt = first.altitude_km
    let mut max_alt = first.altitude_km
    for point in track {
      min_lat = min_lat.min(point.latitude_rad)
      max_lat = max_lat.max(point.latitude_rad)
      min_lon = min_lon.min(point.longitude_rad)
      max_lon = max_lon.max(point.longitude_rad)
      min_alt = min_alt.min(point.altitude_km)
      max_alt = max_alt.max(point.altitude_km)
    }
    {
      minimum_latitude_rad: min_lat,
      maximum_latitude_rad: max_lat,
      minimum_longitude_rad: min_lon,
      maximum_longitude_rad: max_lon,
      minimum_altitude_km: min_alt,
      maximum_altitude_km: max_alt,
    }
  }
}

///|
pub fn track_is_contiguous(
  track : Array[GroundTrackPoint],
  maximum_gap_s : Double,
) -> Bool {
  ground_track_gap_count(track, maximum_gap_s) == 0
}

///|
pub fn track_filter_altitude(
  track : Array[GroundTrackPoint],
  minimum_km : Double,
  maximum_km : Double,
) -> Array[GroundTrackPoint] {
  track.filter(point => {
    point.altitude_km >= minimum_km && point.altitude_km <= maximum_km
  })
}

///|
pub fn track_filter_time(
  track : Array[GroundTrackPoint],
  start_s : Double,
  end_s : Double,
) -> Array[GroundTrackPoint] {
  track.filter(point => point.time_s >= start_s && point.time_s <= end_s)
}

///|
pub fn track_latitude_histogram(
  track : Array[GroundTrackPoint],
  bins : Int,
) -> Histogram {
  histogram(track.map(point => degrees(point.latitude_rad)), -90.0, 90.0, bins)
}

///|
pub fn track_altitude_stats(track : Array[GroundTrackPoint]) -> SampleStats {
  summarize_samples(track.map(point => point.altitude_km))
}

///|
fn append_csv_line(text : String, point : GroundTrackPoint) -> String {
  text +
  "\{point.time_s},\{point.latitude_rad},\{point.longitude_rad},\{point.altitude_km}\n"
}

///|
pub fn track_to_csv(track : Array[GroundTrackPoint]) -> String {
  let mut text = "time_s,latitude_rad,longitude_rad,altitude_km\n"
  for point in track {
    text = append_csv_line(text, point)
  }
  text
}

///|
pub fn segment_ground_track(
  track : Array[GroundTrackPoint],
  maximum_gap_s : Double,
) -> Array[GroundTrackSegment] {
  if track.length() == 0 {
    []
  } else {
    let segments : Array[GroundTrackSegment] = []
    let points : Array[GroundTrackPoint] = [track[0]]
    for i in 1..<track.length() {
      let gap = track[i].time_s - track[i - 1].time_s
      if gap > maximum_gap_s.max(0.0) {
        segments.push(make_ground_track_segment(points))
        points.clear()
      }
      points.push(track[i])
    }
    if points.length() > 0 {
      segments.push(make_ground_track_segment(points))
    }
    segments
  }
}

///|
fn make_ground_track_segment(
  points : Array[GroundTrackPoint],
) -> GroundTrackSegment {
  let first = points[0]
  let last = points[points.length() - 1]
  {
    points,
    start_time_s: first.time_s,
    end_time_s: last.time_s,
    path_length_km: ground_track_path_length(points),
  }
}

///|
fn track_interpolate(
  a : GroundTrackPoint,
  b : GroundTrackPoint,
  time_s : Double,
) -> GroundTrackPoint {
  let fraction = inverse_lerp(a.time_s, b.time_s, time_s)
  {
    time_s,
    latitude_rad: lerp_scalar(a.latitude_rad, b.latitude_rad, fraction),
    longitude_rad: lerp_scalar(a.longitude_rad, b.longitude_rad, fraction),
    altitude_km: lerp_scalar(a.altitude_km, b.altitude_km, fraction),
  }
}

///|
pub fn resample_ground_track(
  track : Array[GroundTrackPoint],
  times : Array[Double],
) -> Array[GroundTrackPoint] {
  let result : Array[GroundTrackPoint] = []
  for time in times {
    if track.length() == 0 ||
      time < track[0].time_s ||
      time > track[track.length() - 1].time_s {
      continue
    }
    let mut inserted = false
    for i in 0..<track.length() {
      if track[i].time_s == time {
        result.push(track[i])
        inserted = true
        break
      }
      if i + 1 < track.length() &&
        track[i].time_s < time &&
        time < track[i + 1].time_s {
        result.push(track_interpolate(track[i], track[i + 1], time))
        inserted = true
        break
      }
    }
    if !inserted && time == track[track.length() - 1].time_s {
      result.push(track[track.length() - 1])
    }
  }
  result
}

///|
pub fn track_time_step_stats(track : Array[GroundTrackPoint]) -> SampleStats {
  if track.length() < 2 {
    summarize_samples([])
  } else {
    let steps : Array[Double] = []
    for i in 0..<(track.length() - 1) {
      steps.push(track[i + 1].time_s - track[i].time_s)
    }
    summarize_samples(steps)
  }
}

///|
pub fn propagate_state_samples(
  mu : Double,
  elements : ClassicalElements,
  times_s : Array[Double],
) -> Array[StateSample] {
  times_s.map(time_s => {
    let propagated = propagate_kepler(mu, elements, time_s)
    { time_s, state: elements_to_state(mu, propagated) }
  })
}

///|
pub fn state_sample_at(
  samples : Array[StateSample],
  time_s : Double,
) -> StateSample? {
  for sample in samples {
    if sample.time_s == time_s {
      return Some(sample)
    }
  }
  None
}

///|
fn pipeline_position_error(a : StateVector, b : StateVector) -> Double {
  a.position_km.distance(b.position_km)
}

///|
fn pipeline_velocity_error(a : StateVector, b : StateVector) -> Double {
  a.velocity_km_s.distance(b.velocity_km_s)
}

///|
pub fn compare_state_samples(
  expected : Array[StateSample],
  actual : Array[StateSample],
) -> StateComparison {
  let count = expected.length().min(actual.length())
  if count == 0 {
    {
      count: 0,
      position_rms_km: 0.0,
      velocity_rms_km_s: 0.0,
      position_max_km: 0.0,
      velocity_max_km_s: 0.0,
      time_span_s: 0.0,
    }
  } else {
    let mut position_square = 0.0
    let mut velocity_square = 0.0
    let mut position_max = 0.0
    let mut velocity_max = 0.0
    for i in 0..<count {
      let position_error = pipeline_position_error(
        expected[i].state,
        actual[i].state,
      )
      let velocity_error = pipeline_velocity_error(
        expected[i].state,
        actual[i].state,
      )
      position_square += position_error * position_error
      velocity_square += velocity_error * velocity_error
      position_max = position_max.max(position_error)
      velocity_max = velocity_max.max(velocity_error)
    }
    {
      count,
      position_rms_km: (position_square / Double::from_int(count)).sqrt(),
      velocity_rms_km_s: (velocity_square / Double::from_int(count)).sqrt(),
      position_max_km: position_max,
      velocity_max_km_s: velocity_max,
      time_span_s: expected[count - 1].time_s - expected[0].time_s,
    }
  }
}

///|
pub fn state_comparison_is_valid(
  comparison : StateComparison,
  position_tolerance_km : Double,
  velocity_tolerance_km_s : Double,
) -> Bool {
  comparison.count > 0 &&
  comparison.position_max_km <= position_tolerance_km.abs() &&
  comparison.velocity_max_km_s <= velocity_tolerance_km_s.abs()
}

///|
pub fn state_comparison_score(comparison : StateComparison) -> Double {
  if comparison.count == 0 {
    0.0
  } else {
    1.0 / (1.0 + comparison.position_rms_km + comparison.velocity_rms_km_s)
  }
}

///|
pub fn state_samples_to_csv(samples : Array[StateSample]) -> String {
  let mut text = "time_s,x_km,y_km,z_km,vx_km_s,vy_km_s,vz_km_s\n"
  for sample in samples {
    let state = sample.state
    text = text +
      "\{sample.time_s},\{state.position_km.x},\{state.position_km.y},\{state.position_km.z},\{state.velocity_km_s.x},\{state.velocity_km_s.y},\{state.velocity_km_s.z}\n"
  }
  text
}
