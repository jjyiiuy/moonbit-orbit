///|
pub struct Quaternion {
  w : Double
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub struct EulerAngles {
  roll_rad : Double
  pitch_rad : Double
  yaw_rad : Double
} derive(Debug, Eq)

///|
pub fn Quaternion::identity() -> Quaternion {
  { w: 1.0, x: 0.0, y: 0.0, z: 0.0 }
}

///|
pub fn Quaternion::new(
  w : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Quaternion {
  { w, x, y, z }
}

///|
pub fn Quaternion::from_axis_angle(
  axis : Vec3,
  angle_rad : Double,
) -> Quaternion {
  let u = axis.unit()
  let half = angle_rad / 2.0
  let s = @math.sin(half)
  { w: @math.cos(half), x: u.x * s, y: u.y * s, z: u.z * s }.normalized()
}

///|
pub fn Quaternion::norm_squared(q : Quaternion) -> Double {
  q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z
}

///|
pub fn Quaternion::norm(q : Quaternion) -> Double {
  q.norm_squared().sqrt()
}

///|
pub fn Quaternion::normalized(q : Quaternion) -> Quaternion {
  let n = q.norm()
  if n == 0.0 {
    Quaternion::identity()
  } else {
    { w: q.w / n, x: q.x / n, y: q.y / n, z: q.z / n }
  }
}

///|
pub fn Quaternion::conjugate(q : Quaternion) -> Quaternion {
  { w: q.w, x: -q.x, y: -q.y, z: -q.z }
}

///|
pub fn Quaternion::multiply(a : Quaternion, b : Quaternion) -> Quaternion {
  {
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
  }
}

///|
pub fn Quaternion::rotate(q : Quaternion, v : Vec3) -> Vec3 {
  let p = Quaternion::new(0.0, v.x, v.y, v.z)
  let r = q.normalized().multiply(p).multiply(q.normalized().conjugate())
  Vec3::new(r.x, r.y, r.z)
}

///|
pub fn Quaternion::from_euler(angles : EulerAngles) -> Quaternion {
  let cr = @math.cos(angles.roll_rad / 2.0)
  let sr = @math.sin(angles.roll_rad / 2.0)
  let cp = @math.cos(angles.pitch_rad / 2.0)
  let sp = @math.sin(angles.pitch_rad / 2.0)
  let cy = @math.cos(angles.yaw_rad / 2.0)
  let sy = @math.sin(angles.yaw_rad / 2.0)
  {
    w: cr * cp * cy + sr * sp * sy,
    x: sr * cp * cy - cr * sp * sy,
    y: cr * sp * cy + sr * cp * sy,
    z: cr * cp * sy - sr * sp * cy,
  }.normalized()
}

///|
pub fn Quaternion::to_euler(q : Quaternion) -> EulerAngles {
  let n = q.normalized()
  let sinr_cosp = 2.0 * (n.w * n.x + n.y * n.z)
  let cosr_cosp = 1.0 - 2.0 * (n.x * n.x + n.y * n.y)
  let sinp = 2.0 * (n.w * n.y - n.z * n.x)
  let pitch = if sinp.abs() >= 1.0 {
    sinp.signum() * half_pi
  } else {
    @math.asin(sinp)
  }
  let siny_cosp = 2.0 * (n.w * n.z + n.x * n.y)
  let cosy_cosp = 1.0 - 2.0 * (n.y * n.y + n.z * n.z)
  {
    roll_rad: @math.atan2(sinr_cosp, cosr_cosp),
    pitch_rad: pitch,
    yaw_rad: @math.atan2(siny_cosp, cosy_cosp),
  }
}
