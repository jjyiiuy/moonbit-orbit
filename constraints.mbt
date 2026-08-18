///|
pub fn altitude_is_valid(
  elements : ClassicalElements,
  minimum_km : Double,
  maximum_km : Double,
) -> Bool {
  let profile = perigee_apogee(elements)
  profile.perigee_altitude_km >= minimum_km &&
  profile.apogee_altitude_km <= maximum_km
}

///|
pub fn period_is_valid(
  elements : ClassicalElements,
  minimum_s : Double,
  maximum_s : Double,
) -> Bool {
  let period = orbital_period(earth_mu_km3_s2, elements.semi_major_axis_km)
  period >= minimum_s && period <= maximum_s
}

///|
pub fn inclination_is_valid(
  elements : ClassicalElements,
  minimum_rad : Double,
  maximum_rad : Double,
) -> Bool {
  elements.inclination_rad >= minimum_rad &&
  elements.inclination_rad <= maximum_rad
}

///|
pub fn eccentricity_is_valid(
  elements : ClassicalElements,
  maximum : Double,
) -> Bool {
  elements.eccentricity >= 0.0 && elements.eccentricity <= maximum
}

///|
pub fn orbit_is_valid(elements : ClassicalElements) -> Bool {
  validate_elements(elements).valid
}

///|
pub fn state_is_valid(state : StateVector) -> Bool {
  validate_state(state).valid
}

///|
pub fn site_is_valid(site : Geodetic) -> Bool {
  validate_site(site).valid
}

///|
pub fn transfer_is_valid(solution : LambertSolution) -> Bool {
  solution.status is Converged && solution.departure_velocity_km_s.norm() > 0.0
}

///|
pub fn budget_is_valid(budget : DeltaVBudget) -> Bool {
  budget.planned_km_s >= 0.0 &&
  budget.reserve_km_s >= 0.0 &&
  budget.total_km_s >= budget.planned_km_s
}

///|
pub fn pass_is_valid(window : PassWindow) -> Bool {
  window.rise_time_s <= window.set_time_s && window.samples >= 0
}

///|
pub fn telemetry_summary_is_valid(summary : TelemetrySummary) -> Bool {
  summary.count >= summary.valid_count && summary.valid_count >= 0
}

///|
pub fn resource_is_valid(profile : ResourceProfile) -> Bool {
  profile.mass_kg >= 0.0 &&
  profile.propellant_kg >= 0.0 &&
  profile.power_w >= 0.0
}

///|
pub fn link_is_valid(link : LinkBudget) -> Bool {
  link.frequency_ghz >= 0.0 && link.distance_km >= 0.0
}

///|
pub fn command_is_valid(command : ControlCommand) -> Bool {
  command.angle_rad >= 0.0 && command.duration_s >= 0.0
}

///|
pub fn analysis_is_valid(analysis : OrbitAnalysis) -> Bool {
  analysis.altitude_km > -earth_radius_km && analysis.speed_km_s >= 0.0
}

///|
pub fn metric_is_valid(metrics : TrajectoryMetrics) -> Bool {
  metrics.duration_s >= 0.0 &&
  metrics.samples >= 0 &&
  metrics.distance_km >= 0.0
}

///|
pub fn report_is_valid(report : OrbitReport) -> Bool {
  report.title.length() > 0
}

///|
pub fn score_is_valid(score : MissionScore) -> Bool {
  score.total.is_nan() == false
}

///|
pub fn health_is_valid(flag : HealthFlag) -> Bool {
  flag.lower <= flag.upper
}

///|
pub fn histogram_is_valid(histogram : Histogram) -> Bool {
  histogram.edges.length() == histogram.counts.length() + 1
}

///|
pub fn regression_is_valid(model : LinearRegression) -> Bool {
  !model.slope.is_nan() && !model.intercept.is_nan()
}
