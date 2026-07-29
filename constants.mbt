///|
pub let pi : Double = 3.141592653589793

///|
pub let two_pi : Double = 6.283185307179586

///|
pub let half_pi : Double = 1.5707963267948966

///|
pub let deg_to_rad : Double = pi / 180.0

///|
pub let rad_to_deg : Double = 180.0 / pi

///|
pub let earth_mu_km3_s2 : Double = 398600.4418

///|
pub let earth_radius_km : Double = 6378.137

///|
pub let earth_rotation_rad_s : Double = 7.2921150e-5

///|
pub let j2 : Double = 1.08262668e-3

///|
pub fn radians(degrees : Double) -> Double {
  degrees * deg_to_rad
}

///|
pub fn degrees(radians : Double) -> Double {
  radians * rad_to_deg
}

///|
pub fn normalize_angle(theta : Double) -> Double {
  let wrapped = theta % two_pi
  if wrapped < 0.0 {
    wrapped + two_pi
  } else {
    wrapped
  }
}

///|
pub fn clamp(x : Double, low : Double, high : Double) -> Double {
  if x < low {
    low
  } else if x > high {
    high
  } else {
    x
  }
}

///|
pub fn nearly_equal(a : Double, b : Double, eps : Double) -> Bool {
  (a - b).abs() <= eps
}
