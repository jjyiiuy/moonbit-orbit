///|
pub fn triangle_area(a : Vec3, b : Vec3, c : Vec3) -> Double {
  b.sub(a).cross(c.sub(a)).norm() / 2.0
}

///|
pub fn tetrahedron_volume(a : Vec3, b : Vec3, c : Vec3, d : Vec3) -> Double {
  b.sub(a).dot(c.sub(a).cross(d.sub(a))).abs() / 6.0
}

///|
pub fn line_point_distance(
  line_point : Vec3,
  line_direction : Vec3,
  point : Vec3,
) -> Double {
  reject_from(point.sub(line_point), line_direction).norm()
}

///|
pub fn segment_point_distance(start : Vec3, end : Vec3, point : Vec3) -> Double {
  let direction = end.sub(start)
  if direction.norm_squared() == 0.0 {
    point.distance(start)
  } else {
    let t = clamp(
      inverse_lerp(
        0.0,
        direction.norm_squared(),
        point.sub(start).dot(direction),
      ),
      0.0,
      1.0,
    )
    point.distance(start.add(direction.scale(t)))
  }
}

///|
pub fn closest_points_on_lines(
  p1 : Vec3,
  d1 : Vec3,
  p2 : Vec3,
  d2 : Vec3,
) -> (Vec3, Vec3) {
  let w = p1.sub(p2)
  let a = d1.dot(d1)
  let b = d1.dot(d2)
  let c = d2.dot(d2)
  let d = d1.dot(w)
  let e = d2.dot(w)
  let denominator = a * c - b * b
  if denominator.abs() < 1.0e-12 {
    (p1, p2)
  } else {
    let s = (b * e - c * d) / denominator
    let t = (a * e - b * d) / denominator
    (p1.add(d1.scale(s)), p2.add(d2.scale(t)))
  }
}

///|
pub fn great_circle_angle(a : Vec3, b : Vec3) -> Double {
  a.unit().angle_between(b.unit())
}

///|
pub fn great_circle_arc_length(radius : Double, a : Vec3, b : Vec3) -> Double {
  radius.abs() * great_circle_angle(a, b)
}

///|
pub fn spherical_triangle_excess(a : Vec3, b : Vec3, c : Vec3) -> Double {
  let ab = great_circle_angle(a, b)
  let bc = great_circle_angle(b, c)
  let ca = great_circle_angle(c, a)
  let semiperimeter = (ab + bc + ca) / 2.0
  let tangent = (@math.tan(semiperimeter / 2.0) *
    @math.tan((semiperimeter - ab) / 2.0) *
    @math.tan((semiperimeter - bc) / 2.0) *
    @math.tan((semiperimeter - ca) / 2.0))
    .abs()
    .sqrt()
  4.0 * @math.atan(tangent)
}

///|
pub fn rotate_about_axis(v : Vec3, axis : Vec3, angle_rad : Double) -> Vec3 {
  let unit = axis.unit()
  v
  .scale(@math.cos(angle_rad))
  .add(unit.cross(v).scale(@math.sin(angle_rad)))
  .add(unit.scale(unit.dot(v) * (1.0 - @math.cos(angle_rad))))
}

///|
pub fn orthogonal_basis(axis : Vec3) -> (Vec3, Vec3) {
  let n = axis.unit()
  let helper = if n.x.abs() < 0.8 {
    Vec3::new(1.0, 0.0, 0.0)
  } else {
    Vec3::new(0.0, 1.0, 0.0)
  }
  let first = n.cross(helper).unit()
  (first, n.cross(first).unit())
}

///|
pub fn project_to_plane(v : Vec3, normal : Vec3) -> Vec3 {
  reject_from(v, normal)
}

///|
pub fn signed_angle_about(a : Vec3, b : Vec3, axis : Vec3) -> Double {
  let angle = a.angle_between(b)
  if a.cross(b).dot(axis) < 0.0 {
    -angle
  } else {
    angle
  }
}

///|
pub fn interpolate_direction(a : Vec3, b : Vec3, t : Double) -> Vec3 {
  a.lerp(b, t).unit()
}

///|
pub fn bounding_box(points : Array[Vec3]) -> (Vec3, Vec3) {
  if points.length() == 0 {
    (Vec3::zero(), Vec3::zero())
  } else {
    let mut minimum = points[0]
    let mut maximum = points[0]
    for point in points {
      minimum = Vec3::new(
        minimum.x.min(point.x),
        minimum.y.min(point.y),
        minimum.z.min(point.z),
      )
      maximum = Vec3::new(
        maximum.x.max(point.x),
        maximum.y.max(point.y),
        maximum.z.max(point.z),
      )
    }
    (minimum, maximum)
  }
}

///|
pub fn bounding_box_center(points : Array[Vec3]) -> Vec3 {
  let box = bounding_box(points)
  box.0.add(box.1).scale(0.5)
}

///|
pub fn bounding_box_diagonal(points : Array[Vec3]) -> Double {
  let box = bounding_box(points)
  box.0.distance(box.1)
}

///|
pub fn centroid(points : Array[Vec3]) -> Vec3 {
  if points.length() == 0 {
    Vec3::zero()
  } else {
    points
    .fold(init=Vec3::zero(), (sum, point) => sum.add(point))
    .scale(1.0 / Double::from_int(points.length()))
  }
}
