///|
pub enum TelemetryQuality {
  Good
  Suspect
  Invalid
} derive(Debug, Eq)

///|
pub struct TelemetrySample {
  time_s : Double
  name : String
  value : Double
  unit : String
  quality : TelemetryQuality
} derive(Debug, Eq)

///|
pub struct TelemetrySummary {
  name : String
  count : Int
  valid_count : Int
  minimum : Double
  maximum : Double
  mean : Double
  latest_time_s : Double
} derive(Debug, Eq)

///|
pub fn TelemetrySample::new(
  time_s : Double,
  name : String,
  value : Double,
  unit : String,
) -> TelemetrySample {
  {
    time_s,
    name,
    value,
    unit,
    quality: if value.is_nan() || value.is_inf() {
      Invalid
    } else {
      Good
    },
  }
}

///|
pub fn TelemetrySample::with_quality(
  sample : TelemetrySample,
  quality : TelemetryQuality,
) -> TelemetrySample {
  { ..sample, quality, }
}

///|
pub fn telemetry_is_valid(sample : TelemetrySample) -> Bool {
  sample.quality is Good
}

///|
pub fn validate_range(
  sample : TelemetrySample,
  lower : Double,
  upper : Double,
) -> TelemetrySample {
  if !telemetry_is_valid(sample) {
    sample
  } else if sample.value < lower || sample.value > upper {
    { ..sample, quality: Suspect }
  } else {
    sample
  }
}

///|
pub fn summarize_telemetry(
  name : String,
  samples : Array[TelemetrySample],
) -> TelemetrySummary {
  let selected = samples.filter(sample => sample.name == name)
  let valid = selected.filter(telemetry_is_valid)
  let values = valid.map(sample => sample.value)
  let stats = summarize_samples(values)
  let latest = selected.fold(init=0.0, (time, sample) => time.max(sample.time_s))
  {
    name,
    count: selected.length(),
    valid_count: valid.length(),
    minimum: stats.minimum,
    maximum: stats.maximum,
    mean: stats.mean,
    latest_time_s: latest,
  }
}

///|
pub fn resample_linear(
  samples : Array[TelemetrySample],
  times : Array[Double],
) -> Array[TelemetrySample] {
  let ordered = samples.filter(telemetry_is_valid)
  let result : Array[TelemetrySample] = []
  for time in times {
    if ordered.length() == 0 {
      continue
    }
    let mut before : TelemetrySample? = None
    let mut after : TelemetrySample? = None
    for sample in ordered {
      if sample.time_s <= time {
        before = Some(sample)
      }
      if sample.time_s >= time && after is None {
        after = Some(sample)
      }
    }
    match (before, after) {
      (Some(a), Some(b)) => {
        let value = if a.time_s == b.time_s {
          a.value
        } else {
          lerp_scalar(a.value, b.value, inverse_lerp(a.time_s, b.time_s, time))
        }
        result.push(TelemetrySample::new(time, a.name, value, a.unit))
      }
      _ => ()
    }
  }
  result
}

///|
pub fn detect_step_changes(
  samples : Array[TelemetrySample],
  threshold : Double,
) -> Array[TelemetrySample] {
  let result : Array[TelemetrySample] = []
  if samples.length() == 0 {
    return result
  }
  let mut previous = samples[0]
  for sample in samples {
    if sample.name == previous.name &&
      (sample.value - previous.value).abs() >= threshold {
      result.push(sample.with_quality(Suspect))
    }
    previous = sample
  }
  result
}

///|
pub fn telemetry_channel_names(
  samples : Array[TelemetrySample],
) -> Array[String] {
  let names : Array[String] = []
  for sample in samples {
    if !names.contains(sample.name) {
      names.push(sample.name)
    }
  }
  names
}

///|
pub fn telemetry_missing_intervals(
  samples : Array[TelemetrySample],
  max_gap_s : Double,
) -> Int {
  let mut count = 0
  if samples.length() < 2 {
    return count
  }
  for i in 0..<(samples.length() - 1) {
    if samples[i + 1].time_s - samples[i].time_s > max_gap_s {
      count += 1
    }
  }
  count
}

///|
pub fn convert_unit(value : Double, from : String, to : String) -> Double {
  if from == to {
    value
  } else if from == "km" && to == "m" {
    value * 1000.0
  } else if from == "m" && to == "km" {
    value / 1000.0
  } else if from == "deg" && to == "rad" {
    radians(value)
  } else if from == "rad" && to == "deg" {
    degrees(value)
  } else if from == "km_s" && to == "m_s" {
    value * 1000.0
  } else if from == "m_s" && to == "km_s" {
    value / 1000.0
  } else {
    value
  }
}

///|
pub fn telemetry_health(samples : Array[TelemetrySample]) -> Double {
  if samples.length() == 0 {
    0.0
  } else {
    Double::from_int(samples.filter(telemetry_is_valid).length()) /
    Double::from_int(samples.length())
  }
}
