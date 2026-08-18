///|
pub struct ControlCommand {
  axis : Vec3
  angle_rad : Double
  duration_s : Double
  torque_nm : Vec3
} derive(Debug, Eq)

///|
pub struct PointingTarget {
  direction : Vec3
  roll_rad : Double
  tolerance_rad : Double
} derive(Debug, Eq)

///|
pub fn make_pointing_target(
  direction : Vec3,
  roll_rad : Double,
  tolerance_rad : Double,
) -> PointingTarget {
  { direction: direction.unit(), roll_rad, tolerance_rad: tolerance_rad.abs() }
}

///|
pub fn pointing_error(
  attitude : Quaternion,
  target : PointingTarget,
  body_axis : Vec3,
) -> Double {
  attitude.rotate(body_axis).angle_between(target.direction)
}

///|
pub fn control_command(
  attitude : Quaternion,
  target : PointingTarget,
  body_axis : Vec3,
  max_rate_rad_s : Double,
) -> ControlCommand {
  let error_axis = attitude.rotate(body_axis).cross(target.direction).unit()
  let error = pointing_error(attitude, target, body_axis)
  let duration = if max_rate_rad_s <= 0.0 {
    0.0
  } else {
    error / max_rate_rad_s
  }
  {
    axis: error_axis,
    angle_rad: error,
    duration_s: duration,
    torque_nm: error_axis.scale(error),
  }
}

///|
pub fn command_is_within_tolerance(
  command : ControlCommand,
  tolerance_rad : Double,
) -> Bool {
  command.angle_rad <= tolerance_rad.abs()
}

///|
pub fn slew_time(
  angle_rad : Double,
  max_rate_rad_s : Double,
  max_accel_rad_s2 : Double,
) -> Double {
  if angle_rad <= 0.0 || max_rate_rad_s <= 0.0 || max_accel_rad_s2 <= 0.0 {
    0.0
  } else {
    let acceleration_time = max_rate_rad_s / max_accel_rad_s2
    let acceleration_angle = max_accel_rad_s2 *
      acceleration_time *
      acceleration_time
    if angle_rad < acceleration_angle {
      2.0 * (angle_rad / max_accel_rad_s2).sqrt()
    } else {
      2.0 * acceleration_time +
      (angle_rad - acceleration_angle) / max_rate_rad_s
    }
  }
}

///|
pub fn reaction_wheel_momentum(inertia : Vec3, angular_velocity : Vec3) -> Vec3 {
  Vec3::new(
    inertia.x * angular_velocity.x,
    inertia.y * angular_velocity.y,
    inertia.z * angular_velocity.z,
  )
}

///|
pub fn desaturation_delta_v(
  momentum : Vec3,
  wheel_inertia : Vec3,
  thruster_arm_km : Vec3,
) -> Vec3 {
  Vec3::new(
    if thruster_arm_km.x == 0.0 {
      0.0
    } else {
      -momentum.x / thruster_arm_km.x / wheel_inertia.x.max(1.0e-9)
    },
    if thruster_arm_km.y == 0.0 {
      0.0
    } else {
      -momentum.y / thruster_arm_km.y / wheel_inertia.y.max(1.0e-9)
    },
    if thruster_arm_km.z == 0.0 {
      0.0
    } else {
      -momentum.z / thruster_arm_km.z / wheel_inertia.z.max(1.0e-9)
    },
  )
}

///|
pub fn quaternion_command_error(
  desired : Quaternion,
  current : Quaternion,
) -> Vec3 {
  let error = attitude_error(desired, current)
  Vec3::new(error.x, error.y, error.z).scale(2.0)
}

///|
pub fn body_rate_limit(rate : Vec3, limit_rad_s : Double) -> Vec3 {
  let maximum = limit_rad_s.abs()
  Vec3::new(
    clamp(rate.x, -maximum, maximum),
    clamp(rate.y, -maximum, maximum),
    clamp(rate.z, -maximum, maximum),
  )
}

///|
pub fn torque_from_rate_error(
  inertia : Vec3,
  desired : Vec3,
  actual : Vec3,
  gain : Double,
) -> Vec3 {
  let error = desired.sub(actual)
  Vec3::new(
    inertia.x * error.x * gain,
    inertia.y * error.y * gain,
    inertia.z * error.z * gain,
  )
}
