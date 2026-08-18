///|
pub struct AttitudeState {
  attitude : Quaternion
  angular_velocity_rad_s : Vec3
  covariance_trace : Double
} derive(Debug, Eq)

///|
pub fn AttitudeState::new(
  attitude : Quaternion,
  angular_velocity_rad_s : Vec3,
) -> AttitudeState {
  { attitude, angular_velocity_rad_s, covariance_trace: 0.0 }
}

///|
pub fn attitude_propagate(
  state : AttitudeState,
  delta_t_s : Double,
) -> AttitudeState {
  let rate = state.angular_velocity_rad_s.norm()
  if rate == 0.0 || delta_t_s == 0.0 {
    state
  } else {
    {
      ..state,
      attitude: state.attitude.multiply(
        Quaternion::from_axis_angle(
          state.angular_velocity_rad_s,
          rate * delta_t_s,
        ),
      ),
    }
  }
}

///|
pub fn attitude_error(desired : Quaternion, actual : Quaternion) -> Quaternion {
  desired.multiply(actual.conjugate())
}

///|
pub fn quaternion_distance(a : Quaternion, b : Quaternion) -> Double {
  2.0 *
  @math.acos(
    clamp((a.w * b.w + a.x * b.x + a.y * b.y + a.z * b.z).abs(), -1.0, 1.0),
  )
}

///|
pub fn quaternion_slerp(
  a : Quaternion,
  b : Quaternion,
  t : Double,
) -> Quaternion {
  let mut target = b
  let mut cosine = a.w * b.w + a.x * b.x + a.y * b.y + a.z * b.z
  if cosine < 0.0 {
    target = Quaternion::new(-b.w, -b.x, -b.y, -b.z)
    cosine = -cosine
  }
  if cosine > 0.9995 {
    return Quaternion::new(
      a.w + (target.w - a.w) * t,
      a.x + (target.x - a.x) * t,
      a.y + (target.y - a.y) * t,
      a.z + (target.z - a.z) * t,
    ).normalized()
  }
  let angle = @math.acos(clamp(cosine, -1.0, 1.0))
  let sin_angle = @math.sin(angle)
  let u = @math.sin((1.0 - t) * angle) / sin_angle
  let v = @math.sin(t * angle) / sin_angle
  Quaternion::new(
    a.w * u + target.w * v,
    a.x * u + target.x * v,
    a.y * u + target.y * v,
    a.z * u + target.z * v,
  )
}

///|
pub fn quaternion_to_euler(q : Quaternion) -> EulerAngles {
  q.to_euler()
}

///|
pub fn euler_to_quaternion(euler : EulerAngles) -> Quaternion {
  Quaternion::from_euler(euler)
}

///|
pub fn rotate_body_to_inertial(attitude : Quaternion, body : Vec3) -> Vec3 {
  attitude.rotate(body)
}

///|
pub fn rotate_inertial_to_body(attitude : Quaternion, inertial : Vec3) -> Vec3 {
  attitude.conjugate().rotate(inertial)
}

///|
pub fn angular_momentum(
  attitude : AttitudeState,
  inertia_diagonal : Vec3,
) -> Vec3 {
  Vec3::new(
    inertia_diagonal.x * attitude.angular_velocity_rad_s.x,
    inertia_diagonal.y * attitude.angular_velocity_rad_s.y,
    inertia_diagonal.z * attitude.angular_velocity_rad_s.z,
  )
}

///|
pub fn kinetic_rotation_energy(
  attitude : AttitudeState,
  inertia_diagonal : Vec3,
) -> Double {
  0.5 *
  attitude.angular_velocity_rad_s.dot(
    angular_momentum(attitude, inertia_diagonal),
  )
}
