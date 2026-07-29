///|
pub struct Epoch {
  seconds_since_j2000 : Double
} derive(Debug, Eq)

///|
pub fn Epoch::j2000() -> Epoch {
  { seconds_since_j2000: 0.0 }
}

///|
pub fn Epoch::from_seconds(seconds_since_j2000 : Double) -> Epoch {
  { seconds_since_j2000, }
}

///|
pub fn Epoch::from_days(days_since_j2000 : Double) -> Epoch {
  { seconds_since_j2000: days_since_j2000 * 86400.0 }
}

///|
pub fn Epoch::add_seconds(epoch : Epoch, seconds : Double) -> Epoch {
  { seconds_since_j2000: epoch.seconds_since_j2000 + seconds }
}

///|
pub fn Epoch::duration_to(a : Epoch, b : Epoch) -> Double {
  b.seconds_since_j2000 - a.seconds_since_j2000
}

///|
pub fn Epoch::days_since_j2000(epoch : Epoch) -> Double {
  epoch.seconds_since_j2000 / 86400.0
}

///|
pub fn gmst(epoch : Epoch) -> Double {
  normalize_angle(4.894961212823756 + earth_rotation_rad_s * epoch.seconds_since_j2000)
}
