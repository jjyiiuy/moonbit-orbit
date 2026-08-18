///|
pub struct OptimizationResult {
  parameters : Array[Double]
  objective : Double
  iterations : Int
  converged : Bool
} derive(Debug, Eq)

///|
pub fn finite_difference_gradient(
  objective : (Array[Double]) -> Double,
  parameters : Array[Double],
  step : Double,
) -> Array[Double] {
  let gradient : Array[Double] = []
  for i in 0..<parameters.length() {
    let plus = parameters.copy()
    let minus = parameters.copy()
    plus[i] += step
    minus[i] -= step
    gradient.push((objective(plus) - objective(minus)) / (2.0 * step))
  }
  gradient
}

///|
pub fn gradient_descent(
  objective : (Array[Double]) -> Double,
  initial : Array[Double],
  learning_rate : Double,
  iterations : Int,
) -> OptimizationResult {
  let parameters = initial.copy()
  let mut completed = 0
  for _ in 0..<iterations.max(0) {
    let gradient = finite_difference_gradient(objective, parameters, 1.0e-6)
    for i in 0..<parameters.length() {
      parameters[i] -= learning_rate * gradient[i]
    }
    completed += 1
    if gradient.fold(init=0.0, (sum, value) => sum + value * value).sqrt() <
      1.0e-8 {
      break
    }
  }
  {
    parameters,
    objective: objective(parameters),
    iterations: completed,
    converged: completed < iterations.max(0) || iterations <= 0,
  }
}

///|
pub fn grid_search_1d(
  objective : (Double) -> Double,
  lower : Double,
  upper : Double,
  samples : Int,
) -> (Double, Double) {
  let mut best_x = lower
  let mut best_value = objective(lower)
  for i in 0..<samples.max(1) {
    let x = lerp_scalar(
      lower,
      upper,
      Double::from_int(i) / Double::from_int(samples.max(1) - 1).max(1.0),
    )
    let value = objective(x)
    if value < best_value {
      best_x = x
      best_value = value
    }
  }
  (best_x, best_value)
}

///|
pub fn weighted_objective(
  values : Array[Double],
  weights : Array[Double],
  target : Double,
) -> Double {
  if values.length() != weights.length() {
    1.0e30
  } else {
    let normalized = normalize_weights(weights)
    let mut total = 0.0
    for i in 0..<values.length() {
      let error = values[i] - target
      total += normalized[i] * error * error
    }
    total
  }
}

///|
pub fn minimize_delta_v(mu : Double, radii : Array[Double]) -> (Double, Double) {
  if radii.length() < 2 {
    (0.0, 0.0)
  } else {
    let mut best = radii[0]
    let mut cost = 1.0e30
    for radius in radii {
      let value = circular_speed(mu, radius)
      if value < cost {
        cost = value
        best = radius
      }
    }
    (best, cost)
  }
}

///|
pub fn pareto_front(
  values : Array[(Double, Double)],
) -> Array[(Double, Double)] {
  let result : Array[(Double, Double)] = []
  for candidate in values {
    let dominated = values.any(other => {
      other.0 <= candidate.0 &&
      other.1 <= candidate.1 &&
      (other.0 < candidate.0 || other.1 < candidate.1)
    })
    if !dominated {
      result.push(candidate)
    }
  }
  result
}

///|
pub fn normalize_parameter(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  clamp(inverse_lerp(lower, upper, value), 0.0, 1.0)
}

///|
pub fn denormalize_parameter(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  lerp_scalar(lower, upper, clamp(value, 0.0, 1.0))
}

///|
pub fn objective_orbit_altitude(
  mu : Double,
  elements : ClassicalElements,
  target_altitude_km : Double,
) -> Double {
  let actual = elements.semi_major_axis_km - earth_radius_km
  (actual - target_altitude_km).abs() +
  elements.eccentricity * 100.0 +
  orbital_period(mu, elements.semi_major_axis_km) * 1.0e-5
}

///|
pub fn select_best_candidate(
  candidates : Array[DesignCandidate],
) -> DesignCandidate? {
  let feasible = feasible_designs(candidates)
  let ranked = rank_designs(feasible)
  if ranked.length() == 0 {
    None
  } else {
    Some(ranked[0])
  }
}
