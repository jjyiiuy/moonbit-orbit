# Source Notes

`moonbit-orbit` is original MoonBit source written for this repository.

The implemented formulas are standard astrodynamics relationships:

- two-body vis-viva equation
- Kepler equation for elliptical orbits
- Hohmann transfer delta-v estimates
- quaternion composition and vector rotation
- spherical ECI/ECEF/geodetic/topocentric geometry
- first-order J2 secular precession estimates

No third-party source code was copied into the project. The TLE parser is a small fixed-width parser written for this package. The SGP4-compatible surface is intentionally marked as a roadmap boundary rather than represented as a complete SGP4 implementation.
