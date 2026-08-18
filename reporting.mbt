///|
pub struct OrbitReport {
  title : String
  sections : Array[String]
  metrics : Array[(String, Double)]
} derive(Debug, Eq)

///|
pub fn OrbitReport::new(title : String) -> OrbitReport {
  { title, sections: [], metrics: [] }
}

///|
pub fn OrbitReport::add_section(
  report : OrbitReport,
  section : String,
) -> OrbitReport {
  let sections = report.sections.copy()
  sections.push(section)
  { ..report, sections, }
}

///|
pub fn OrbitReport::add_metric(
  report : OrbitReport,
  name : String,
  value : Double,
) -> OrbitReport {
  let metrics = report.metrics.copy()
  metrics.push((name, value))
  { ..report, metrics, }
}

///|
pub fn OrbitReport::metric(report : OrbitReport, name : String) -> Double? {
  for item in report.metrics {
    if item.0 == name {
      return Some(item.1)
    }
  }
  None
}

///|
pub fn OrbitReport::render(report : OrbitReport) -> String {
  let mut text = "# \{report.title}\n"
  for section in report.sections {
    text = text + "\n## \{section}\n"
  }
  for item in report.metrics {
    text = text + "- \{item.0}: \{item.1}\n"
  }
  text
}

///|
pub fn orbit_report(mu : Double, elements : ClassicalElements) -> OrbitReport {
  let summary = summarize_orbit(mu, elements)
  OrbitReport::new("Orbit analysis")
  .add_section("Dynamics")
  .add_metric("periapsis_km", summary.radius_periapsis_km)
  .add_metric("apoapsis_km", summary.radius_apoapsis_km)
  .add_metric("period_s", summary.period_s)
  .add_metric("energy_km2_s2", summary.specific_energy_km2_s2)
}

///|
pub fn mission_report(
  timeline : MissionTimeline,
  budget : DeltaVBudget,
) -> OrbitReport {
  OrbitReport::new("Mission plan")
  .add_section("Schedule")
  .add_metric("duration_s", timeline.duration())
  .add_metric("delta_v_km_s", timeline.total_delta_v())
  .add_metric("budget_total_km_s", budget.total_km_s)
  .add_metric(
    "budget_remaining_km_s",
    budget_remaining(budget, timeline.total_delta_v()),
  )
}

///|
pub fn telemetry_report(
  samples : Array[TelemetrySample],
  name : String,
) -> OrbitReport {
  let summary = summarize_telemetry(name, samples)
  OrbitReport::new("Telemetry")
  .add_section(summary.name)
  .add_metric("count", Double::from_int(summary.count))
  .add_metric("valid_count", Double::from_int(summary.valid_count))
  .add_metric("mean", summary.mean)
  .add_metric("latest_time_s", summary.latest_time_s)
}

///|
pub fn benchmark_report_text(results : Array[BenchmarkResult]) -> String {
  let mut text = "benchmark\n"
  for result in results {
    text = text +
      "\{result.name}: iterations=\{result.iterations},checksum=\{result.checksum}\n"
  }
  text
}
