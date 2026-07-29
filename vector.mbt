///|
pub struct Vec3 {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub fn Vec3::new(x : Double, y : Double, z : Double) -> Vec3 {
  { x, y, z }
}

///|
pub fn Vec3::zero() -> Vec3 {
  { x: 0.0, y: 0.0, z: 0.0 }
}

///|
pub fn Vec3::add(a : Vec3, b : Vec3) -> Vec3 {
  { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z }
}

///|
pub fn Vec3::sub(a : Vec3, b : Vec3) -> Vec3 {
  { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z }
}

///|
pub fn Vec3::scale(v : Vec3, k : Double) -> Vec3 {
  { x: v.x * k, y: v.y * k, z: v.z * k }
}

///|
pub fn Vec3::dot(a : Vec3, b : Vec3) -> Double {
  a.x * b.x + a.y * b.y + a.z * b.z
}

///|
pub fn Vec3::cross(a : Vec3, b : Vec3) -> Vec3 {
  {
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  }
}

///|
pub fn Vec3::norm_squared(v : Vec3) -> Double {
  v.dot(v)
}

///|
pub fn Vec3::norm(v : Vec3) -> Double {
  v.norm_squared().sqrt()
}

///|
pub fn Vec3::unit(v : Vec3) -> Vec3 {
  let n = v.norm()
  if n == 0.0 {
    Vec3::zero()
  } else {
    v.scale(1.0 / n)
  }
}

///|
pub fn Vec3::distance(a : Vec3, b : Vec3) -> Double {
  a.sub(b).norm()
}

///|
pub fn Vec3::angle_between(a : Vec3, b : Vec3) -> Double {
  let denom = a.norm() * b.norm()
  if denom == 0.0 {
    0.0
  } else {
    @math.acos(clamp(a.dot(b) / denom, -1.0, 1.0))
  }
}

///|
pub fn Vec3::lerp(a : Vec3, b : Vec3, t : Double) -> Vec3 {
  a.scale(1.0 - t).add(b.scale(t))
}
