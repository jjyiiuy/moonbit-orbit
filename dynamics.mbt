///|
pub struct AccelerationModel {
  central_body_mu : Double
  j2_enabled : Bool
  drag_enabled : Bool
  ballistic_coefficient : Double
  atmosphere_scale_height_km : Double
} derive(Debug, Eq)

///|
pub struct DynamicsState {
  state : StateVector
  acceleration_km_s2 : Vec3
  elapsed_s : Double
} derive(Debug, Eq)

///|
pub fn AccelerationModel::earth() -> AccelerationModel {
  {
    central_body_mu: earth_mu_km3_s2,
    j2_enabled: true,
    drag_enabled: false,
    ballistic_coefficient: 0.0,
    atmosphere_scale_height_km: 8.5,
  }
}

///|
pub fn AccelerationModel::vacuum(mu : Double) -> AccelerationModel {
  {
    central_body_mu: mu,
    j2_enabled: false,
    drag_enabled: false,
    ballistic_coefficient: 0.0,
    atmosphere_scale_height_km: 8.5,
  }
}

///|
pub fn AccelerationModel::with_drag(
  model : AccelerationModel,
  coefficient : Double,
  scale_height_km : Double,
) -> AccelerationModel {
  {
    ..model,
    drag_enabled: true,
    ballistic_coefficient: coefficient.max(0.0),
    atmosphere_scale_height_km: scale_height_km.max(0.1),
  }
}

///|
pub fn central_acceleration(mu : Double, position : Vec3) -> Vec3 {
  let r = position.norm()
  if r == 0.0 {
    Vec3::zero()
  } else {
    position.scale(-mu / (r * r * r))
  }
}

///|
pub fn j2_acceleration(
  mu : Double,
  radius_km : Double,
  coefficient : Double,
  position : Vec3,
) -> Vec3 {
  let r2 = position.norm_squared()
  let r = r2.sqrt()
  if r == 0.0 || radius_km <= 0.0 {
    Vec3::zero()
  } else {
    let z2 = position.z * position.z
    let factor = 1.5 *
      coefficient *
      mu *
      radius_km *
      radius_km /
      @math.pow(r, 5.0)
    Vec3::new(
      factor * position.x * (5.0 * z2 / r2 - 1.0),
      factor * position.y * (5.0 * z2 / r2 - 1.0),
      factor * position.z * (5.0 * z2 / r2 - 3.0),
    )
  }
}

///|
pub fn exponential_density_kg_m3(
  altitude_km : Double,
  scale_height_km : Double,
) -> Double {
  if scale_height_km <= 0.0 {
    0.0
  } else {
    1.225 * @math.exp(-altitude_km.max(0.0) / scale_height_km)
  }
}

///|
pub fn drag_acceleration(
  model : AccelerationModel,
  position : Vec3,
  velocity : Vec3,
) -> Vec3 {
  if !model.drag_enabled || model.ballistic_coefficient <= 0.0 {
    Vec3::zero()
  } else {
    let altitude = position.norm() - earth_radius_km
    let density = exponential_density_kg_m3(
      altitude,
      model.atmosphere_scale_height_km,
    )
    let speed = velocity.norm()
    if speed == 0.0 {
      Vec3::zero()
    } else {
      velocity.scale(-0.5 * density * model.ballistic_coefficient * speed)
    }
  }
}

///|
pub fn acceleration(model : AccelerationModel, state : StateVector) -> Vec3 {
  let central = central_acceleration(model.central_body_mu, state.position_km)
  let correction = if model.j2_enabled {
    j2_acceleration(
      model.central_body_mu,
      earth_radius_km,
      j2,
      state.position_km,
    )
  } else {
    Vec3::zero()
  }
  central
  .add(correction)
  .add(drag_acceleration(model, state.position_km, state.velocity_km_s))
}

///|
pub fn rk4_step(
  model : AccelerationModel,
  state : StateVector,
  step_s : Double,
) -> StateVector {
  if step_s == 0.0 {
    return state
  }
  let a1 = acceleration(model, state)
  let s2 = StateVector::new(
    state.position_km.add(state.velocity_km_s.scale(step_s / 2.0)),
    state.velocity_km_s.add(a1.scale(step_s / 2.0)),
  )
  let a2 = acceleration(model, s2)
  let s3 = StateVector::new(
    state.position_km.add(s2.velocity_km_s.scale(step_s / 2.0)),
    state.velocity_km_s.add(a2.scale(step_s / 2.0)),
  )
  let a3 = acceleration(model, s3)
  let s4 = StateVector::new(
    state.position_km.add(s3.velocity_km_s.scale(step_s)),
    state.velocity_km_s.add(a3.scale(step_s)),
  )
  let a4 = acceleration(model, s4)
  let velocity = state.velocity_km_s.add(
    a1.add(a2.scale(2.0)).add(a3.scale(2.0)).add(a4).scale(step_s / 6.0),
  )
  let position = state.position_km.add(
    state.velocity_km_s
    .add(s2.velocity_km_s.scale(2.0))
    .add(s3.velocity_km_s.scale(2.0))
    .add(s4.velocity_km_s)
    .scale(step_s / 6.0),
  )
  StateVector::new(position, velocity)
}

///|
pub fn integrate_dynamics(
  model : AccelerationModel,
  initial : StateVector,
  duration_s : Double,
  step_s : Double,
) -> Array[DynamicsState] {
  let result : Array[DynamicsState] = []
  if duration_s < 0.0 || step_s <= 0.0 {
    return result
  }
  let mut state = initial
  let mut elapsed = 0.0
  while elapsed <= duration_s {
    result.push({
      state,
      acceleration_km_s2: acceleration(model, state),
      elapsed_s: elapsed,
    })
    state = rk4_step(model, state, step_s)
    elapsed += step_s
  }
  result
}

///|
pub fn specific_angular_momentum(state : StateVector) -> Vec3 {
  state.position_km.cross(state.velocity_km_s)
}

///|
pub fn flight_path_angle(state : StateVector) -> Double {
  let speed = state.velocity_km_s.norm()
  let radius = state.position_km.norm()
  if speed == 0.0 || radius == 0.0 {
    0.0
  } else {
    @math.asin(
      clamp_unit(state.position_km.dot(state.velocity_km_s) / (speed * radius)),
    )
  }
}

///|
pub fn radial_velocity(state : StateVector) -> Double {
  let radius = state.position_km.norm()
  if radius == 0.0 {
    0.0
  } else {
    state.position_km.dot(state.velocity_km_s) / radius
  }
}

///|
pub fn transverse_velocity(state : StateVector) -> Double {
  let speed2 = state.velocity_km_s.norm_squared()
  let radial = radial_velocity(state)
  (speed2 - radial * radial).max(0.0).sqrt()
}

///|
pub fn vis_viva_velocity(
  mu : Double,
  radius_km : Double,
  semi_major_axis_km : Double,
) -> Double {
  if radius_km <= 0.0 || semi_major_axis_km == 0.0 {
    0.0
  } else {
    (mu * (2.0 / radius_km - 1.0 / semi_major_axis_km)).max(0.0).sqrt()
  }
}

///|
pub fn escape_velocity(mu : Double, radius_km : Double) -> Double {
  if radius_km <= 0.0 {
    0.0
  } else {
    (2.0 * mu / radius_km).sqrt()
  }
}

///|
pub fn orbit_state_energy(mu : Double, state : StateVector) -> Double {
  0.5 * state.velocity_km_s.norm_squared() - mu / state.position_km.norm()
}

///|
pub fn orbit_state_angular_momentum(state : StateVector) -> Double {
  specific_angular_momentum(state).norm()
}

///|
pub fn state_after_impulse(state : StateVector, delta_v : Vec3) -> StateVector {
  StateVector::new(state.position_km, state.velocity_km_s.add(delta_v))
}

///|
pub fn impulse_magnitude(delta_v : Vec3) -> Double {
  delta_v.norm()
}
