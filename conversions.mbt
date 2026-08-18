///|
pub fn kilometers_to_meters(value : Double) -> Double {
  value * 1000.0
}

///|
pub fn meters_to_kilometers(value : Double) -> Double {
  value / 1000.0
}

///|
pub fn kilometers_to_au(value : Double) -> Double {
  value / SunEarthDistanceKm
}

///|
pub fn au_to_kilometers(value : Double) -> Double {
  value * SunEarthDistanceKm
}

///|
pub fn seconds_to_minutes(value : Double) -> Double {
  value / 60.0
}

///|
pub fn minutes_to_seconds(value : Double) -> Double {
  value * 60.0
}

///|
pub fn seconds_to_hours(value : Double) -> Double {
  value / 3600.0
}

///|
pub fn hours_to_seconds(value : Double) -> Double {
  value * 3600.0
}

///|
pub fn days_to_seconds(value : Double) -> Double {
  value * 86400.0
}

///|
pub fn seconds_to_days(value : Double) -> Double {
  value / 86400.0
}

///|
pub fn kilometers_per_second_to_meters_per_second(value : Double) -> Double {
  value * 1000.0
}

///|
pub fn meters_per_second_to_kilometers_per_second(value : Double) -> Double {
  value / 1000.0
}

///|
pub fn degrees_to_radians(value : Double) -> Double {
  radians(value)
}

///|
pub fn radians_to_degrees(value : Double) -> Double {
  degrees(value)
}

///|
pub fn revolutions_per_day_to_rad_per_second(value : Double) -> Double {
  mean_motion_rev_day_to_rad_s(value)
}

///|
pub fn rad_per_second_to_revolutions_per_day(value : Double) -> Double {
  value * 86400.0 / two_pi
}

///|
pub fn newtons_to_kilograms_force(value : Double) -> Double {
  value / 9.80665
}

///|
pub fn kilograms_force_to_newtons(value : Double) -> Double {
  value * 9.80665
}

///|
pub fn pascal_to_bar(value : Double) -> Double {
  value / 100000.0
}

///|
pub fn bar_to_pascal(value : Double) -> Double {
  value * 100000.0
}

///|
pub fn watts_to_dbw(value : Double) -> Double {
  if value <= 0.0 {
    -1.0e9
  } else {
    10.0 * @math.log10(value)
  }
}

///|
pub fn dbw_to_watts(value : Double) -> Double {
  @math.pow(10.0, value / 10.0)
}

///|
pub fn db_to_linear(value : Double) -> Double {
  @math.pow(10.0, value / 10.0)
}

///|
pub fn linear_to_db(value : Double) -> Double {
  if value <= 0.0 {
    -1.0e9
  } else {
    10.0 * @math.log10(value)
  }
}

///|
pub fn normalize_angle_degrees(value : Double) -> Double {
  wrap_positive(value, 360.0)
}

///|
pub fn signed_angle_degrees(value : Double) -> Double {
  let wrapped = normalize_angle_degrees(value)
  if wrapped > 180.0 {
    wrapped - 360.0
  } else {
    wrapped
  }
}

///|
pub fn normalize_time_of_day_seconds(value : Double) -> Double {
  wrap_positive(value, 86400.0)
}

///|
pub fn format_duration_seconds(value : Double) -> String {
  "\{seconds_to_hours(value).floor()}h \{(seconds_to_minutes(value) % 60.0).floor()}m \{(value % 60.0).floor()}s"
}
