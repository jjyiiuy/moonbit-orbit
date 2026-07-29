# moonbit-orbit

`moonbit-orbit` is a MoonBit library for small spacecraft mission analysis. It focuses on the calculations that appear again and again in early mission design: two-body orbits, Kepler propagation, transfer maneuvers, attitude quaternions, ground-station look angles, and a deliberately scoped TLE/SGP4 entry point.

The first release is not a flight-dynamics certification tool. It is a compact, readable foundation for MoonBit users who want reusable astrodynamics building blocks and a place to grow higher-fidelity models later.

## Why This Project

MoonBit already has strong infrastructure packages, parsers, async libraries, and application examples on Mooncakes. Before choosing this topic I checked Mooncakes for orbit/aerospace-related package names and did not find a mature, highly overlapping orbital mechanics library. The project is therefore positioned as an ecosystem gap: a reusable scientific/engineering library rather than another general utility package.

The scope is intentionally broader than a single formula module:

- orbital constants, angle helpers, and numeric utilities
- `Vec3` vector operations for mission geometry
- J2000-like epoch helper and Greenwich sidereal angle approximation
- classical orbital elements and inertial state conversion
- Kepler equation solving and two-body propagation
- circular, escape, vis-viva, Hohmann, bi-elliptic, and plane-change helpers
- quaternion attitude composition and vector rotation
- ECI/ECEF/geodetic/topocentric frame helpers
- ground-station visibility samples and contact-window collection
- J2 secular drift estimates for mean elements
- TLE parsing and mean-element conversion with explicit SGP4 roadmap

## Quick Start

Run the checks:

```bash
moon check --deny-warn
moon test --deny-warn
moon info
moon fmt --check
```

Run the example CLI:

```bash
moon run cmd/main
```

Expected output includes a low Earth orbit period, a LEO-to-GEO Hohmann transfer estimate, and a simple quaternion rotation sample.

## Minimal Example

```mbt check
///|
test {
  let leo = circular_orbit(earth_radius_km + 500.0, radians(51.6))
  let summary = summarize_orbit(earth_mu_km3_s2, leo)
  assert_true(summary.period_s > 5600.0 && summary.period_s < 5700.0)

  let transfer = hohmann_transfer(
    earth_mu_km3_s2,
    earth_radius_km + 500.0,
    42164.0,
  )
  assert_true(transfer.delta_v_total_km_s > 3.7)
}
```

## Package Layout

- `constants.mbt`: physical constants and angle helpers
- `vector.mbt`: three-dimensional vector operations
- `time.mbt`: epoch and sidereal-time helper
- `orbit.mbt`: orbital elements, state conversion, Kepler solver, two-body propagation
- `transfer.mbt`: maneuver and transfer calculations
- `attitude.mbt`: quaternions and Euler angle conversion
- `frames.mbt`: ECI/ECEF/geodetic/topocentric transformations
- `ground_station.mbt`: visibility samples and contact windows
- `perturbation.mbt`: J2 secular-rate utilities
- `sgp4.mbt`: TLE parser and SGP4 extension boundary
- `cmd/main`: runnable mission sketch
- `orbit_wbtest.mbt`: core tests

Generated interface files from `moon info` are committed so API changes can be reviewed directly.

## Accuracy Notes

- Distances are in kilometers; velocities are in kilometers per second.
- Angles are radians unless a helper explicitly says otherwise.
- The Earth model is spherical except where J2 secular estimates are used.
- `gmst` is a compact approximation tied to the local `Epoch` type.
- `parse_tle` handles common fixed-width TLE fields and returns `Result` instead of throwing.
- `sgp4_status()` states the current boundary: TLE parsing and mean-element conversion are present; the full SGP4 force model is reserved for a compatible future package.

## Competition Readiness

This repository is prepared for the MoonBit August hackathon/open ecosystem track:

- public MoonBit source with a clear, reusable library boundary
- Apache-2.0 license
- CI workflow for formatting, warning-denied checking, `moon info`, tests, and multi-target sanity checks
- more than ten meaningful commits planned in public history
- no copied third-party implementation code
- no generated or fictional contributors
- README, source notes, and roadmap included

## Roadmap

1. Add a complete SGP4 propagator behind the existing TLE API.
2. Add WGS84 ellipsoid geodetic conversion.
3. Add Lambert transfer solving for interplanetary and rendezvous planning.
4. Add eclipse and beta-angle helpers.
5. Add a Mooncakes release once API names stabilize.

## Source And Originality

The implementation is original MoonBit code written for this repository. It uses standard astrodynamics formulas such as Kepler's equation, vis-viva, Hohmann transfer, quaternion rotation, and J2 secular drift. No external source files were copied or translated line-by-line.

## License

Apache-2.0.
