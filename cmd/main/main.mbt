///|
fn print_line(label : String, value : Double, unit : String) -> Unit {
  println("\{label}: \{value} \{unit}")
}

///|
fn main {
  let leo = @orbit.circular_orbit(
    @orbit.earth_radius_km + 500.0,
    @orbit.radians(51.6),
  )
  let summary = @orbit.summarize_orbit(@orbit.earth_mu_km3_s2, leo)
  let transfer = @orbit.hohmann_transfer(
    @orbit.earth_mu_km3_s2,
    @orbit.earth_radius_km + 500.0,
    42164.0,
  )
  println("moonbit-orbit mission sketch")
  print_line("LEO period", summary.period_s / 60.0, "min")
  print_line("LEO mean motion", summary.mean_motion_rad_s, "rad/s")
  print_line("Hohmann total delta-v", transfer.delta_v_total_km_s, "km/s")
  print_line("Hohmann time of flight", transfer.time_of_flight_s / 3600.0, "h")
  let q = @orbit.Quaternion::from_axis_angle(
    @orbit.Vec3::new(0.0, 0.0, 1.0),
    @orbit.radians(30.0),
  )
  let body_x = q.rotate(@orbit.Vec3::new(1.0, 0.0, 0.0))
  println("rotated body-x: \{to_repr(body_x)}")
}
