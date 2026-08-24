///|
pub struct MissionPhase {
  name : String
  start_s : Double
  end_s : Double
  delta_v_km_s : Double
  priority : Int
  resource_cost : Double
} derive(Debug, Eq)

///|
pub struct MissionScenario {
  name : String
  phases : Array[MissionPhase]
  reserve_km_s : Double
} derive(Debug, Eq)

///|
pub struct ScenarioSummary {
  valid : Bool
  phase_count : Int
  total_duration_s : Double
  total_delta_v_km_s : Double
  total_resource_cost : Double
  overlap_count : Int
  resource_remaining : Double
} derive(Debug, Eq)

///|
pub fn mission_phase(
  name : String,
  start_s : Double,
  end_s : Double,
  delta_v_km_s : Double,
) -> MissionPhase {
  {
    name,
    start_s,
    end_s,
    delta_v_km_s: delta_v_km_s.max(0.0),
    priority: 0,
    resource_cost: delta_v_km_s.max(0.0),
  }
}

///|
pub fn MissionPhase::with_priority(
  phase : MissionPhase,
  priority : Int,
) -> MissionPhase {
  { ..phase, priority, }
}

///|
pub fn MissionPhase::with_resource_cost(
  phase : MissionPhase,
  resource_cost : Double,
) -> MissionPhase {
  { ..phase, resource_cost: resource_cost.max(0.0) }
}

///|
pub fn phase_duration_s(phase : MissionPhase) -> Double {
  (phase.end_s - phase.start_s).max(0.0)
}

///|
pub fn phase_is_well_formed(phase : MissionPhase) -> Bool {
  phase.name.length() > 0 &&
  phase.start_s >= 0.0 &&
  phase.end_s >= phase.start_s &&
  phase.delta_v_km_s >= 0.0 &&
  phase.resource_cost >= 0.0
}

///|
pub fn phase_contains(phase : MissionPhase, time_s : Double) -> Bool {
  time_s >= phase.start_s && time_s <= phase.end_s
}

///|
pub fn MissionScenario::new(name : String) -> MissionScenario {
  { name, phases: [], reserve_km_s: 0.0 }
}

///|
pub fn MissionScenario::with_reserve(
  scenario : MissionScenario,
  reserve_km_s : Double,
) -> MissionScenario {
  { ..scenario, reserve_km_s: reserve_km_s.max(0.0) }
}

///|
pub fn MissionScenario::add_phase(
  scenario : MissionScenario,
  phase : MissionPhase,
) -> MissionScenario {
  let phases = scenario.phases.copy()
  phases.push(phase)
  { ..scenario, phases, }
}

///|
pub fn MissionScenario::sort_by_start(
  scenario : MissionScenario,
) -> MissionScenario {
  let phases = scenario.phases.copy()
  for i in 0..<phases.length() {
    for j in (i + 1)..<phases.length() {
      if phases[j].start_s < phases[i].start_s {
        let item = phases[i]
        phases[i] = phases[j]
        phases[j] = item
      }
    }
  }
  { ..scenario, phases, }
}

///|
fn phase_overlaps(a : MissionPhase, b : MissionPhase) -> Bool {
  a.start_s < b.end_s && b.start_s < a.end_s
}

///|
pub fn count_phase_overlaps(scenario : MissionScenario) -> Int {
  let ordered = scenario.sort_by_start()
  let mut count = 0
  for i in 0..<ordered.phases.length() {
    for j in (i + 1)..<ordered.phases.length() {
      if phase_overlaps(ordered.phases[i], ordered.phases[j]) {
        count += 1
      }
    }
  }
  count
}

///|
pub fn scenario_duration_s(scenario : MissionScenario) -> Double {
  scenario.phases.fold(init=0.0, (maximum, phase) => maximum.max(phase.end_s))
}

///|
pub fn scenario_delta_v(scenario : MissionScenario) -> Double {
  scenario.phases.fold(init=0.0, (total, phase) => total + phase.delta_v_km_s)
}

///|
pub fn scenario_resource_cost(scenario : MissionScenario) -> Double {
  scenario.phases.fold(init=0.0, (total, phase) => total + phase.resource_cost)
}

///|
pub fn scenario_is_well_formed(scenario : MissionScenario) -> Bool {
  scenario.name.length() > 0 &&
  scenario.phases.all(phase_is_well_formed) &&
  count_phase_overlaps(scenario) == 0
}

///|
pub fn scenario_resource_margin(
  scenario : MissionScenario,
  resource_limit : Double,
) -> Double {
  resource_limit.max(0.0) +
  scenario.reserve_km_s -
  scenario_resource_cost(scenario)
}

///|
pub fn summarize_scenario(
  scenario : MissionScenario,
  resource_limit : Double,
) -> ScenarioSummary {
  let overlaps = count_phase_overlaps(scenario)
  let valid = scenario_is_well_formed(scenario) &&
    scenario_resource_margin(scenario, resource_limit) >= 0.0
  {
    valid,
    phase_count: scenario.phases.length(),
    total_duration_s: scenario_duration_s(scenario),
    total_delta_v_km_s: scenario_delta_v(scenario),
    total_resource_cost: scenario_resource_cost(scenario),
    overlap_count: overlaps,
    resource_remaining: scenario_resource_margin(scenario, resource_limit),
  }
}

///|
pub fn phases_at_time(
  scenario : MissionScenario,
  time_s : Double,
) -> Array[MissionPhase] {
  scenario.phases.filter(phase => phase_contains(phase, time_s))
}

///|
pub fn phases_with_priority(
  scenario : MissionScenario,
  minimum_priority : Int,
) -> Array[MissionPhase] {
  scenario.phases.filter(phase => phase.priority >= minimum_priority)
}

///|
pub fn scenario_to_timeline(scenario : MissionScenario) -> MissionTimeline {
  let ordered = scenario.sort_by_start()
  let mut timeline = MissionTimeline::new()
  for phase in ordered.phases {
    timeline = timeline.add(
      MissionEvent::new(
        phase.start_s,
        PayloadOperation,
        phase.name,
        delta_v_km_s=phase.delta_v_km_s,
        duration_s=phase_duration_s(phase),
      ),
    )
  }
  timeline.sort_by_time()
}

///|
pub fn scenario_report(
  scenario : MissionScenario,
  resource_limit : Double,
) -> String {
  let summary = summarize_scenario(scenario, resource_limit)
  "valid=\{summary.valid},phases=\{summary.phase_count},duration_s=\{summary.total_duration_s},delta_v_km_s=\{summary.total_delta_v_km_s},overlaps=\{summary.overlap_count}"
}

///|
pub fn scenario_phase_names(scenario : MissionScenario) -> Array[String] {
  scenario.phases.map(phase => phase.name)
}

///|
pub fn scenario_peak_priority(scenario : MissionScenario) -> Int {
  scenario.phases.fold(init=0, (maximum, phase) => maximum.max(phase.priority))
}

///|
pub fn scenario_is_empty(scenario : MissionScenario) -> Bool {
  scenario.phases.length() == 0
}

///|
pub fn scenario_append_all(
  scenario : MissionScenario,
  phases : Array[MissionPhase],
) -> MissionScenario {
  let mut result = scenario
  for phase in phases {
    result = result.add_phase(phase)
  }
  result
}

///|
pub fn phase_utilization(
  phase : MissionPhase,
  resource_limit : Double,
) -> Double {
  if resource_limit <= 0.0 {
    0.0
  } else {
    phase.resource_cost / resource_limit
  }
}

///|
pub fn scenario_utilization(
  scenario : MissionScenario,
  resource_limit : Double,
) -> Double {
  if resource_limit <= 0.0 {
    0.0
  } else {
    scenario_resource_cost(scenario) / resource_limit
  }
}
