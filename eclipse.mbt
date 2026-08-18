///|
pub enum EclipseKind {
  None
  Penumbra
  Umbra
} derive(Debug, Eq)

///|
pub struct EclipseResult {
  kind : EclipseKind
  occultation_fraction : Double
  sun_angle_rad : Double
  earth_angle_rad : Double
  duration_estimate_s : Double
} derive(Debug, Eq)

///|
pub const SunRadiusKm : Double = 695700.0

///|
pub const SunEarthDistanceKm : Double = 149597870.7

///|
pub fn angular_radius(radius_km : Double, distance_km : Double) -> Double {
  if radius_km <= 0.0 || distance_km <= 0.0 {
    0.0
  } else {
    @math.asin(clamp(radius_km / distance_km, -1.0, 1.0))
  }
}

///|
pub fn eclipse_geometry(
  satellite_to_sun : Vec3,
  satellite_to_earth : Vec3,
  earth_radius_km : Double,
  sun_radius_km : Double,
) -> EclipseResult {
  let sun_distance = satellite_to_sun.norm()
  let earth_distance = satellite_to_earth.norm()
  if sun_distance == 0.0 ||
    earth_distance == 0.0 ||
    earth_radius_km <= 0.0 ||
    sun_radius_km <= 0.0 {
    return {
      kind: None,
      occultation_fraction: 0.0,
      sun_angle_rad: 0.0,
      earth_angle_rad: 0.0,
      duration_estimate_s: 0.0,
    }
  }
  let sun_angle = angular_radius(sun_radius_km, sun_distance)
  let earth_angle = angular_radius(earth_radius_km, earth_distance)
  let separation = satellite_to_sun.angle_between(satellite_to_earth)
  let overlap = (sun_angle + earth_angle - separation).max(0.0)
  let fraction = clamp(overlap / (2.0 * sun_angle.max(1.0e-15)), 0.0, 1.0)
  let kind = if separation >= sun_angle + earth_angle {
    None
  } else if earth_angle > sun_angle && separation + sun_angle <= earth_angle {
    Umbra
  } else {
    Penumbra
  }
  let chord = earth_distance * @math.sin(earth_angle.min(half_pi)) * 2.0
  {
    kind,
    occultation_fraction: fraction,
    sun_angle_rad: sun_angle,
    earth_angle_rad: earth_angle,
    duration_estimate_s: if kind is None {
      0.0
    } else {
      chord / 7.5
    },
  }
}

///|
pub fn cylindrical_eclipse(
  satellite_position : Vec3,
  sun_direction : Vec3,
  earth_radius_km : Double,
) -> EclipseResult {
  let axis = sun_direction.unit()
  let along = satellite_position.dot(axis)
  let perpendicular = satellite_position.sub(axis.scale(along)).norm()
  let in_shadow = along < 0.0 && perpendicular <= earth_radius_km
  let fraction = if in_shadow { 1.0 } else { 0.0 }
  {
    kind: if in_shadow {
      Umbra
    } else {
      None
    },
    occultation_fraction: fraction,
    sun_angle_rad: 0.0,
    earth_angle_rad: 0.0,
    duration_estimate_s: 0.0,
  }
}

///|
pub fn beta_angle(orbit_normal : Vec3, sun_direction : Vec3) -> Double {
  half_pi - orbit_normal.unit().angle_between(sun_direction.unit())
}

///|
pub fn daylight_fraction(result : EclipseResult) -> Double {
  1.0 - result.occultation_fraction
}

///|
pub fn eclipse_is_total(result : EclipseResult) -> Bool {
  result.kind is Umbra
}

///|
pub fn eclipse_is_partial(result : EclipseResult) -> Bool {
  result.kind is Penumbra
}

///|
pub fn sunlight_power_fraction(
  result : EclipseResult,
  albedo? : Double = 0.0,
) -> Double {
  let direct = daylight_fraction(result)
  (direct + albedo * (1.0 - direct)).min(1.0).max(0.0)
}

///|
pub fn solar_flux_at_distance(distance_au : Double) -> Double {
  if distance_au <= 0.0 {
    0.0
  } else {
    1361.0 / (distance_au * distance_au)
  }
}

///|
pub fn solar_pressure_n_m2(distance_au : Double) -> Double {
  solar_flux_at_distance(distance_au) / 299792458.0
}

///|
pub fn eclipse_margin_rad(result : EclipseResult) -> Double {
  result.earth_angle_rad - result.sun_angle_rad - result.sun_angle_rad
}

///|
pub fn estimate_eclipse_duration(
  orbit_radius_km : Double,
  earth_radius_km : Double,
  orbital_speed_km_s : Double,
) -> Double {
  if orbit_radius_km <= earth_radius_km || orbital_speed_km_s <= 0.0 {
    0.0
  } else {
    let half_chord = (orbit_radius_km * orbit_radius_km -
    earth_radius_km * earth_radius_km).sqrt()
    2.0 * half_chord / orbital_speed_km_s
  }
}
