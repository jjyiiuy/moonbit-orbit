///|
pub enum MissionEventKind {
  OrbitInsertion
  Maneuver
  GroundContact
  EclipseEntry
  EclipseExit
  PayloadOperation
  Custom
} derive(Debug, Eq)

///|
pub fn mission_event_kind_name(kind : MissionEventKind) -> String {
  match kind {
    OrbitInsertion => "orbit-insertion"
    Maneuver => "maneuver"
    GroundContact => "ground-contact"
    EclipseEntry => "eclipse-entry"
    EclipseExit => "eclipse-exit"
    PayloadOperation => "payload-operation"
    Custom => "custom"
  }
}

///|
pub fn all_mission_event_kinds() -> Array[MissionEventKind] {
  [
    OrbitInsertion,
    Maneuver,
    GroundContact,
    EclipseEntry,
    EclipseExit,
    PayloadOperation,
    Custom,
  ]
}

///|
pub struct MissionEvent {
  time_s : Double
  kind : MissionEventKind
  label : String
  delta_v_km_s : Double
  duration_s : Double
} derive(Debug, Eq)

///|
pub struct DeltaVBudget {
  planned_km_s : Double
  reserve_fraction : Double
  reserve_km_s : Double
  total_km_s : Double
} derive(Debug, Eq)

///|
pub struct MissionTimeline {
  events : Array[MissionEvent]
  end_time_s : Double
} derive(Debug, Eq)

///|
pub struct PassWindow {
  rise_time_s : Double
  set_time_s : Double
  max_elevation_rad : Double
  samples : Int
} derive(Debug, Eq)

///|
pub fn MissionEvent::new(
  time_s : Double,
  kind : MissionEventKind,
  label : String,
  delta_v_km_s? : Double = 0.0,
  duration_s? : Double = 0.0,
) -> MissionEvent {
  {
    time_s,
    kind,
    label,
    delta_v_km_s: delta_v_km_s.max(0.0),
    duration_s: duration_s.max(0.0),
  }
}

///|
pub fn MissionTimeline::new(end_time_s? : Double = 0.0) -> MissionTimeline {
  { events: [], end_time_s: end_time_s.max(0.0) }
}

///|
pub fn MissionTimeline::add(
  timeline : MissionTimeline,
  event : MissionEvent,
) -> MissionTimeline {
  let events = timeline.events.copy()
  events.push(event)
  {
    events,
    end_time_s: timeline.end_time_s.max(event.time_s + event.duration_s),
  }
}

///|
pub fn MissionTimeline::sort_by_time(
  timeline : MissionTimeline,
) -> MissionTimeline {
  let result = timeline
  for i in 0..<result.events.length() {
    for j in (i + 1)..<result.events.length() {
      if result.events[j].time_s < result.events[i].time_s {
        let swap = result.events[i]
        result.events[i] = result.events[j]
        result.events[j] = swap
      }
    }
  }
  result
}

///|
pub fn MissionTimeline::duration(timeline : MissionTimeline) -> Double {
  timeline.end_time_s
}

///|
pub fn MissionTimeline::total_delta_v(timeline : MissionTimeline) -> Double {
  timeline.events.fold(init=0.0, (total, event) => total + event.delta_v_km_s)
}

///|
pub fn MissionTimeline::events_in_range(
  timeline : MissionTimeline,
  start_s : Double,
  end_s : Double,
) -> Array[MissionEvent] {
  timeline.events.filter(event => {
    event.time_s >= start_s && event.time_s <= end_s
  })
}

///|
pub fn make_delta_v_budget(
  planned_km_s : Double,
  reserve_fraction? : Double = 0.1,
) -> DeltaVBudget {
  let planned = planned_km_s.max(0.0)
  let reserve = reserve_fraction.max(0.0)
  let reserve_value = planned * reserve
  {
    planned_km_s: planned,
    reserve_fraction: reserve,
    reserve_km_s: reserve_value,
    total_km_s: planned + reserve_value,
  }
}

///|
pub fn budget_remaining(budget : DeltaVBudget, spent_km_s : Double) -> Double {
  budget.total_km_s - spent_km_s.max(0.0)
}

///|
pub fn budget_is_exceeded(budget : DeltaVBudget, spent_km_s : Double) -> Bool {
  spent_km_s > budget.total_km_s
}

///|
pub fn accumulate_budgets(budgets : Array[DeltaVBudget]) -> DeltaVBudget {
  let planned = budgets.fold(init=0.0, (total, budget) => {
    total + budget.planned_km_s
  })
  let total = budgets.fold(init=0.0, (sum, budget) => sum + budget.total_km_s)
  let reserve = total - planned
  {
    planned_km_s: planned,
    reserve_fraction: if planned == 0.0 {
      0.0
    } else {
      reserve / planned
    },
    reserve_km_s: reserve,
    total_km_s: total,
  }
}

///|
pub fn estimate_orbit_pass(
  station : GroundStation,
  elements : ClassicalElements,
  start_epoch : Epoch,
  duration_s : Double,
  step_s : Double,
  min_elevation_rad : Double,
) -> Array[PassWindow] {
  let windows : Array[PassWindow] = []
  if duration_s <= 0.0 || step_s <= 0.0 {
    return windows
  }
  let mut in_pass = false
  let mut rise = 0.0
  let mut peak = -half_pi
  let mut samples = 0
  let mut time = 0.0
  while time <= duration_s {
    let propagated = propagate_kepler(earth_mu_km3_s2, elements, time)
    let state = elements_to_state(earth_mu_km3_s2, propagated)
    let sample = sample_visibility(station, start_epoch, state.position_km)
    if sample.visible && sample.look.elevation_rad >= min_elevation_rad {
      if !in_pass {
        in_pass = true
        rise = time
        peak = sample.look.elevation_rad
        samples = 0
      }
      peak = peak.max(sample.look.elevation_rad)
      samples += 1
    } else if in_pass {
      windows.push({
        rise_time_s: rise,
        set_time_s: time,
        max_elevation_rad: peak,
        samples,
      })
      in_pass = false
    }
    time += step_s
  }
  if in_pass {
    windows.push({
      rise_time_s: rise,
      set_time_s: duration_s,
      max_elevation_rad: peak,
      samples,
    })
  }
  windows
}

///|
pub fn refine_pass_peak(
  station : GroundStation,
  elements : ClassicalElements,
  epoch : Epoch,
  start_s : Double,
  end_s : Double,
  step_s : Double,
) -> Double {
  let mut peak = -half_pi
  let mut t = start_s
  while t <= end_s {
    let state = elements_to_state(
      earth_mu_km3_s2,
      propagate_kepler(earth_mu_km3_s2, elements, t),
    )
    let angle = sample_visibility(station, epoch, state.position_km).look.elevation_rad
    peak = peak.max(angle)
    t += step_s.max(1.0)
  }
  peak
}

///|
pub fn mission_event_count(
  timeline : MissionTimeline,
  kind : MissionEventKind,
) -> Int {
  timeline.events.fold(init=0, (count, event) => {
    if event.kind == kind {
      count + 1
    } else {
      count
    }
  })
}

///|
pub fn mission_energy_proxy(
  mu : Double,
  elements : ClassicalElements,
  mass_kg : Double,
) -> Double {
  mass_kg.max(0.0) *
  specific_orbital_energy(mu, elements.semi_major_axis_km).abs()
}

///|
pub fn maneuver_event(
  time_s : Double,
  label : String,
  delta_v_km_s : Double,
) -> MissionEvent {
  MissionEvent::new(time_s, Maneuver, label, delta_v_km_s~)
}

///|
pub fn contact_event(
  time_s : Double,
  label : String,
  duration_s : Double,
) -> MissionEvent {
  MissionEvent::new(time_s, GroundContact, label, duration_s~)
}

///|
pub fn timeline_report(timeline : MissionTimeline) -> String {
  let ordered = timeline.sort_by_time()
  "events=\{ordered.events.length()},duration_s=\{ordered.end_time_s},delta_v_km_s=\{ordered.total_delta_v()}"
}
