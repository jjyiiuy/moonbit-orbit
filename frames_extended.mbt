///|
pub fn rotate_x(v : Vec3, angle_rad : Double) -> Vec3 {
  let c = @math.cos(angle_rad)
  let s = @math.sin(angle_rad)
  Vec3::new(v.x, c * v.y - s * v.z, s * v.y + c * v.z)
}

///|
pub fn rotate_y(v : Vec3, angle_rad : Double) -> Vec3 {
  let c = @math.cos(angle_rad)
  let s = @math.sin(angle_rad)
  Vec3::new(c * v.x + s * v.z, v.y, -s * v.x + c * v.z)
}

///|
pub fn rotate_xyz(
  v : Vec3,
  roll_rad : Double,
  pitch_rad : Double,
  yaw_rad : Double,
) -> Vec3 {
  rotate_z(rotate_y(rotate_x(v, roll_rad), pitch_rad), yaw_rad)
}

///|
pub fn project_onto(v : Vec3, axis : Vec3) -> Vec3 {
  let unit = axis.unit()
  unit.scale(v.dot(unit))
}

///|
pub fn reject_from(v : Vec3, axis : Vec3) -> Vec3 {
  v.sub(project_onto(v, axis))
}

///|
pub fn reflect(v : Vec3, normal : Vec3) -> Vec3 {
  v.sub(normal.unit().scale(2.0 * v.dot(normal.unit())))
}

///|
pub fn spherical_to_cartesian(
  radius : Double,
  latitude_rad : Double,
  longitude_rad : Double,
) -> Vec3 {
  Vec3::new(
    radius * @math.cos(latitude_rad) * @math.cos(longitude_rad),
    radius * @math.cos(latitude_rad) * @math.sin(longitude_rad),
    radius * @math.sin(latitude_rad),
  )
}

///|
pub fn cartesian_to_spherical(position : Vec3) -> (Double, Double, Double) {
  let radius = position.norm()
  if radius == 0.0 {
    (0.0, 0.0, 0.0)
  } else {
    (
      radius,
      @math.asin(clamp_unit(position.z / radius)),
      @math.atan2(position.y, position.x),
    )
  }
}

///|
pub fn radial_transverse_normal(
  position : Vec3,
  velocity : Vec3,
) -> (Vec3, Vec3, Vec3) {
  let radial = position.unit()
  let normal = position.cross(velocity).unit()
  let transverse = normal.cross(radial).unit()
  (radial, transverse, normal)
}

///|
pub fn perifocal_to_inertial(
  elements : ClassicalElements,
  vector : Vec3,
) -> Vec3 {
  let state = elements_to_state(1.0, { ..elements, true_anomaly_rad: 0.0 })
  let node = Vec3::new(
    @math.cos(elements.raan_rad),
    @math.sin(elements.raan_rad),
    0.0,
  )
  let _ = state
  rotate_z(
    rotate_x(
      rotate_z(vector, elements.arg_periapsis_rad),
      elements.inclination_rad,
    ),
    elements.raan_rad,
  ).add(node.scale(0.0))
}

///|
pub fn inertial_to_perifocal(
  elements : ClassicalElements,
  vector : Vec3,
) -> Vec3 {
  rotate_z(
    rotate_x(rotate_z(vector, -elements.raan_rad), -elements.inclination_rad),
    -elements.arg_periapsis_rad,
  )
}

///|
pub fn local_ned(site : Geodetic, target_ecef : Vec3) -> Vec3 {
  let enu = enu_coordinates(site, target_ecef)
  Vec3::new(enu.y, enu.x, -enu.z)
}

///|
pub fn horizon_mask_elevation(
  azimuth_rad : Double,
  mask_coefficients : Array[Double],
) -> Double {
  if mask_coefficients.length() == 0 {
    0.0
  } else {
    let x = normalize_angle(azimuth_rad)
    polynomial(mask_coefficients, x)
  }
}

///|
pub fn apply_horizon_mask(
  look : LookAngle,
  coefficients : Array[Double],
) -> Bool {
  look.elevation_rad >= horizon_mask_elevation(look.azimuth_rad, coefficients)
}

///|
pub fn line_of_sight(
  site_ecef : Vec3,
  target_ecef : Vec3,
  body_radius_km : Double,
) -> Bool {
  let midpoint = site_ecef.add(target_ecef).scale(0.5)
  let chord = site_ecef.distance(target_ecef)
  midpoint.norm() > body_radius_km || chord == 0.0
}

///|
pub fn azimuth_rate(
  previous : LookAngle,
  current : LookAngle,
  delta_t_s : Double,
) -> Double {
  if delta_t_s == 0.0 {
    0.0
  } else {
    longitude_difference_rad(previous.azimuth_rad, current.azimuth_rad) /
    delta_t_s
  }
}

///|
pub fn elevation_rate(
  previous : LookAngle,
  current : LookAngle,
  delta_t_s : Double,
) -> Double {
  if delta_t_s == 0.0 {
    0.0
  } else {
    (current.elevation_rad - previous.elevation_rad) / delta_t_s
  }
}
