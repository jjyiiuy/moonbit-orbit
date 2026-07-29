///|
pub struct HohmannTransfer {
  radius_initial_km : Double
  radius_final_km : Double
  semi_major_axis_km : Double
  delta_v_departure_km_s : Double
  delta_v_arrival_km_s : Double
  delta_v_total_km_s : Double
  time_of_flight_s : Double
} derive(Debug, Eq)

///|
pub struct PlaneChange {
  speed_km_s : Double
  angle_rad : Double
  delta_v_km_s : Double
} derive(Debug, Eq)

///|
pub fn circular_speed(mu : Double, radius_km : Double) -> Double {
  (mu / radius_km).sqrt()
}

///|
pub fn escape_speed(mu : Double, radius_km : Double) -> Double {
  (2.0 * mu / radius_km).sqrt()
}

///|
pub fn vis_viva_speed(mu : Double, radius_km : Double, semi_major_axis_km : Double) -> Double {
  (mu * (2.0 / radius_km - 1.0 / semi_major_axis_km)).sqrt()
}

///|
pub fn hohmann_transfer(mu : Double, radius_initial_km : Double, radius_final_km : Double) -> HohmannTransfer {
  let a_t = (radius_initial_km + radius_final_km) / 2.0
  let v1 = circular_speed(mu, radius_initial_km)
  let v2 = circular_speed(mu, radius_final_km)
  let vt1 = vis_viva_speed(mu, radius_initial_km, a_t)
  let vt2 = vis_viva_speed(mu, radius_final_km, a_t)
  let dv1 = (vt1 - v1).abs()
  let dv2 = (v2 - vt2).abs()
  {
    radius_initial_km,
    radius_final_km,
    semi_major_axis_km: a_t,
    delta_v_departure_km_s: dv1,
    delta_v_arrival_km_s: dv2,
    delta_v_total_km_s: dv1 + dv2,
    time_of_flight_s: pi * (a_t * a_t * a_t / mu).sqrt(),
  }
}

///|
pub fn bi_elliptic_transfer_delta_v(
  mu : Double,
  radius_initial_km : Double,
  radius_final_km : Double,
  radius_intermediate_km : Double
) -> Double {
  let a1 = (radius_initial_km + radius_intermediate_km) / 2.0
  let a2 = (radius_final_km + radius_intermediate_km) / 2.0
  let dv1 = (vis_viva_speed(mu, radius_initial_km, a1) - circular_speed(mu, radius_initial_km)).abs()
  let dv2 = (vis_viva_speed(mu, radius_intermediate_km, a2) - vis_viva_speed(mu, radius_intermediate_km, a1)).abs()
  let dv3 = (circular_speed(mu, radius_final_km) - vis_viva_speed(mu, radius_final_km, a2)).abs()
  dv1 + dv2 + dv3
}

///|
pub fn plane_change(speed_km_s : Double, angle_rad : Double) -> PlaneChange {
  {
    speed_km_s,
    angle_rad,
    delta_v_km_s: 2.0 * speed_km_s * @math.sin(angle_rad / 2.0).abs(),
  }
}

///|
pub fn combined_plane_change(
  speed_before_km_s : Double,
  speed_after_km_s : Double,
  angle_rad : Double
) -> Double {
  (
    speed_before_km_s * speed_before_km_s +
    speed_after_km_s * speed_after_km_s -
    2.0 * speed_before_km_s * speed_after_km_s * @math.cos(angle_rad)
  ).sqrt()
}

///|
pub fn phasing_orbit_axis(mu : Double, target_period_s : Double) -> Double {
  let n = two_pi / target_period_s
  @math.pow(mu / (n * n), 1.0 / 3.0)
}
