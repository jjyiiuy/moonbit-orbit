///|
pub enum SolveStatus {
  Converged
  MaxIterations
  InvalidInput
} derive(Debug, Eq)

///|
pub struct RootResult {
  value : Double
  residual : Double
  iterations : Int
  status : SolveStatus
} derive(Debug, Eq)

///|
pub struct SampleStats {
  count : Int
  minimum : Double
  maximum : Double
  mean : Double
  variance : Double
  sum : Double
} derive(Debug, Eq)

///|
pub fn finite_or(value : Double, fallback : Double) -> Double {
  if value.is_nan() || value.is_inf() {
    fallback
  } else {
    value
  }
}

///|
pub fn clamp_unit(value : Double) -> Double {
  clamp(value, -1.0, 1.0)
}

///|
pub fn wrap_positive(value : Double, period : Double) -> Double {
  if period <= 0.0 {
    value
  } else {
    let mut result = value % period
    if result < 0.0 {
      result += period
    }
    result
  }
}

///|
pub fn lerp_scalar(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

///|
pub fn inverse_lerp(a : Double, b : Double, value : Double) -> Double {
  if a == b {
    0.0
  } else {
    (value - a) / (b - a)
  }
}

///|
pub fn smooth_step(edge0 : Double, edge1 : Double, value : Double) -> Double {
  let t = clamp(inverse_lerp(edge0, edge1, value), 0.0, 1.0)
  t * t * (3.0 - 2.0 * t)
}

///|
pub fn mean(values : Array[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    values.fold(init=0.0, (sum, value) => sum + value) /
    Double::from_int(values.length())
  }
}

///|
pub fn variance(values : Array[Double]) -> Double {
  if values.length() < 2 {
    0.0
  } else {
    let average = mean(values)
    values.fold(init=0.0, (sum, value) => {
      sum + (value - average) * (value - average)
    }) /
    Double::from_int(values.length() - 1)
  }
}

///|
pub fn summarize_samples(values : Array[Double]) -> SampleStats {
  if values.length() == 0 {
    { count: 0, minimum: 0.0, maximum: 0.0, mean: 0.0, variance: 0.0, sum: 0.0 }
  } else {
    let mut minimum = values[0]
    let mut maximum = values[0]
    let mut sum = 0.0
    for value in values {
      if value < minimum {
        minimum = value
      }
      if value > maximum {
        maximum = value
      }
      sum += value
    }
    {
      count: values.length(),
      minimum,
      maximum,
      mean: sum / Double::from_int(values.length()),
      variance: variance(values),
      sum,
    }
  }
}

///|
pub fn integrate_trapezoid(xs : Array[Double], ys : Array[Double]) -> Double {
  if xs.length() != ys.length() || xs.length() < 2 {
    0.0
  } else {
    let mut total = 0.0
    for i in 0..<(xs.length() - 1) {
      total += (xs[i + 1] - xs[i]) * (ys[i] + ys[i + 1]) / 2.0
    }
    total
  }
}

///|
pub fn find_bracket(
  f : (Double) -> Double,
  start : Double,
  end : Double,
  samples? : Int = 32,
) -> (Double, Double)? {
  if samples < 1 || start == end {
    None
  } else {
    let step = (end - start) / Double::from_int(samples)
    let mut left = start
    let mut left_value = f(left)
    let mut result : (Double, Double)? = None
    for _ in 0..<samples {
      let right = left + step
      let right_value = f(right)
      if result is None &&
        (
          left_value == 0.0 ||
          right_value == 0.0 ||
          left_value * right_value < 0.0
        ) {
        result = Some((left, right))
      }
      left = right
      left_value = right_value
    }
    result
  }
}

///|
pub fn bisect(
  f : (Double) -> Double,
  lower : Double,
  upper : Double,
  tolerance? : Double = 1.0e-10,
  max_iterations? : Int = 64,
) -> RootResult {
  let mut lo = lower
  let mut hi = upper
  let mut flo = f(lo)
  let fhi = f(hi)
  if flo.is_nan() || fhi.is_nan() || flo * fhi > 0.0 {
    return { value: lower, residual: flo, iterations: 0, status: InvalidInput }
  }
  for iteration in 0..<max_iterations {
    let mid = (lo + hi) / 2.0
    let fmid = f(mid)
    if fmid.abs() <= tolerance || (hi - lo).abs() <= tolerance {
      return {
        value: mid,
        residual: fmid,
        iterations: iteration + 1,
        status: Converged,
      }
    }
    if flo * fmid <= 0.0 {
      hi = mid
    } else {
      lo = mid
      flo = fmid
    }
  }
  let value = (lo + hi) / 2.0
  {
    value,
    residual: f(value),
    iterations: max_iterations,
    status: MaxIterations,
  }
}

///|
pub fn newton(
  f : (Double) -> Double,
  derivative : (Double) -> Double,
  initial : Double,
  tolerance? : Double = 1.0e-10,
  max_iterations? : Int = 32,
) -> RootResult {
  let mut x = initial
  for iteration in 0..<max_iterations {
    let fx = f(x)
    let slope = derivative(x)
    if fx.is_nan() || slope == 0.0 || slope.is_nan() {
      return {
        value: x,
        residual: fx,
        iterations: iteration,
        status: InvalidInput,
      }
    }
    let next = x - fx / slope
    if (next - x).abs() <= tolerance || f(next).abs() <= tolerance {
      return {
        value: next,
        residual: f(next),
        iterations: iteration + 1,
        status: Converged,
      }
    }
    x = next
  }
  {
    value: x,
    residual: f(x),
    iterations: max_iterations,
    status: MaxIterations,
  }
}

///|
pub fn polynomial(coefficients : Array[Double], x : Double) -> Double {
  coefficients.fold(init=0.0, (value, coefficient) => value * x + coefficient)
}

///|
pub fn polynomial_derivative(
  coefficients : Array[Double],
  x : Double,
) -> Double {
  if coefficients.length() < 2 {
    0.0
  } else {
    let mut result = 0.0
    let degree = coefficients.length() - 1
    for i in 0..<degree {
      result = result * x + coefficients[i] * Double::from_int(degree - i)
    }
    result
  }
}

///|
pub fn moving_average(values : Array[Double], window : Int) -> Array[Double] {
  let result : Array[Double] = []
  if window <= 0 {
    return result
  }
  for i in 0..<values.length() {
    let begin = if i + 1 >= window { i + 1 - window } else { 0 }
    let mut total = 0.0
    for j in begin..<=i {
      total += values[j]
    }
    result.push(total / Double::from_int(i - begin + 1))
  }
  result
}

///|
pub fn quantize(value : Double, step : Double) -> Double {
  if step <= 0.0 {
    value
  } else {
    (value / step).round() * step
  }
}

///|
pub fn relative_error(actual : Double, expected : Double) -> Double {
  if expected == 0.0 {
    (actual - expected).abs()
  } else {
    (actual - expected).abs() / expected.abs()
  }
}

///|
pub fn is_close(
  actual : Double,
  expected : Double,
  absolute? : Double = 1.0e-10,
  relative? : Double = 1.0e-10,
) -> Bool {
  (actual - expected).abs() <= absolute ||
  relative_error(actual, expected) <= relative
}

///|
pub fn normalize_weights(weights : Array[Double]) -> Array[Double] {
  let total = weights.fold(init=0.0, (sum, value) => sum + value.max(0.0))
  if total == 0.0 {
    weights.map(value => value * 0.0)
  } else {
    weights.map(value => value.max(0.0) / total)
  }
}
