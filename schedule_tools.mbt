///|
pub fn schedule_sort(events : Array[MissionEvent]) -> Array[MissionEvent] {
  schedule_to_timeline(events).events
}

///|
pub fn schedule_shift(
  events : Array[MissionEvent],
  delta_s : Double,
) -> Array[MissionEvent] {
  events.map(event => { ..event, time_s: event.time_s + delta_s })
}

///|
pub fn schedule_scale(
  events : Array[MissionEvent],
  factor : Double,
) -> Array[MissionEvent] {
  events.map(event => {
    ..event,
    time_s: event.time_s * factor,
    duration_s: event.duration_s * factor.abs(),
  })
}

///|
pub fn schedule_filter_kind(
  events : Array[MissionEvent],
  kind : MissionEventKind,
) -> Array[MissionEvent] {
  events.filter(event => event.kind == kind)
}

///|
pub fn schedule_total_duration(events : Array[MissionEvent]) -> Double {
  events.fold(init=0.0, (total, event) => total + event.duration_s)
}

///|
pub fn schedule_total_cost(events : Array[MissionEvent]) -> Double {
  events.fold(init=0.0, (total, event) => total + event.delta_v_km_s)
}

///|
pub fn schedule_first(events : Array[MissionEvent]) -> MissionEvent? {
  if events.length() == 0 {
    None
  } else {
    Some(events[0])
  }
}

///|
pub fn schedule_last(events : Array[MissionEvent]) -> MissionEvent? {
  if events.length() == 0 {
    None
  } else {
    Some(events[events.length() - 1])
  }
}

///|
pub fn schedule_contains_label(
  events : Array[MissionEvent],
  label : String,
) -> Bool {
  events.any(event => event.label == label)
}

///|
pub fn schedule_labels(events : Array[MissionEvent]) -> Array[String] {
  events.map(event => event.label)
}

///|
pub fn schedule_times(events : Array[MissionEvent]) -> Array[Double] {
  events.map(event => event.time_s)
}

///|
pub fn schedule_durations(events : Array[MissionEvent]) -> Array[Double] {
  events.map(event => event.duration_s)
}

///|
pub fn schedule_delta_vs(events : Array[MissionEvent]) -> Array[Double] {
  events.map(event => event.delta_v_km_s)
}

///|
pub fn schedule_time_span(events : Array[MissionEvent]) -> Double {
  if events.length() < 2 {
    0.0
  } else {
    let times = schedule_times(events)
    let stats = summarize_samples(times)
    stats.maximum - stats.minimum
  }
}

///|
pub fn schedule_validate(events : Array[MissionEvent]) -> ValidationReport {
  validate_timeline(
    events.fold(init=MissionTimeline::new(), (timeline, event) => {
      timeline.add(event)
    }),
  )
}

///|
pub fn schedule_to_timeline(events : Array[MissionEvent]) -> MissionTimeline {
  events
  .fold(init=MissionTimeline::new(), (timeline, event) => timeline.add(event))
  .sort_by_time()
}

///|
pub fn schedule_from_timeline(
  timeline : MissionTimeline,
) -> Array[MissionEvent] {
  timeline.sort_by_time().events
}
