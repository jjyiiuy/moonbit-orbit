///|
pub struct LambertSolution {
  departure_velocity_km_s : Vec3
  arrival_velocity_km_s : Vec3
  transfer_angle_rad : Double
  time_of_flight_s : Double
  iterations : Int
  status : SolveStatus
} derive(Debug, Eq)

///|
fn stumpff_c(z : Double) -> Double {
  if z > 1.0e-8 {
    (1.0 - @math.cos(z.sqrt())) / z
  } else if z < -1.0e-8 {
    (@math.cosh((-z).sqrt()) - 1.0) / -z
  } else {
    0.5
  }
}

///|
fn stumpff_s(z : Double) -> Double {
  if z > 1.0e-8 {
    (z.sqrt() - @math.sin(z.sqrt())) / (z * z.sqrt())
  } else if z < -1.0e-8 {
    (@math.sinh((-z).sqrt()) - (-z).sqrt()) / (-z * (-z).sqrt())
  } else {
    1.0 / 6.0
  }
}

///|
pub fn transfer_angle(r1 : Vec3, r2 : Vec3, prograde? : Bool = true) -> Double {
  let base = r1.angle_between(r2)
  let cross_z = r1.cross(r2).z
  if prograde && cross_z < 0.0 {
    two_pi - base
  } else if !prograde && cross_z >= 0.0 {
    two_pi - base
  } else {
    base
  }
}

///|
pub fn lambert_universal(
  mu : Double,
  start : Vec3,
  end : Vec3,
  time_of_flight_s : Double,
  prograde? : Bool = true,
  max_iterations? : Int = 64,
) -> LambertSolution {
  let r1 = start.norm()
  let r2 = end.norm()
  let theta = transfer_angle(start, end, prograde~)
  if mu <= 0.0 ||
    r1 == 0.0 ||
    r2 == 0.0 ||
    time_of_flight_s <= 0.0 ||
    theta == 0.0 {
    return {
      departure_velocity_km_s: Vec3::zero(),
      arrival_velocity_km_s: Vec3::zero(),
      transfer_angle_rad: theta,
      time_of_flight_s,
      iterations: 0,
      status: InvalidInput,
    }
  }
  let a = @math.sin(theta) * (r1 * r2 / (1.0 - @math.cos(theta))).sqrt()
  if a.abs() < 1.0e-12 {
    return {
      departure_velocity_km_s: Vec3::zero(),
      arrival_velocity_km_s: Vec3::zero(),
      transfer_angle_rad: theta,
      time_of_flight_s,
      iterations: 0,
      status: InvalidInput,
    }
  }
  let mut z = 0.0
  let mut converged = false
  let mut y = 0.0
  for _ in 0..<max_iterations {
    let c = stumpff_c(z)
    let s = stumpff_s(z)
    y = r1 + r2 + a * (z * s - 1.0) / c.sqrt()
    if y < 0.0 {
      z += 0.1
      continue
    }
    let x = (y / c).sqrt()
    let estimate = (x * x * x * s + a * y.sqrt()) / mu.sqrt()
    if (estimate - time_of_flight_s).abs() < 1.0e-8 {
      converged = true
      break
    }
    if estimate < time_of_flight_s {
      z += 0.1
    } else {
      z -= 0.1
    }
  }
  let f = 1.0 - y / r1
  let g = a * (y / mu).sqrt()
  let gdot = 1.0 - y / r2
  if g.abs() < 1.0e-12 {
    return {
      departure_velocity_km_s: Vec3::zero(),
      arrival_velocity_km_s: Vec3::zero(),
      transfer_angle_rad: theta,
      time_of_flight_s,
      iterations: max_iterations,
      status: InvalidInput,
    }
  }
  let v1 = end.sub(start.scale(f)).scale(1.0 / g)
  let v2 = end.scale(gdot).sub(start).scale(1.0 / g)
  {
    departure_velocity_km_s: v1,
    arrival_velocity_km_s: v2,
    transfer_angle_rad: theta,
    time_of_flight_s,
    iterations: max_iterations,
    status: if converged {
      Converged
    } else {
      MaxIterations
    },
  }
}

///|
pub fn lambert_delta_v(
  solution : LambertSolution,
  initial_velocity : Vec3,
  final_velocity : Vec3,
) -> (Double, Double, Double) {
  let departure = solution.departure_velocity_km_s.distance(initial_velocity)
  let arrival = final_velocity.distance(solution.arrival_velocity_km_s)
  (departure, arrival, departure + arrival)
}

///|
pub fn hohmann_like_lambert(
  mu : Double,
  start : Vec3,
  end : Vec3,
  time_of_flight_s : Double,
) -> LambertSolution {
  lambert_universal(mu, start, end, time_of_flight_s)
}

///|
pub fn transfer_plane_normal(start : Vec3, end : Vec3) -> Vec3 {
  start.cross(end).unit()
}

///|
pub fn transfer_is_prograde(start : Vec3, end : Vec3, reference : Vec3) -> Bool {
  start.cross(end).dot(reference) >= 0.0
}
