///|
pub struct TleRecord {
  name : String
  satellite_number : Int
  classification : Char
  epoch_year : Int
  epoch_day : Double
  inclination_rad : Double
  raan_rad : Double
  eccentricity : Double
  arg_periapsis_rad : Double
  mean_anomaly_rad : Double
  mean_motion_rev_day : Double
  revolution_number : Int
} derive(Debug, Eq)

///|
pub(all) enum TleParseError {
  LineTooShort(String)
  InvalidNumber(String)
  InvalidFormat(String)
} derive(Debug, Eq)

///|
fn slice_text(s : String, start : Int, end : Int) -> String {
  s[start:end].trim().to_owned()
}

///|
fn digit_value(c : Char) -> Int? {
  match c {
    '0' => Some(0)
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    '4' => Some(4)
    '5' => Some(5)
    '6' => Some(6)
    '7' => Some(7)
    '8' => Some(8)
    '9' => Some(9)
    _ => None
  }
}

///|
fn parse_int_field(s : String) -> Result[Int, TleParseError] {
  let text = s.trim()
  let mut sign = 1
  let mut value = 0
  let mut seen_digit = false
  for index, c in text {
    if index == 0 && c == '-' {
      sign = -1
    } else if index == 0 && c == '+' {
      ()
    } else {
      match digit_value(c) {
        Some(d) => {
          seen_digit = true
          value = value * 10 + d
        }
        None => return Err(TleParseError::InvalidNumber(text.to_owned()))
      }
    }
  }
  if seen_digit {
    Ok(sign * value)
  } else {
    Err(TleParseError::InvalidNumber(text.to_owned()))
  }
}

///|
fn parse_double_field(s : String) -> Result[Double, TleParseError] {
  let text = s.trim()
  let mut sign = 1.0
  let mut integer = 0.0
  let mut fraction = 0.0
  let mut scale = 1.0
  let mut after_dot = false
  let mut seen_digit = false
  for index, c in text {
    if index == 0 && c == '-' {
      sign = -1.0
    } else if index == 0 && c == '+' {
      ()
    } else if c == '.' {
      if after_dot {
        return Err(TleParseError::InvalidNumber(text.to_owned()))
      }
      after_dot = true
    } else {
      match digit_value(c) {
        Some(d) => {
          seen_digit = true
          if after_dot {
            scale = scale * 10.0
            fraction = fraction + Double::from_int(d) / scale
          } else {
            integer = integer * 10.0 + Double::from_int(d)
          }
        }
        None => return Err(TleParseError::InvalidNumber(text.to_owned()))
      }
    }
  }
  if seen_digit {
    Ok(sign * (integer + fraction))
  } else {
    Err(TleParseError::InvalidNumber(text.to_owned()))
  }
}

///|
pub fn parse_tle(name : String, line1 : String, line2 : String) -> Result[TleRecord, TleParseError] {
  if line1.length() < 63 {
    return Err(TleParseError::LineTooShort("line1"))
  }
  if line2.length() < 63 {
    return Err(TleParseError::LineTooShort("line2"))
  }
  if !(line1 is [.."1 ", ..]) || !(line2 is [.."2 ", ..]) {
    return Err(TleParseError::InvalidFormat("TLE lines must start with 1 and 2"))
  }
  let sat1 = match parse_int_field(slice_text(line1, 2, 7)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let sat2 = match parse_int_field(slice_text(line2, 2, 7)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if sat1 != sat2 {
    return Err(TleParseError::InvalidFormat("satellite numbers differ"))
  }
  let classification = line1.get_char(7).unwrap_or('U')
  let epoch_year = match parse_int_field(slice_text(line1, 18, 20)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let epoch_day = match parse_double_field(slice_text(line1, 20, 32)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let ecc_text = slice_text(line2, 26, 33)
  let eccentricity = match parse_double_field("0.\{ecc_text}") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let inclination = match parse_double_field(slice_text(line2, 8, 16)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let raan = match parse_double_field(slice_text(line2, 17, 25)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let arg_periapsis = match parse_double_field(slice_text(line2, 34, 42)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let mean_anomaly = match parse_double_field(slice_text(line2, 43, 51)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let mean_motion = match parse_double_field(slice_text(line2, 52, 63)) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let revolution = if line2.length() >= 68 {
    match parse_int_field(slice_text(line2, 63, 68)) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
  } else {
    0
  }
  Ok({
    name,
    satellite_number: sat1,
    classification,
    epoch_year,
    epoch_day,
    inclination_rad: radians(inclination),
    raan_rad: radians(raan),
    eccentricity,
    arg_periapsis_rad: radians(arg_periapsis),
    mean_anomaly_rad: radians(mean_anomaly),
    mean_motion_rev_day: mean_motion,
    revolution_number: revolution,
  })
}

///|
pub fn mean_motion_rev_day_to_rad_s(mean_motion_rev_day : Double) -> Double {
  mean_motion_rev_day * two_pi / 86400.0
}

///|
pub fn semi_major_axis_from_mean_motion(mu : Double, mean_motion_rev_day : Double) -> Double {
  let n = mean_motion_rev_day_to_rad_s(mean_motion_rev_day)
  @math.pow(mu / (n * n), 1.0 / 3.0)
}

///|
pub fn tle_to_mean_elements(mu : Double, tle : TleRecord) -> ClassicalElements {
  let a = semi_major_axis_from_mean_motion(mu, tle.mean_motion_rev_day)
  let eccentric = solve_kepler(tle.mean_anomaly_rad, tle.eccentricity)
  ClassicalElements::new(
    a,
    tle.eccentricity,
    tle.inclination_rad,
    tle.raan_rad,
    tle.arg_periapsis_rad,
    true_anomaly_from_eccentric(eccentric, tle.eccentricity),
  )
}

///|
pub struct Sgp4Status {
  available : Bool
  note : String
} derive(Debug, Eq)

///|
pub fn sgp4_status() -> Sgp4Status {
  {
    available: false,
    note: "TLE parsing and mean-element conversion are available; full SGP4 force model is intentionally reserved for a later compatible package.",
  }
}
