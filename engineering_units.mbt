///|
pub fn millimeters_to_meters(value : Double) -> Double {
  value / 1000.0
}

///|
pub fn meters_to_millimeters(value : Double) -> Double {
  value * 1000.0
}

///|
pub fn centimeters_to_meters(value : Double) -> Double {
  value / 100.0
}

///|
pub fn meters_to_centimeters(value : Double) -> Double {
  value * 100.0
}

///|
pub fn pounds_to_kilograms(value : Double) -> Double {
  value * 0.45359237
}

///|
pub fn kilograms_to_pounds(value : Double) -> Double {
  value / 0.45359237
}

///|
pub fn inches_to_meters(value : Double) -> Double {
  value * 0.0254
}

///|
pub fn meters_to_inches(value : Double) -> Double {
  value / 0.0254
}

///|
pub fn miles_to_kilometers(value : Double) -> Double {
  value * 1.609344
}

///|
pub fn kilometers_to_miles(value : Double) -> Double {
  value / 1.609344
}

///|
pub fn knots_to_meters_per_second(value : Double) -> Double {
  value * 0.514444444
}

///|
pub fn meters_per_second_to_knots(value : Double) -> Double {
  value / 0.514444444
}

///|
pub fn psi_to_pascal(value : Double) -> Double {
  value * 6894.757293
}

///|
pub fn pascal_to_psi(value : Double) -> Double {
  value / 6894.757293
}

///|
pub fn kelvin_to_celsius(value : Double) -> Double {
  value - 273.15
}

///|
pub fn celsius_to_kelvin(value : Double) -> Double {
  value + 273.15
}

///|
pub fn fahrenheit_to_celsius(value : Double) -> Double {
  (value - 32.0) * 5.0 / 9.0
}

///|
pub fn celsius_to_fahrenheit(value : Double) -> Double {
  value * 9.0 / 5.0 + 32.0
}

///|
pub fn joules_to_watt_hours(value : Double) -> Double {
  value / 3600.0
}

///|
pub fn watt_hours_to_joules(value : Double) -> Double {
  value * 3600.0
}

///|
pub fn kilowatt_hours_to_joules(value : Double) -> Double {
  value * 3600000.0
}

///|
pub fn joules_to_kilowatt_hours(value : Double) -> Double {
  value / 3600000.0
}

///|
pub fn square_meters_to_square_kilometers(value : Double) -> Double {
  value / 1000000.0
}

///|
pub fn square_kilometers_to_square_meters(value : Double) -> Double {
  value * 1000000.0
}

///|
pub fn cubic_meters_to_liters(value : Double) -> Double {
  value * 1000.0
}

///|
pub fn liters_to_cubic_meters(value : Double) -> Double {
  value / 1000.0
}

///|
pub fn rad_per_second_to_deg_per_second(value : Double) -> Double {
  degrees(value)
}

///|
pub fn deg_per_second_to_rad_per_second(value : Double) -> Double {
  radians(value)
}

///|
pub fn arcseconds_to_radians(value : Double) -> Double {
  radians(value / 3600.0)
}

///|
pub fn radians_to_arcseconds(value : Double) -> Double {
  degrees(value) * 3600.0
}

///|
pub fn hertz_to_period_seconds(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else {
    1.0 / value
  }
}

///|
pub fn period_seconds_to_hertz(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else {
    1.0 / value
  }
}

///|
pub fn percent_to_fraction(value : Double) -> Double {
  value / 100.0
}

///|
pub fn fraction_to_percent(value : Double) -> Double {
  value * 100.0
}

///|
pub fn ratio_to_decibels(value : Double) -> Double {
  linear_to_db(value)
}

///|
pub fn decibels_to_ratio(value : Double) -> Double {
  db_to_linear(value)
}

///|
pub fn signal_to_noise_db(signal : Double, noise : Double) -> Double {
  if noise <= 0.0 {
    1.0e9
  } else {
    linear_to_db(signal / noise)
  }
}

///|
pub fn noise_from_density(
  density_w_hz : Double,
  bandwidth_hz : Double,
) -> Double {
  density_w_hz.max(0.0) * bandwidth_hz.max(0.0)
}

///|
pub fn thermal_noise_power(
  temperature_k : Double,
  bandwidth_hz : Double,
) -> Double {
  1.380649e-23 * temperature_k.max(0.0) * bandwidth_hz.max(0.0)
}

///|
pub fn photon_energy(frequency_hz : Double) -> Double {
  6.62607015e-34 * frequency_hz.max(0.0)
}

///|
pub fn blackbody_flux(temperature_k : Double) -> Double {
  5.670374419e-8 *
  temperature_k.max(0.0) *
  temperature_k.max(0.0) *
  temperature_k.max(0.0) *
  temperature_k.max(0.0)
}

///|
pub fn dynamic_pressure(density_kg_m3 : Double, speed_m_s : Double) -> Double {
  0.5 * density_kg_m3.max(0.0) * speed_m_s * speed_m_s
}

///|
pub fn mach_number(speed_m_s : Double, sound_speed_m_s : Double) -> Double {
  if sound_speed_m_s <= 0.0 {
    0.0
  } else {
    speed_m_s / sound_speed_m_s
  }
}

///|
pub fn reynolds_number(
  density : Double,
  speed : Double,
  length : Double,
  viscosity : Double,
) -> Double {
  if viscosity <= 0.0 {
    0.0
  } else {
    density * speed * length / viscosity
  }
}

///|
pub fn ballistic_coefficient(
  mass_kg : Double,
  area_m2 : Double,
  drag_coefficient : Double,
) -> Double {
  if area_m2 <= 0.0 || drag_coefficient <= 0.0 {
    0.0
  } else {
    mass_kg.max(0.0) / (area_m2 * drag_coefficient)
  }
}

///|
pub fn propellant_mass_from_delta_v(
  initial_mass_kg : Double,
  delta_v_km_s : Double,
  exhaust_velocity_km_s : Double,
) -> Double {
  if exhaust_velocity_km_s <= 0.0 {
    0.0
  } else {
    initial_mass_kg.max(0.0) *
    (1.0 - @math.exp(-delta_v_km_s.max(0.0) / exhaust_velocity_km_s))
  }
}

///|
pub fn rocket_delta_v(
  initial_mass_kg : Double,
  final_mass_kg : Double,
  exhaust_velocity_km_s : Double,
) -> Double {
  if final_mass_kg <= 0.0 || initial_mass_kg <= final_mass_kg {
    0.0
  } else {
    exhaust_velocity_km_s * @math.ln(initial_mass_kg / final_mass_kg)
  }
}
