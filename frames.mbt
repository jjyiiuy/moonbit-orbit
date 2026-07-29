///|
pub struct Geodetic {
  latitude_rad : Double
  longitude_rad : Double
  altitude_km : Double
} derive(Debug, Eq)

///|
pub struct Topocentric {
  east_km : Double
  north_km : Double
  up_km : Double
} derive(Debug, Eq)

///|
pub struct LookAngle {
  azimuth_rad : Double
  elevation_rad : Double
  range_km : Double
} derive(Debug, Eq)

///|
pub fn Geodetic::new(latitude_rad : Double, longitude_rad : Double, altitude_km : Double) -> Geodetic {
  { latitude_rad, longitude_rad: normalize_angle(longitude_rad), altitude_km }
}

///|
pub fn geodetic_to_ecef(site : Geodetic) -> Vec3 {
  let r = earth_radius_km + site.altitude_km
  let cos_lat = @math.cos(site.latitude_rad)
  Vec3::new(
    r * cos_lat * @math.cos(site.longitude_rad),
    r * cos_lat * @math.sin(site.longitude_rad),
    r * @math.sin(site.latitude_rad),
  )
}

///|
pub fn ecef_to_geodetic_spherical(pos : Vec3) -> Geodetic {
  let r = pos.norm()
  let lat = @math.asin(clamp(pos.z / r, -1.0, 1.0))
  let lon = normalize_angle(@math.atan2(pos.y, pos.x))
  { latitude_rad: lat, longitude_rad: lon, altitude_km: r - earth_radius_km }
}

///|
pub fn rotate_z(v : Vec3, angle_rad : Double) -> Vec3 {
  let c = @math.cos(angle_rad)
  let s = @math.sin(angle_rad)
  Vec3::new(c * v.x - s * v.y, s * v.x + c * v.y, v.z)
}

///|
pub fn eci_to_ecef(epoch : Epoch, position_eci_km : Vec3) -> Vec3 {
  rotate_z(position_eci_km, -gmst(epoch))
}

///|
pub fn ecef_to_eci(epoch : Epoch, position_ecef_km : Vec3) -> Vec3 {
  rotate_z(position_ecef_km, gmst(epoch))
}

///|
pub fn topocentric(site : Geodetic, satellite_ecef_km : Vec3) -> Topocentric {
  let site_ecef = geodetic_to_ecef(site)
  let rho = satellite_ecef_km.sub(site_ecef)
  let sin_lat = @math.sin(site.latitude_rad)
  let cos_lat = @math.cos(site.latitude_rad)
  let sin_lon = @math.sin(site.longitude_rad)
  let cos_lon = @math.cos(site.longitude_rad)
  {
    east_km: -sin_lon * rho.x + cos_lon * rho.y,
    north_km: -sin_lat * cos_lon * rho.x - sin_lat * sin_lon * rho.y + cos_lat * rho.z,
    up_km: cos_lat * cos_lon * rho.x + cos_lat * sin_lon * rho.y + sin_lat * rho.z,
  }
}

///|
pub fn look_angle(site : Geodetic, satellite_ecef_km : Vec3) -> LookAngle {
  let topo = topocentric(site, satellite_ecef_km)
  let range = (topo.east_km * topo.east_km + topo.north_km * topo.north_km + topo.up_km * topo.up_km).sqrt()
  let az = normalize_angle(@math.atan2(topo.east_km, topo.north_km))
  let el = @math.asin(clamp(topo.up_km / range, -1.0, 1.0))
  { azimuth_rad: az, elevation_rad: el, range_km: range }
}

///|
pub fn look_angle_from_eci(site : Geodetic, epoch : Epoch, satellite_eci_km : Vec3) -> LookAngle {
  look_angle(site, eci_to_ecef(epoch, satellite_eci_km))
}
