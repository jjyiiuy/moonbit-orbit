///|
pub struct Histogram {
  edges : Array[Double]
  counts : Array[Int]
} derive(Debug, Eq)

///|
pub struct LinearRegression {
  slope : Double
  intercept : Double
  r_squared : Double
} derive(Debug, Eq)

///|
pub fn histogram(
  values : Array[Double],
  lower : Double,
  upper : Double,
  bins : Int,
) -> Histogram {
  let count = bins.max(1)
  let edges : Array[Double] = []
  let counts : Array[Int] = []
  for i in 0..<=count {
    edges.push(
      lerp_scalar(lower, upper, Double::from_int(i) / Double::from_int(count)),
    )
  }
  for _ in 0..<count {
    counts.push(0)
  }
  let width = (upper - lower) / Double::from_int(count)
  if width > 0.0 {
    for value in values {
      let index = ((value - lower) / width)
        .floor()
        .to_int()
        .min(count - 1)
        .max(0)
      counts[index] += 1
    }
  }
  { edges, counts }
}

///|
pub fn percentile(values : Array[Double], fraction : Double) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let sorted = values.copy()
    for i in 0..<sorted.length() {
      for j in (i + 1)..<sorted.length() {
        if sorted[j] < sorted[i] {
          let item = sorted[i]
          sorted[i] = sorted[j]
          sorted[j] = item
        }
      }
    }
    let index = (clamp(fraction, 0.0, 1.0) *
      Double::from_int(sorted.length() - 1))
      .round()
      .to_int()
    sorted[index]
  }
}

///|
pub fn covariance(xs : Array[Double], ys : Array[Double]) -> Double {
  if xs.length() != ys.length() || xs.length() < 2 {
    0.0
  } else {
    let ax = mean(xs)
    let ay = mean(ys)
    let mut total = 0.0
    for i in 0..<xs.length() {
      total += (xs[i] - ax) * (ys[i] - ay)
    }
    total / Double::from_int(xs.length() - 1)
  }
}

///|
pub fn correlation(xs : Array[Double], ys : Array[Double]) -> Double {
  let denominator = variance(xs).sqrt() * variance(ys).sqrt()
  if denominator == 0.0 {
    0.0
  } else {
    covariance(xs, ys) / denominator
  }
}

///|
pub fn linear_regression(
  xs : Array[Double],
  ys : Array[Double],
) -> LinearRegression {
  let slope = if variance(xs) == 0.0 {
    0.0
  } else {
    covariance(xs, ys) / variance(xs)
  }
  let intercept = mean(ys) - slope * mean(xs)
  let predicted = xs.map(x => slope * x + intercept)
  let total = ys.fold(init=0.0, (sum, y) => {
    sum + (y - mean(ys)) * (y - mean(ys))
  })
  let mut residual = 0.0
  for i in 0..<ys.length() {
    residual += (ys[i] - predicted[i]) * (ys[i] - predicted[i])
  }
  {
    slope,
    intercept,
    r_squared: if total == 0.0 {
      0.0
    } else {
      1.0 - residual / total
    },
  }
}

///|
pub fn z_score(value : Double, values : Array[Double]) -> Double {
  let deviation = variance(values).sqrt()
  if deviation == 0.0 {
    0.0
  } else {
    (value - mean(values)) / deviation
  }
}

///|
pub fn outliers(values : Array[Double], threshold : Double) -> Array[Double] {
  let average = mean(values)
  let deviation = variance(values).sqrt()
  if deviation == 0.0 {
    []
  } else {
    values.filter(value => (value - average).abs() > threshold * deviation)
  }
}

///|
pub fn cumulative_sum(values : Array[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let mut total = 0.0
  for value in values {
    total += value
    result.push(total)
  }
  result
}

///|
pub fn cumulative_maximum(values : Array[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let mut maximum = -1.0e300
  for value in values {
    maximum = maximum.max(value)
    result.push(maximum)
  }
  result
}

///|
pub fn normalize_series(values : Array[Double]) -> Array[Double] {
  let stats = summarize_samples(values)
  if stats.maximum == stats.minimum {
    values.map(_ => 0.0)
  } else {
    values.map(value => inverse_lerp(stats.minimum, stats.maximum, value))
  }
}
