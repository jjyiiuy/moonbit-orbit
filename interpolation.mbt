///|
pub fn interpolate_array(
  xs : Array[Double],
  ys : Array[Double],
  query : Double,
) -> Double {
  if xs.length() == 0 || xs.length() != ys.length() {
    0.0
  } else if query <= xs[0] {
    ys[0]
  } else if query >= xs[xs.length() - 1] {
    ys[ys.length() - 1]
  } else {
    let mut value = ys[0]
    for i in 0..<(xs.length() - 1) {
      if query >= xs[i] && query <= xs[i + 1] {
        value = lerp_scalar(
          ys[i],
          ys[i + 1],
          inverse_lerp(xs[i], xs[i + 1], query),
        )
        break
      }
    }
    value
  }
}

///|
pub fn interpolate_angle(
  xs : Array[Double],
  ys : Array[Double],
  query : Double,
) -> Double {
  normalize_angle(interpolate_array(xs, ys.map(normalize_angle), query))
}

///|
pub fn nearest_index(values : Array[Double], query : Double) -> Int {
  if values.length() == 0 {
    -1
  } else {
    let mut index = 0
    let mut distance = (values[0] - query).abs()
    for i in 1..<values.length() {
      if (values[i] - query).abs() < distance {
        index = i
        distance = (values[i] - query).abs()
      }
    }
    index
  }
}

///|
pub fn nearest_value(values : Array[Double], query : Double) -> Double {
  let index = nearest_index(values, query)
  if index < 0 {
    0.0
  } else {
    values[index]
  }
}

///|
pub fn resample_uniform(
  values : Array[Double],
  start : Double,
  step : Double,
  count : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let xs : Array[Double] = []
  for i in 0..<values.length() {
    xs.push(Double::from_int(i))
  }
  for i in 0..<count.max(0) {
    result.push(start + step * Double::from_int(i))
  }
  result.map(query => interpolate_array(xs, values, query))
}

///|
pub fn finite_difference(
  values : Array[Double],
  spacing : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if spacing == 0.0 {
    return result
  }
  for i in 0..<values.length() {
    if i == 0 {
      result.push((values[1] - values[0]) / spacing)
    } else if i == values.length() - 1 {
      result.push((values[i] - values[i - 1]) / spacing)
    } else {
      result.push((values[i + 1] - values[i - 1]) / (2.0 * spacing))
    }
  }
  result
}

///|
pub fn second_difference(
  values : Array[Double],
  spacing : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() < 3 || spacing == 0.0 {
    return result
  }
  for i in 1..<(values.length() - 1) {
    result.push(
      (values[i + 1] - 2.0 * values[i] + values[i - 1]) / (spacing * spacing),
    )
  }
  result
}

///|
pub fn integrate_uniform(values : Array[Double], spacing : Double) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for i in 0..<(values.length() - 1) {
      total += (values[i] + values[i + 1]) * spacing / 2.0
    }
    total
  }
}

///|
pub fn integrate_simpson(values : Array[Double], spacing : Double) -> Double {
  if values.length() < 3 || values.length() % 2 == 0 {
    integrate_uniform(values, spacing)
  } else {
    let mut total = values[0] + values[values.length() - 1]
    for i in 1..<(values.length() - 1) {
      total += if i % 2 == 0 { 2.0 * values[i] } else { 4.0 * values[i] }
    }
    total * spacing / 3.0
  }
}

///|
pub fn polynomial_fit_linear(
  xs : Array[Double],
  ys : Array[Double],
) -> (Double, Double) {
  let model = linear_regression(xs, ys)
  (model.slope, model.intercept)
}

///|
pub fn predict_linear(model : (Double, Double), x : Double) -> Double {
  model.0 * x + model.1
}

///|
pub fn residuals_linear(
  model : (Double, Double),
  xs : Array[Double],
  ys : Array[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<xs.length().min(ys.length()) {
    result.push(ys[i] - predict_linear(model, xs[i]))
  }
  result
}

///|
pub fn smooth_box(values : Array[Double], radius : Int) -> Array[Double] {
  moving_average(values, radius * 2 + 1)
}

///|
pub fn smooth_exponential(
  values : Array[Double],
  alpha : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() == 0 {
    return result
  }
  let weight = clamp(alpha, 0.0, 1.0)
  let mut previous = values[0]
  for value in values {
    previous = weight * value + (1.0 - weight) * previous
    result.push(previous)
  }
  result
}
