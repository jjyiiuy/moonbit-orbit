///|
pub enum ObservationKind {
  Range
  RangeRate
  Azimuth
  Elevation
} derive(Debug, Eq)

///|
pub enum ObservationQuality {
  Good
  Suspect
  Invalid
} derive(Debug, Eq)

///|
pub struct Observation {
  epoch : Epoch
  station : GroundStation
  kind : ObservationKind
  value : Double
  predicted : Double
  sigma : Double
  quality : ObservationQuality
} derive(Debug, Eq)

///|
pub struct ObservationBatch {
  name : String
  observations : Array[Observation]
} derive(Debug, Eq)

///|
pub fn observation_kind_name(kind : ObservationKind) -> String {
  match kind {
    Range => "range"
    RangeRate => "range-rate"
    Azimuth => "azimuth"
    Elevation => "elevation"
  }
}

///|
pub fn all_observation_kinds() -> Array[ObservationKind] {
  [Range, RangeRate, Azimuth, Elevation]
}

///|
pub fn invalid_observation_quality() -> ObservationQuality {
  ObservationQuality::Invalid
}

///|
pub fn observation_kind_is_angular(kind : ObservationKind) -> Bool {
  match kind {
    Azimuth | Elevation => true
    _ => false
  }
}

///|
pub fn observation_kind_is_dynamic(kind : ObservationKind) -> Bool {
  match kind {
    RangeRate => true
    _ => false
  }
}

///|
pub fn Observation::new(
  epoch : Epoch,
  station : GroundStation,
  kind : ObservationKind,
  value : Double,
  sigma : Double,
) -> Observation {
  let quality = if sigma <= 0.0 || value.is_nan() || value.is_inf() {
    ObservationQuality::Invalid
  } else {
    ObservationQuality::Good
  }
  { epoch, station, kind, value, predicted: value, sigma: sigma.abs(), quality }
}

///|
pub fn Observation::with_quality(
  observation : Observation,
  quality : ObservationQuality,
) -> Observation {
  { ..observation, quality, }
}

///|
pub fn Observation::with_prediction(
  observation : Observation,
  predicted : Double,
) -> Observation {
  let quality = if predicted.is_nan() || predicted.is_inf() {
    ObservationQuality::Invalid
  } else {
    observation.quality
  }
  { ..observation, predicted, quality }
}

///|
pub fn Observation::is_valid(observation : Observation) -> Bool {
  observation.quality is Good || observation.quality is Suspect
}

///|
pub fn Observation::residual(observation : Observation) -> Double {
  observation.value - observation.predicted
}

///|
pub fn Observation::normalized_residual(observation : Observation) -> Double {
  if observation.sigma <= 0.0 {
    0.0
  } else {
    observation.residual() / observation.sigma
  }
}

///|
pub fn Observation::weight(observation : Observation) -> Double {
  if !observation.is_valid() || observation.sigma <= 0.0 {
    0.0
  } else {
    1.0 / (observation.sigma * observation.sigma)
  }
}

///|
pub fn ObservationBatch::new(name : String) -> ObservationBatch {
  { name, observations: [] }
}

///|
pub fn ObservationBatch::add(
  batch : ObservationBatch,
  observation : Observation,
) -> ObservationBatch {
  let observations = batch.observations.copy()
  observations.push(observation)
  { ..batch, observations, }
}

///|
pub fn ObservationBatch::sort_by_epoch(
  batch : ObservationBatch,
) -> ObservationBatch {
  let observations = batch.observations.copy()
  for i in 0..<observations.length() {
    for j in (i + 1)..<observations.length() {
      if observations[j].epoch.seconds_since_j2000 <
        observations[i].epoch.seconds_since_j2000 {
        let item = observations[i]
        observations[i] = observations[j]
        observations[j] = item
      }
    }
  }
  { ..batch, observations, }
}

///|
pub fn ObservationBatch::valid_count(batch : ObservationBatch) -> Int {
  batch.observations.filter(item => item.is_valid()).length()
}

///|
pub fn ObservationBatch::invalid_count(batch : ObservationBatch) -> Int {
  batch.observations.length() - batch.valid_count()
}

///|
pub fn ObservationBatch::span_s(batch : ObservationBatch) -> Double {
  if batch.observations.length() < 2 {
    0.0
  } else {
    let sorted = batch.sort_by_epoch()
    sorted.observations[sorted.observations.length() - 1].epoch.seconds_since_j2000 -
    sorted.observations[0].epoch.seconds_since_j2000
  }
}

///|
pub fn ObservationBatch::by_kind(
  batch : ObservationBatch,
  kind : ObservationKind,
) -> Array[Observation] {
  batch.observations.filter(item => item.kind == kind)
}

///|
pub fn ObservationBatch::residual_rms(batch : ObservationBatch) -> Double {
  let valid = batch.observations.filter(item => item.is_valid())
  if valid.length() == 0 {
    0.0
  } else {
    let total = valid.fold(init=0.0, (sum, item) => {
      sum + item.residual() * item.residual()
    })
    (total / Double::from_int(valid.length())).sqrt()
  }
}

///|
pub fn ObservationBatch::weighted_residual_rms(
  batch : ObservationBatch,
) -> Double {
  let valid = batch.observations.filter(item => {
    item.is_valid() && item.weight() > 0.0
  })
  if valid.length() == 0 {
    0.0
  } else {
    let weighted = valid.fold(init=0.0, (sum, item) => {
      sum + item.weight() * item.residual() * item.residual()
    })
    let weights = valid.fold(init=0.0, (sum, item) => sum + item.weight())
    (weighted / weights.max(1.0e-30)).sqrt()
  }
}

///|
pub fn observation_prediction(
  station : GroundStation,
  epoch : Epoch,
  state : StateVector,
  kind : ObservationKind,
) -> Double {
  let look = look_angle_from_eci(station.location, epoch, state.position_km)
  match kind {
    Range => look.range_km
    RangeRate => state.velocity_km_s.dot(state.position_km.unit())
    Azimuth => look.azimuth_rad
    Elevation => look.elevation_rad
  }
}

///|
pub fn observe_state(
  station : GroundStation,
  epoch : Epoch,
  state : StateVector,
  kind : ObservationKind,
  bias? : Double = 0.0,
  sigma? : Double = 1.0,
) -> Observation {
  let predicted = observation_prediction(station, epoch, state, kind)
  let value = predicted + bias
  let quality = if sigma <= 0.0 || predicted.is_nan() || predicted.is_inf() {
    ObservationQuality::Invalid
  } else {
    ObservationQuality::Good
  }
  { epoch, station, kind, value, predicted, sigma: sigma.abs(), quality }
}

///|
pub fn observation_residual(
  observation : Observation,
  state : StateVector,
) -> Double {
  observation.value -
  observation_prediction(
    observation.station,
    observation.epoch,
    state,
    observation.kind,
  )
}

///|
pub fn mark_observation_outlier(
  observation : Observation,
  limit_sigma : Double,
) -> Observation {
  if observation.normalized_residual().abs() > limit_sigma.abs() {
    observation.with_quality(Suspect)
  } else {
    observation
  }
}

///|
pub fn observation_quality_score(observation : Observation) -> Double {
  match observation.quality {
    Good => 1.0
    Suspect => 0.5
    Invalid => 0.0
  }
}
