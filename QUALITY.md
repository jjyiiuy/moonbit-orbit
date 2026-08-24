# Quality and reproducibility

The repository keeps its validation path small and reproducible. Run the
following commands from the module root:

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon test --target native --deny-warn
moon check --target all --deny-warn
moon info
git diff --exit-code
moon run cmd/main
```

The test suite exercises orbital calculations, coordinate transforms, attitude
operations, mission planning, telemetry validation, communications estimates,
engineering units, numerical edge cases, and report generation. Boundary cases
include empty inputs, zero vectors, polar and antimeridian coordinates,
degenerate transfer geometry, invalid brackets, resource limits, eclipse
transitions, and invalid orbital elements.

`moon run cmd/main` provides a small end-to-end example and deterministic
benchmark checksums. The benchmark workload and checksum are reproducible;
wall-clock measurements depend on the host CPU, operating system, and selected
MoonBit backend, so performance comparisons should record those conditions.

GitHub Actions runs formatting, warning-denied checks, tests on the native
backend, all-target checking, generated-interface verification, the CLI smoke
test, and coverage reporting on Linux, macOS, and Windows.
