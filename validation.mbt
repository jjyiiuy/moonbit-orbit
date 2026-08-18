///|
pub enum ValidationLevel {
  Info
  Warning
  Error
} derive(Debug, Eq)

///|
pub fn all_validation_levels() -> Array[ValidationLevel] {
  [Info, Warning, Error]
}

///|
pub struct ValidationMessage {
  level : ValidationLevel
  code : String
  message : String
} derive(Debug, Eq)

///|
pub struct ValidationReport {
  valid : Bool
  messages : Array[ValidationMessage]
  score : Double
} derive(Debug, Eq)

///|
pub fn ValidationMessage::new(
  level : ValidationLevel,
  code : String,
  message : String,
) -> ValidationMessage {
  { level, code, message }
}

///|
pub fn validate_elements(elements : ClassicalElements) -> ValidationReport {
  let messages : Array[ValidationMessage] = []
  if elements.semi_major_axis_km <= 0.0 {
    messages.push(
      ValidationMessage::new(Error, "axis", "semi-major axis must be positive"),
    )
  }
  if elements.eccentricity < 0.0 || elements.eccentricity >= 1.0 {
    messages.push(
      ValidationMessage::new(
        Error,
        "eccentricity",
        "elliptic eccentricity must be in [0,1)",
      ),
    )
  }
  if elements.inclination_rad.is_nan() {
    messages.push(
      ValidationMessage::new(Error, "inclination", "inclination is not finite"),
    )
  }
  {
    valid: messages.filter(item => item.level is Error).length() == 0,
    score: 1.0 - Double::from_int(messages.length()) * 0.2,
    messages,
  }
}

///|
pub fn validate_state(state : StateVector) -> ValidationReport {
  let messages : Array[ValidationMessage] = []
  if state.position_km.norm() == 0.0 {
    messages.push(
      ValidationMessage::new(Error, "position", "position cannot be zero"),
    )
  }
  if state.velocity_km_s.norm() > 100.0 {
    messages.push(
      ValidationMessage::new(
        Warning,
        "speed",
        "speed exceeds nominal mission range",
      ),
    )
  }
  {
    valid: messages.filter(item => item.level is Error).length() == 0,
    score: 1.0 - Double::from_int(messages.length()) * 0.2,
    messages,
  }
}

///|
pub fn validate_site(site : Geodetic) -> ValidationReport {
  let messages : Array[ValidationMessage] = []
  if site.latitude_rad.abs() > half_pi {
    messages.push(
      ValidationMessage::new(
        Error,
        "latitude",
        "latitude outside physical range",
      ),
    )
  }
  if site.altitude_km < -earth_radius_km {
    messages.push(
      ValidationMessage::new(Error, "altitude", "site is below body center"),
    )
  }
  {
    valid: messages.length() == 0,
    score: 1.0 - Double::from_int(messages.length()) * 0.2,
    messages,
  }
}

///|
pub fn validate_timeline(timeline : MissionTimeline) -> ValidationReport {
  let messages : Array[ValidationMessage] = []
  for event in timeline.events {
    if event.time_s < 0.0 {
      messages.push(
        ValidationMessage::new(Error, "event-time", "event is before epoch"),
      )
    }
    if event.duration_s < 0.0 {
      messages.push(
        ValidationMessage::new(Error, "duration", "duration cannot be negative"),
      )
    }
  }
  {
    valid: messages.length() == 0,
    score: 1.0 - Double::from_int(messages.length()) * 0.2,
    messages,
  }
}

///|
pub fn validate_telemetry(samples : Array[TelemetrySample]) -> ValidationReport {
  let messages : Array[ValidationMessage] = []
  if samples.length() == 0 {
    messages.push(
      ValidationMessage::new(Warning, "empty", "telemetry stream is empty"),
    )
  }
  if samples.any(sample => sample.quality is Invalid) {
    messages.push(
      ValidationMessage::new(
        Error,
        "invalid",
        "telemetry contains invalid values",
      ),
    )
  }
  {
    valid: messages.filter(item => item.level is Error).length() == 0,
    score: 1.0 - Double::from_int(messages.length()) * 0.2,
    messages,
  }
}

///|
pub fn validation_error_count(report : ValidationReport) -> Int {
  report.messages.filter(item => item.level is Error).length()
}

///|
pub fn validation_warning_count(report : ValidationReport) -> Int {
  report.messages.filter(item => item.level is Warning).length()
}

///|
pub fn validation_summary(report : ValidationReport) -> String {
  "valid=\{report.valid},score=\{report.score},messages=\{report.messages.length()}"
}
