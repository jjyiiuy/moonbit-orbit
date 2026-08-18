///|
pub struct HealthFlag {
  name : String
  value : Double
  lower : Double
  upper : Double
  healthy : Bool
} derive(Debug, Eq)

///|
pub fn health_flag(
  name : String,
  value : Double,
  lower : Double,
  upper : Double,
) -> HealthFlag {
  { name, value, lower, upper, healthy: value >= lower && value <= upper }
}

///|
pub fn health_flags(
  values : Array[(String, Double)],
  lower : Double,
  upper : Double,
) -> Array[HealthFlag] {
  values.map(item => health_flag(item.0, item.1, lower, upper))
}

///|
pub fn healthy_fraction(flags : Array[HealthFlag]) -> Double {
  if flags.length() == 0 {
    0.0
  } else {
    Double::from_int(flags.filter(flag => flag.healthy).length()) /
    Double::from_int(flags.length())
  }
}

///|
pub fn health_is_nominal(flags : Array[HealthFlag]) -> Bool {
  flags.length() > 0 && flags.all(flag => flag.healthy)
}

///|
pub fn health_score(flags : Array[HealthFlag]) -> Double {
  healthy_fraction(flags) * 100.0
}

///|
pub fn health_margin(flag : HealthFlag) -> Double {
  if flag.value < flag.lower {
    flag.value - flag.lower
  } else if flag.value > flag.upper {
    flag.upper - flag.value
  } else {
    (flag.value - flag.lower).min(flag.upper - flag.value)
  }
}

///|
pub fn health_worst_margin(flags : Array[HealthFlag]) -> Double {
  if flags.length() == 0 {
    0.0
  } else {
    flags.fold(init=1.0e300, (value, flag) => value.min(health_margin(flag)))
  }
}

///|
pub fn health_summary(flags : Array[HealthFlag]) -> String {
  "healthy=\{healthy_fraction(flags)},score=\{health_score(flags)},worst_margin=\{health_worst_margin(flags)}"
}

///|
pub fn thermal_health(power_budget : Double, load : Double) -> HealthFlag {
  health_flag("power", load, 0.0, power_budget)
}

///|
pub fn attitude_health(error_rad : Double, limit_rad : Double) -> HealthFlag {
  health_flag("attitude", error_rad, -limit_rad.abs(), limit_rad.abs())
}

///|
pub fn navigation_health(
  position_error_km : Double,
  limit_km : Double,
) -> HealthFlag {
  health_flag("navigation", position_error_km, 0.0, limit_km.abs())
}

///|
pub fn propulsion_health(
  remaining_km_s : Double,
  required_km_s : Double,
) -> HealthFlag {
  health_flag("propellant", remaining_km_s, required_km_s, 1.0e300)
}

///|
pub fn communication_health(
  margin_db : Double,
  required_db : Double,
) -> HealthFlag {
  health_flag("link", margin_db, required_db, 1.0e300)
}
