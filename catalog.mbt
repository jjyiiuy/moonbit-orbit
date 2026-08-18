///|
pub struct CatalogEntry {
  id : String
  name : String
  elements : ClassicalElements
  epoch_day : Double
  active : Bool
} derive(Debug, Eq)

///|
pub struct CatalogQuery {
  minimum_altitude_km : Double
  maximum_altitude_km : Double
  minimum_inclination_rad : Double
  maximum_inclination_rad : Double
  active_only : Bool
} derive(Debug, Eq)

///|
pub fn CatalogQuery::any() -> CatalogQuery {
  {
    minimum_altitude_km: -earth_radius_km,
    maximum_altitude_km: 1.0e9,
    minimum_inclination_rad: -two_pi,
    maximum_inclination_rad: two_pi,
    active_only: false,
  }
}

///|
pub fn CatalogQuery::leo() -> CatalogQuery {
  {
    minimum_altitude_km: 150.0,
    maximum_altitude_km: 2000.0,
    minimum_inclination_rad: -two_pi,
    maximum_inclination_rad: two_pi,
    active_only: true,
  }
}

///|
pub fn CatalogEntry::new(
  id : String,
  name : String,
  elements : ClassicalElements,
  epoch_day : Double,
  active? : Bool = true,
) -> CatalogEntry {
  { id, name, elements, epoch_day, active }
}

///|
pub fn catalog_altitude_km(entry : CatalogEntry) -> Double {
  entry.elements.semi_major_axis_km - earth_radius_km
}

///|
pub fn catalog_matches(query : CatalogQuery, entry : CatalogEntry) -> Bool {
  catalog_altitude_km(entry) >= query.minimum_altitude_km &&
  catalog_altitude_km(entry) <= query.maximum_altitude_km &&
  entry.elements.inclination_rad >= query.minimum_inclination_rad &&
  entry.elements.inclination_rad <= query.maximum_inclination_rad &&
  (!query.active_only || entry.active)
}

///|
pub fn filter_catalog(
  entries : Array[CatalogEntry],
  query : CatalogQuery,
) -> Array[CatalogEntry] {
  entries.filter(entry => catalog_matches(query, entry))
}

///|
pub fn sort_catalog_by_altitude(
  entries : Array[CatalogEntry],
) -> Array[CatalogEntry] {
  let result = entries.copy()
  for i in 0..<result.length() {
    for j in (i + 1)..<result.length() {
      if catalog_altitude_km(result[j]) < catalog_altitude_km(result[i]) {
        let swap = result[i]
        result[i] = result[j]
        result[j] = swap
      }
    }
  }
  result
}

///|
pub fn find_catalog_entry(
  entries : Array[CatalogEntry],
  id : String,
) -> CatalogEntry? {
  for entry in entries {
    if entry.id == id {
      return Some(entry)
    }
  }
  None
}

///|
pub fn catalog_names(entries : Array[CatalogEntry]) -> Array[String] {
  entries.map(entry => entry.name)
}

///|
pub fn catalog_altitude_stats(entries : Array[CatalogEntry]) -> SampleStats {
  summarize_samples(entries.map(catalog_altitude_km))
}

///|
pub fn catalog_period_stats(entries : Array[CatalogEntry]) -> SampleStats {
  summarize_samples(
    entries.map(entry => {
      orbital_period(earth_mu_km3_s2, entry.elements.semi_major_axis_km)
    }),
  )
}

///|
pub fn propagate_catalog(
  entries : Array[CatalogEntry],
  delta_t_s : Double,
) -> Array[CatalogEntry] {
  entries.map(entry => {
    ..entry,
    elements: propagate_kepler(earth_mu_km3_s2, entry.elements, delta_t_s),
  })
}

///|
pub fn catalog_merge(
  left : Array[CatalogEntry],
  right : Array[CatalogEntry],
) -> Array[CatalogEntry] {
  let result = left.copy()
  for entry in right {
    if find_catalog_entry(result, entry.id) is None {
      result.push(entry)
    }
  }
  result
}

///|
pub fn catalog_density(
  entries : Array[CatalogEntry],
  altitude_bin_km : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  if altitude_bin_km <= 0.0 {
    return result
  }
  for entry in entries {
    let bin = (catalog_altitude_km(entry) / altitude_bin_km).floor().to_int()
    while result.length() <= bin {
      result.push(0)
    }
    result[bin] += 1
  }
  result
}

///|
pub fn catalog_active_fraction(entries : Array[CatalogEntry]) -> Double {
  if entries.length() == 0 {
    0.0
  } else {
    Double::from_int(entries.filter(entry => entry.active).length()) /
    Double::from_int(entries.length())
  }
}
