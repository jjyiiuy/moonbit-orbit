///|
pub struct BenchmarkResult {
  name : String
  iterations : Int
  checksum : Double
} derive(Debug, Eq)

///|
pub fn benchmark_kepler(iterations : Int) -> BenchmarkResult {
  let mut checksum = 0.0
  let count = iterations.max(0)
  for i in 0..<count {
    checksum += solve_kepler(Double::from_int(i) * 0.001, 0.2)
  }
  { name: "kepler-solver", iterations: count, checksum }
}

///|
pub fn benchmark_state_conversion(iterations : Int) -> BenchmarkResult {
  let mut checksum = 0.0
  let count = iterations.max(0)
  let elements = ClassicalElements::new(
    7000.0,
    0.01,
    radians(51.6),
    0.3,
    0.7,
    1.1,
  )
  for _ in 0..<count {
    checksum += elements_to_state(earth_mu_km3_s2, elements).position_km.norm()
  }
  { name: "state-conversion", iterations: count, checksum }
}

///|
pub fn benchmark_geodesy(iterations : Int) -> BenchmarkResult {
  let mut checksum = 0.0
  let count = iterations.max(0)
  let site = Geodetic::new(radians(35.0), radians(139.0), 0.1)
  for i in 0..<count {
    let position = geodetic_to_ecef_wgs84({
      ..site,
      longitude_rad: site.longitude_rad + Double::from_int(i) * 1.0e-5,
    })
    checksum += position.norm()
  }
  { name: "wgs84-conversion", iterations: count, checksum }
}

///|
pub fn benchmark_report(iterations : Int) -> Array[BenchmarkResult] {
  [
    benchmark_kepler(iterations),
    benchmark_state_conversion(iterations),
    benchmark_geodesy(iterations),
  ]
}
