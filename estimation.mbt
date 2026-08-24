///|
pub enum EstimateStatus {
  Converged
  InsufficientData
  Singular
} derive(Debug, Eq)

///|
pub struct ScalarEstimate {
  value : Double
  variance : Double
  residual_rms : Double
  used : Int
  status : EstimateStatus
} derive(Debug, Eq)

///|
pub struct TrendEstimate {
  intercept : Double
  slope_per_s : Double
  variance : Double
  residual_rms : Double
  used : Int
  status : EstimateStatus
} derive(Debug, Eq)

///|
pub struct ResidualSummary {
  count : Int
  mean : Double
  rms : Double
  maximum_abs : Double
  rejected : Int
} derive(Debug, Eq)

///|
fn scalar_empty() -> ScalarEstimate {
  {
    value: 0.0,
    variance: 0.0,
    residual_rms: 0.0,
    used: 0,
    status: InsufficientData,
  }
}

///|
pub fn weighted_scalar_estimate(
  observations : Array[Observation],
) -> ScalarEstimate {
  let usable = observations.filter(item => {
    item.is_valid() && item.weight() > 0.0
  })
  if usable.length() == 0 {
    scalar_empty()
  } else {
    let weight_sum = usable.fold(init=0.0, (sum, item) => sum + item.weight())
    let weighted_value = usable.fold(init=0.0, (sum, item) => {
        sum + item.weight() * item.value
      }) /
      weight_sum
    let residual = usable.fold(init=0.0, (sum, item) => {
      let error = item.value - weighted_value
      sum + error * error
    })
    {
      value: weighted_value,
      variance: 1.0 / weight_sum.max(1.0e-30),
      residual_rms: (residual / Double::from_int(usable.length())).sqrt(),
      used: usable.length(),
      status: Converged,
    }
  }
}

///|
pub fn weighted_residual_estimate(
  observations : Array[Observation],
) -> ScalarEstimate {
  let usable = observations.filter(item => {
    item.is_valid() && item.weight() > 0.0
  })
  if usable.length() == 0 {
    scalar_empty()
  } else {
    let weight_sum = usable.fold(init=0.0, (sum, item) => sum + item.weight())
    let weighted_value = usable.fold(init=0.0, (sum, item) => {
        sum + item.weight() * item.residual()
      }) /
      weight_sum
    let residual = usable.fold(init=0.0, (sum, item) => {
      let error = item.residual() - weighted_value
      sum + error * error
    })
    {
      value: weighted_value,
      variance: 1.0 / weight_sum.max(1.0e-30),
      residual_rms: (residual / Double::from_int(usable.length())).sqrt(),
      used: usable.length(),
      status: Converged,
    }
  }
}

///|
pub fn innovation_is_acceptable(
  estimate : ScalarEstimate,
  limit_sigma : Double,
) -> Bool {
  estimate.status is Converged &&
  estimate.residual_rms <= limit_sigma.abs() * estimate.variance.sqrt().max(1.0)
}

///|
pub fn estimate_observation_bias(
  observations : Array[Observation],
) -> ScalarEstimate {
  weighted_residual_estimate(observations)
}

///|
pub fn observation_residual_summary(
  observations : Array[Observation],
  gate_sigma : Double,
) -> ResidualSummary {
  let valid = observations.filter(item => item.is_valid())
  if valid.length() == 0 {
    {
      count: 0,
      mean: 0.0,
      rms: 0.0,
      maximum_abs: 0.0,
      rejected: observations.length(),
    }
  } else {
    let mean = valid.fold(init=0.0, (sum, item) => sum + item.residual()) /
      Double::from_int(valid.length())
    let square_sum = valid.fold(init=0.0, (sum, item) => {
      sum + item.residual() * item.residual()
    })
    let maximum_abs = valid.fold(init=0.0, (maximum, item) => {
      maximum.max(item.residual().abs())
    })
    let rejected = valid
      .filter(item => item.normalized_residual().abs() > gate_sigma.abs())
      .length()
    {
      count: valid.length(),
      mean,
      rms: (square_sum / Double::from_int(valid.length())).sqrt(),
      maximum_abs,
      rejected: rejected + observations.length() - valid.length(),
    }
  }
}

///|
pub fn fit_observation_trend(
  observations : Array[Observation],
) -> TrendEstimate {
  let usable = observations.filter(item => item.is_valid())
  if usable.length() < 2 {
    {
      intercept: 0.0,
      slope_per_s: 0.0,
      variance: 0.0,
      residual_rms: 0.0,
      used: usable.length(),
      status: InsufficientData,
    }
  } else {
    let origin = usable[0].epoch.seconds_since_j2000
    let times = usable.map(item => item.epoch.seconds_since_j2000 - origin)
    let values = usable.map(item => item.value)
    let mean_t = times.fold(init=0.0, (sum, value) => sum + value) /
      Double::from_int(times.length())
    let mean_y = values.fold(init=0.0, (sum, value) => sum + value) /
      Double::from_int(values.length())
    let denominator = times.fold(init=0.0, (sum, value) => {
      let delta = value - mean_t
      sum + delta * delta
    })
    if denominator <= 1.0e-30 {
      {
        intercept: mean_y,
        slope_per_s: 0.0,
        variance: 0.0,
        residual_rms: 0.0,
        used: usable.length(),
        status: Singular,
      }
    } else {
      let mut numerator = 0.0
      let mut residual = 0.0
      for i in 0..<times.length() {
        numerator += (times[i] - mean_t) * (values[i] - mean_y)
      }
      let slope = numerator / denominator
      let intercept = mean_y - slope * mean_t
      for i in 0..<times.length() {
        let error = values[i] - (intercept + slope * times[i])
        residual += error * error
      }
      {
        intercept: intercept - slope * origin,
        slope_per_s: slope,
        variance: residual / Double::from_int((usable.length() - 1).max(1)),
        residual_rms: (residual / Double::from_int(usable.length())).sqrt(),
        used: usable.length(),
        status: Converged,
      }
    }
  }
}

///|
pub fn predict_trend(estimate : TrendEstimate, epoch : Epoch) -> Double {
  estimate.intercept + estimate.slope_per_s * epoch.seconds_since_j2000
}

///|
pub fn trend_is_stable(
  estimate : TrendEstimate,
  maximum_slope_per_s : Double,
) -> Bool {
  estimate.status is Converged &&
  estimate.slope_per_s.abs() <= maximum_slope_per_s.abs()
}

///|
pub fn reject_observation(
  observation : Observation,
  gate_sigma : Double,
) -> Observation {
  if observation.normalized_residual().abs() > gate_sigma.abs() {
    observation.with_quality(ObservationQuality::Suspect)
  } else {
    observation
  }
}

///|
pub fn reject_outliers(
  observations : Array[Observation],
  gate_sigma : Double,
) -> Array[Observation] {
  observations.map(item => reject_observation(item, gate_sigma))
}

///|
pub fn covariance_of_observations(
  first : Array[Observation],
  second : Array[Observation],
) -> Double {
  if first.length() != second.length() || first.length() < 2 {
    0.0
  } else {
    let a = first.map(item => item.value)
    let b = second.map(item => item.value)
    covariance(a, b)
  }
}

///|
pub fn observation_information(observations : Array[Observation]) -> Double {
  observations.fold(init=0.0, (sum, item) => sum + item.weight())
}

///|
pub fn information_variance(observations : Array[Observation]) -> Double {
  let information = observation_information(observations)
  if information <= 0.0 {
    0.0
  } else {
    1.0 / information
  }
}
