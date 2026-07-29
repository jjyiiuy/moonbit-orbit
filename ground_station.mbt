///|
pub struct GroundStation {
  name : String
  location : Geodetic
  min_elevation_rad : Double
} derive(Debug, Eq)

///|
pub struct VisibilitySample {
  epoch : Epoch
  look : LookAngle
  visible : Bool
} derive(Debug, Eq)

///|
pub struct VisibilityWindow {
  start : Epoch
  end : Epoch
  max_elevation_rad : Double
  closest_range_km : Double
} derive(Debug, Eq)

///|
pub fn GroundStation::new(
  name : String,
  latitude_rad : Double,
  longitude_rad : Double,
  altitude_km? : Double = 0.0,
  min_elevation_rad? : Double = radians(5.0),
) -> GroundStation {
  {
    name,
    location: Geodetic::new(latitude_rad, longitude_rad, altitude_km),
    min_elevation_rad,
  }
}

///|
pub fn sample_visibility(
  station : GroundStation,
  epoch : Epoch,
  satellite_eci_km : Vec3,
) -> VisibilitySample {
  let look = look_angle_from_eci(station.location, epoch, satellite_eci_km)
  { epoch, look, visible: look.elevation_rad >= station.min_elevation_rad }
}

///|
pub fn sample_kepler_visibility(
  mu : Double,
  station : GroundStation,
  start : Epoch,
  elements : ClassicalElements,
  step_s : Double,
  count : Int,
) -> Array[VisibilitySample] {
  let samples : Array[VisibilitySample] = []
  for k in 0..<count {
    let epoch = start.add_seconds(Double::from_int(k) * step_s)
    let advanced = propagate_kepler(mu, elements, start.duration_to(epoch))
    let state = elements_to_state(mu, advanced)
    samples.push(sample_visibility(station, epoch, state.position_km))
  }
  samples
}

///|
pub fn collect_visibility_windows(
  samples : ArrayView[VisibilitySample],
) -> Array[VisibilityWindow] {
  let windows : Array[VisibilityWindow] = []
  let mut active = false
  let mut start = Epoch::j2000()
  let mut end = Epoch::j2000()
  let mut max_el = -half_pi
  let mut min_range = 1.0e30
  for sample in samples {
    if sample.visible {
      if !active {
        active = true
        start = sample.epoch
        max_el = sample.look.elevation_rad
        min_range = sample.look.range_km
      }
      end = sample.epoch
      if sample.look.elevation_rad > max_el {
        max_el = sample.look.elevation_rad
      }
      if sample.look.range_km < min_range {
        min_range = sample.look.range_km
      }
    } else if active {
      windows.push({
        start,
        end,
        max_elevation_rad: max_el,
        closest_range_km: min_range,
      })
      active = false
    }
  }
  if active {
    windows.push({
      start,
      end,
      max_elevation_rad: max_el,
      closest_range_km: min_range,
    })
  }
  windows
}

///|
pub fn is_line_of_sight_clear(site_ecef : Vec3, satellite_ecef : Vec3) -> Bool {
  let rho = satellite_ecef.sub(site_ecef)
  let projection = site_ecef.dot(rho)
  projection > 0.0
}
