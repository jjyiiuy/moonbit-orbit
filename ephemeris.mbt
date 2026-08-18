///|
pub struct SunPosition {
  position_eci_km : Vec3
  distance_au : Double
  right_ascension_rad : Double
  declination_rad : Double
} derive(Debug, Eq)

///|
pub struct MoonPosition {
  position_eci_km : Vec3
  distance_km : Double
  phase_angle_rad : Double
} derive(Debug, Eq)

///|
pub fn sun_position(epoch : Epoch) -> SunPosition {
  let days = epoch.days_since_j2000()
  let mean_longitude = radians(280.460 + 0.9856474 * days)
  let anomaly = radians(357.528 + 0.9856003 * days)
  let longitude = mean_longitude +
    radians(1.915) * @math.sin(anomaly) +
    radians(0.020) * @math.sin(2.0 * anomaly)
  let obliquity = radians(23.4393)
  let position = spherical_to_cartesian(SunEarthDistanceKm, 0.0, longitude)
  {
    position_eci_km: position,
    distance_au: 1.0,
    right_ascension_rad: @math.atan2(
      @math.cos(obliquity) * @math.sin(longitude),
      @math.cos(longitude),
    ),
    declination_rad: @math.asin(@math.sin(obliquity) * @math.sin(longitude)),
  }
}

///|
pub fn moon_position(epoch : Epoch) -> MoonPosition {
  let days = epoch.days_since_j2000()
  let longitude = radians(218.316 + 13.176396 * days)
  let position = spherical_to_cartesian(384400.0, 0.0, longitude)
  {
    position_eci_km: position,
    distance_km: position.norm(),
    phase_angle_rad: normalize_angle(
      longitude - sun_position(epoch).right_ascension_rad,
    ),
  }
}

///|
pub fn sun_altitude(site : Geodetic, epoch : Epoch) -> Double {
  let sun = sun_position(epoch)
  look_angle(site, eci_to_ecef(epoch, sun.position_eci_km)).elevation_rad
}

///|
pub fn moon_altitude(site : Geodetic, epoch : Epoch) -> Double {
  let moon = moon_position(epoch)
  look_angle(site, eci_to_ecef(epoch, moon.position_eci_km)).elevation_rad
}

///|
pub fn solar_declination(epoch : Epoch) -> Double {
  sun_position(epoch).declination_rad
}

///|
pub fn solar_hour_angle(site : Geodetic, epoch : Epoch) -> Double {
  normalize_angle(
    gmst(epoch) + site.longitude_rad - sun_position(epoch).right_ascension_rad,
  )
}

///|
pub fn approximate_sunrise(site : Geodetic, epoch : Epoch) -> Double {
  let hour = solar_hour_angle(site, epoch)
  (two_pi - hour) / two_pi * 86400.0
}

///|
pub fn approximate_sunset(site : Geodetic, epoch : Epoch) -> Double {
  approximate_sunrise(site, epoch) + 43200.0
}
