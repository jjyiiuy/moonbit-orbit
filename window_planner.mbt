///|
pub struct WindowConstraint {
  minimum_elevation_rad : Double
  maximum_range_km : Double
  minimum_duration_s : Double
  required_score : Double
} derive(Debug, Eq)

///|
pub struct PlannedWindow {
  window : VisibilityWindow
  score : Double
  data_volume_mb : Double
  selected : Bool
} derive(Debug, Eq)

///|
pub struct WindowSchedule {
  windows : Array[PlannedWindow]
  total_duration_s : Double
  total_volume_mb : Double
  mean_score : Double
} derive(Debug, Eq)

///|
pub fn make_visibility_window(
  start : Epoch,
  end : Epoch,
  max_elevation_rad : Double,
  closest_range_km : Double,
) -> VisibilityWindow {
  { start, end, max_elevation_rad, closest_range_km }
}

///|
pub fn WindowConstraint::new(
  minimum_elevation_rad : Double,
  maximum_range_km : Double,
  minimum_duration_s : Double,
) -> WindowConstraint {
  {
    minimum_elevation_rad,
    maximum_range_km: maximum_range_km.max(0.0),
    minimum_duration_s: minimum_duration_s.max(0.0),
    required_score: 0.0,
  }
}

///|
pub fn WindowConstraint::with_score(
  constraint : WindowConstraint,
  required_score : Double,
) -> WindowConstraint {
  { ..constraint, required_score: required_score.max(0.0) }
}

///|
pub fn window_duration_s(window : VisibilityWindow) -> Double {
  (window.end.seconds_since_j2000 - window.start.seconds_since_j2000).max(0.0)
}

///|
pub fn window_midpoint(window : VisibilityWindow) -> Epoch {
  window.start.add_seconds(window_duration_s(window) / 2.0)
}

///|
pub fn window_is_acceptable(
  window : VisibilityWindow,
  constraint : WindowConstraint,
) -> Bool {
  window_duration_s(window) >= constraint.minimum_duration_s &&
  window.max_elevation_rad >= constraint.minimum_elevation_rad &&
  window.closest_range_km <= constraint.maximum_range_km
}

///|
pub fn window_quality_score(
  window : VisibilityWindow,
  constraint : WindowConstraint,
) -> Double {
  let duration_score = if constraint.minimum_duration_s == 0.0 {
    1.0
  } else {
    window_duration_s(window) / constraint.minimum_duration_s
  }
  let elevation_score = if constraint.minimum_elevation_rad.abs() < 1.0e-12 {
    1.0
  } else {
    window.max_elevation_rad / constraint.minimum_elevation_rad
  }
  let range_score = if constraint.maximum_range_km <= 0.0 {
    0.0
  } else {
    (1.0 - window.closest_range_km / constraint.maximum_range_km).max(0.0)
  }
  (0.5 * duration_score + 0.3 * elevation_score + 0.2 * range_score).max(0.0)
}

///|
pub fn window_data_volume_mb(
  window : VisibilityWindow,
  rate_kbps : Double,
) -> Double {
  window_duration_s(window) * rate_kbps.max(0.0) / 8000.0
}

///|
pub fn schedule_window(
  window : VisibilityWindow,
  constraint : WindowConstraint,
  rate_kbps : Double,
) -> PlannedWindow {
  let score = window_quality_score(window, constraint)
  {
    window,
    score,
    data_volume_mb: window_data_volume_mb(window, rate_kbps),
    selected: window_is_acceptable(window, constraint) &&
    score >= constraint.required_score,
  }
}

///|
fn planned_start(item : PlannedWindow) -> Double {
  item.window.start.seconds_since_j2000
}

///|
fn sort_planned_windows(windows : Array[PlannedWindow]) -> Array[PlannedWindow] {
  let result = windows.copy()
  for i in 0..<result.length() {
    for j in (i + 1)..<result.length() {
      if planned_start(result[j]) < planned_start(result[i]) {
        let item = result[i]
        result[i] = result[j]
        result[j] = item
      }
    }
  }
  result
}

///|
fn overlaps(a : VisibilityWindow, b : VisibilityWindow) -> Bool {
  a.start.seconds_since_j2000 < b.end.seconds_since_j2000 &&
  b.start.seconds_since_j2000 < a.end.seconds_since_j2000
}

///|
fn select_non_overlapping(
  candidates : Array[PlannedWindow],
) -> Array[PlannedWindow] {
  let sorted = sort_planned_windows(candidates)
  let selected : Array[PlannedWindow] = []
  for candidate in sorted {
    if !candidate.selected {
      continue
    }
    let conflict = selected.any(item => overlaps(item.window, candidate.window))
    if !conflict {
      selected.push(candidate)
    }
  }
  selected
}

///|
pub fn plan_windows(
  windows : Array[VisibilityWindow],
  constraint : WindowConstraint,
  rate_kbps : Double,
) -> WindowSchedule {
  let candidates = windows.map(window => {
    schedule_window(window, constraint, rate_kbps)
  })
  let selected = select_non_overlapping(candidates)
  let total_duration = selected.fold(init=0.0, (sum, item) => {
    sum + window_duration_s(item.window)
  })
  let total_volume = selected.fold(init=0.0, (sum, item) => {
    sum + item.data_volume_mb
  })
  let score = selected.fold(init=0.0, (sum, item) => sum + item.score)
  {
    windows: selected,
    total_duration_s: total_duration,
    total_volume_mb: total_volume,
    mean_score: if selected.length() == 0 {
      0.0
    } else {
      score / Double::from_int(selected.length())
    },
  }
}

///|
pub fn schedule_is_feasible(
  schedule : WindowSchedule,
  minimum_volume_mb : Double,
) -> Bool {
  schedule.total_volume_mb >= minimum_volume_mb.max(0.0)
}

///|
pub fn schedule_efficiency(schedule : WindowSchedule) -> Double {
  if schedule.total_duration_s <= 0.0 {
    0.0
  } else {
    schedule.total_volume_mb / schedule.total_duration_s
  }
}

///|
pub fn schedule_first_window(schedule : WindowSchedule) -> PlannedWindow? {
  if schedule.windows.length() == 0 {
    None
  } else {
    Some(schedule.windows[0])
  }
}

///|
pub fn schedule_last_window(schedule : WindowSchedule) -> PlannedWindow? {
  if schedule.windows.length() == 0 {
    None
  } else {
    Some(schedule.windows[schedule.windows.length() - 1])
  }
}

///|
pub fn schedule_to_mission_timeline(
  schedule : WindowSchedule,
  label_prefix : String,
) -> MissionTimeline {
  let timeline = MissionTimeline::new()
  let mut index = 0
  let mut result = timeline
  for item in schedule.windows {
    let label = "\{label_prefix}-\{index}"
    result = result.add(
      contact_event(
        item.window.start.seconds_since_j2000,
        label,
        window_duration_s(item.window),
      ),
    )
    index += 1
  }
  result.sort_by_time()
}

///|
pub fn schedule_gap_seconds(schedule : WindowSchedule) -> Double {
  if schedule.windows.length() < 2 {
    0.0
  } else {
    let mut gap = 0.0
    for i in 0..<(schedule.windows.length() - 1) {
      let current = schedule.windows[i].window
      let next = schedule.windows[i + 1].window
      let difference = next.start.seconds_since_j2000 -
        current.end.seconds_since_j2000
      gap = gap.max(difference)
    }
    gap
  }
}

///|
pub fn schedule_window_count(schedule : WindowSchedule) -> Int {
  schedule.windows.length()
}

///|
pub fn schedule_summary(schedule : WindowSchedule) -> String {
  "windows=\{schedule.windows.length()},duration_s=\{schedule.total_duration_s},volume_mb=\{schedule.total_volume_mb},mean_score=\{schedule.mean_score}"
}

///|
pub fn filter_windows_by_time(
  windows : Array[VisibilityWindow],
  start : Epoch,
  end : Epoch,
) -> Array[VisibilityWindow] {
  windows.filter(window => {
    window.start.seconds_since_j2000 >= start.seconds_since_j2000 &&
    window.end.seconds_since_j2000 <= end.seconds_since_j2000
  })
}

///|
pub fn merge_adjacent_windows(
  windows : Array[VisibilityWindow],
  maximum_gap_s : Double,
) -> Array[VisibilityWindow] {
  if windows.length() == 0 {
    []
  } else {
    let sorted = windows.copy()
    for i in 0..<sorted.length() {
      for j in (i + 1)..<sorted.length() {
        if sorted[j].start.seconds_since_j2000 <
          sorted[i].start.seconds_since_j2000 {
          let item = sorted[i]
          sorted[i] = sorted[j]
          sorted[j] = item
        }
      }
    }
    let merged : Array[VisibilityWindow] = []
    for window in sorted {
      if merged.length() == 0 {
        merged.push(window)
      } else {
        let last = merged[merged.length() - 1]
        let gap = window.start.seconds_since_j2000 -
          last.end.seconds_since_j2000
        if gap <= maximum_gap_s.max(0.0) {
          merged[merged.length() - 1] = make_visibility_window(
            last.start,
            if window.end.seconds_since_j2000 > last.end.seconds_since_j2000 {
              window.end
            } else {
              last.end
            },
            last.max_elevation_rad.max(window.max_elevation_rad),
            last.closest_range_km.min(window.closest_range_km),
          )
        } else {
          merged.push(window)
        }
      }
    }
    merged
  }
}
