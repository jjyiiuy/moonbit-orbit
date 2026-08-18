///|
pub struct LinkBudget {
  frequency_ghz : Double
  distance_km : Double
  tx_power_dbw : Double
  antenna_gain_db : Double
  losses_db : Double
  margin_db : Double
} derive(Debug, Eq)

///|
pub struct ContactCapacity {
  duration_s : Double
  rate_kbps : Double
  volume_mb : Double
  margin_db : Double
} derive(Debug, Eq)

///|
pub fn link_budget(
  frequency_ghz : Double,
  distance_km : Double,
  tx_power_dbw : Double,
  antenna_gain_db : Double,
  losses_db : Double,
  required_db : Double,
) -> LinkBudget {
  let margin = antenna_gain_db +
    tx_power_dbw -
    losses_db -
    free_space_path_loss_db(distance_km, frequency_ghz) -
    required_db
  {
    frequency_ghz,
    distance_km,
    tx_power_dbw,
    antenna_gain_db,
    losses_db,
    margin_db: margin,
  }
}

///|
pub fn contact_capacity(
  duration_s : Double,
  rate_kbps : Double,
  link : LinkBudget,
) -> ContactCapacity {
  {
    duration_s: duration_s.max(0.0),
    rate_kbps: rate_kbps.max(0.0),
    volume_mb: contact_data_volume_mb(rate_kbps, duration_s),
    margin_db: link.margin_db,
  }
}

///|
pub fn link_is_usable(budget : LinkBudget, required_margin_db : Double) -> Bool {
  budget.margin_db >= required_margin_db
}

///|
pub fn doppler_corrected_frequency(
  carrier_hz : Double,
  radial_speed_km_s : Double,
) -> Double {
  carrier_hz + doppler_shift_hz(carrier_hz, radial_speed_km_s)
}

///|
pub fn range_rate(a : StateVector, b : StateVector) -> Double {
  let relative = relative_state(a, b)
  if relative.position_km.norm() == 0.0 {
    0.0
  } else {
    relative.position_km.dot(relative.velocity_km_s) /
    relative.position_km.norm()
  }
}

///|
pub fn round_trip_delay_s(distance_km : Double) -> Double {
  distance_km.max(0.0) * 2.0 / 299792.458
}

///|
pub fn light_time_s(distance_km : Double) -> Double {
  distance_km.max(0.0) / 299792.458
}

///|
pub fn packet_error_rate(eb_no_db : Double, coding_gain_db : Double) -> Double {
  let quality = eb_no_db + coding_gain_db
  if quality <= 0.0 {
    1.0
  } else {
    @math.exp(-quality / 10.0).min(1.0)
  }
}

///|
pub fn effective_data_rate(rate_kbps : Double, packet_error : Double) -> Double {
  rate_kbps.max(0.0) * (1.0 - clamp(packet_error, 0.0, 1.0))
}

///|
pub fn link_availability(
  margins : Array[Double],
  threshold_db : Double,
) -> Double {
  if margins.length() == 0 {
    0.0
  } else {
    Double::from_int(margins.filter(margin => margin >= threshold_db).length()) /
    Double::from_int(margins.length())
  }
}
