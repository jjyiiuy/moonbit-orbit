///|
pub const Wgs84A : Double = 6378.137

///|
pub const Wgs84F : Double = 1.0 / 298.257223563

///|
pub const Wgs84B : Double = Wgs84A * (1.0 - Wgs84F)

///|
pub const Wgs84E2 : Double = Wgs84F * (2.0 - Wgs84F)

///|
pub struct LocalFrame {
  east : Vec3
  north : Vec3
  up : Vec3
} derive(Debug, Eq)

///|
pub fn geodetic_to_ecef_wgs84(site : Geodetic) -> Vec3 {
  let sin_lat = @math.sin(site.latitude_rad)
  let cos_lat = @math.cos(site.latitude_rad)
  let sin_lon = @math.sin(site.longitude_rad)
  let cos_lon = @math.cos(site.longitude_rad)
  let n = Wgs84A / (1.0 - Wgs84E2 * sin_lat * sin_lat).sqrt()
  Vec3::new(
    (n + site.altitude_km) * cos_lat * cos_lon,
    (n + site.altitude_km) * cos_lat * sin_lon,
    (n * (1.0 - Wgs84E2) + site.altitude_km) * sin_lat,
  )
}

///|
pub fn ecef_to_geodetic_wgs84(position : Vec3) -> Geodetic {
  let p = (position.x * position.x + position.y * position.y).sqrt()
  if p < 1.0e-12 {
    let latitude = if position.z >= 0.0 { half_pi } else { -half_pi }
    return Geodetic::new(latitude, 0.0, position.z.abs() - Wgs84B)
  }
  let longitude = @math.atan2(position.y, position.x)
  let mut latitude = @math.atan2(position.z, p * (1.0 - Wgs84E2))
  let mut altitude = 0.0
  for _ in 0..<12 {
    let sin_lat = @math.sin(latitude)
    let n = Wgs84A / (1.0 - Wgs84E2 * sin_lat * sin_lat).sqrt()
    altitude = p / @math.cos(latitude) - n
    let next = @math.atan2(position.z, p * (1.0 - Wgs84E2 * n / (n + altitude)))
    if (next - latitude).abs() < 1.0e-12 {
      latitude = next
      break
    }
    latitude = next
  }
  Geodetic::new(latitude, longitude, altitude)
}

///|
pub fn local_frame(site : Geodetic) -> LocalFrame {
  let sl = @math.sin(site.latitude_rad)
  let cl = @math.cos(site.latitude_rad)
  let so = @math.sin(site.longitude_rad)
  let co = @math.cos(site.longitude_rad)
  {
    east: Vec3::new(-so, co, 0.0),
    north: Vec3::new(-sl * co, -sl * so, cl),
    up: Vec3::new(cl * co, cl * so, sl),
  }
}

///|
pub fn geodesic_surface_distance_km(a : Geodetic, b : Geodetic) -> Double {
  let dlat = b.latitude_rad - a.latitude_rad
  let dlon = normalize_angle(b.longitude_rad - a.longitude_rad)
  let h = @math.sin(dlat / 2.0) * @math.sin(dlat / 2.0) +
    @math.cos(a.latitude_rad) *
    @math.cos(b.latitude_rad) *
    @math.sin(dlon / 2.0) *
    @math.sin(dlon / 2.0)
  2.0 * earth_radius_km * @math.asin(clamp(h.sqrt(), 0.0, 1.0))
}

///|
pub fn initial_bearing_rad(a : Geodetic, b : Geodetic) -> Double {
  let dlon = normalize_angle(b.longitude_rad - a.longitude_rad)
  normalize_angle(
    @math.atan2(
      @math.sin(dlon) * @math.cos(b.latitude_rad),
      @math.cos(a.latitude_rad) * @math.sin(b.latitude_rad) -
      @math.sin(a.latitude_rad) * @math.cos(b.latitude_rad) * @math.cos(dlon),
    ),
  )
}

///|
pub fn destination_point(
  start : Geodetic,
  bearing_rad : Double,
  distance_km : Double,
) -> Geodetic {
  let angular = distance_km / earth_radius_km
  let lat = @math.asin(
    clamp(
      @math.sin(start.latitude_rad) * @math.cos(angular) +
      @math.cos(start.latitude_rad) *
      @math.sin(angular) *
      @math.cos(bearing_rad),
      -1.0,
      1.0,
    ),
  )
  let lon = start.longitude_rad +
    @math.atan2(
      @math.sin(bearing_rad) *
      @math.sin(angular) *
      @math.cos(start.latitude_rad),
      @math.cos(angular) - @math.sin(start.latitude_rad) * @math.sin(lat),
    )
  Geodetic::new(lat, lon, start.altitude_km)
}

///|
pub fn enu_coordinates(site : Geodetic, target_ecef : Vec3) -> Vec3 {
  let frame = local_frame(site)
  let delta = target_ecef.sub(geodetic_to_ecef_wgs84(site))
  Vec3::new(delta.dot(frame.east), delta.dot(frame.north), delta.dot(frame.up))
}

///|
pub fn geodetic_height_above_ellipsoid(site : Geodetic) -> Double {
  site.altitude_km
}

///|
pub fn longitude_difference_rad(a : Double, b : Double) -> Double {
  normalize_angle(b - a)
}

///|
pub fn meridian_radius_km(latitude_rad : Double) -> Double {
  let s = @math.sin(latitude_rad)
  Wgs84A * (1.0 - Wgs84E2) / @math.pow(1.0 - Wgs84E2 * s * s, 1.5)
}

///|
pub fn prime_vertical_radius_km(latitude_rad : Double) -> Double {
  let s = @math.sin(latitude_rad)
  Wgs84A / (1.0 - Wgs84E2 * s * s).sqrt()
}

///|
pub fn local_gravity_m_s2(
  latitude_rad : Double,
  altitude_km : Double,
) -> Double {
  let sin_lat = @math.sin(latitude_rad)
  let sin2 = sin_lat * sin_lat
  let g0 = 9.7803253359 *
    (1.0 + 0.00193185265241 * sin2) /
    (1.0 - Wgs84E2 * sin2).sqrt()
  g0 - 3.086e-6 * altitude_km * 1000.0
}

///|
pub fn ecef_distance_km(a : Vec3, b : Vec3) -> Double {
  a.distance(b)
}
