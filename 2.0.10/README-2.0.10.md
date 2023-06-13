# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### June 13th, 2023

* **Version 2.0.10 available.** This release wraps `Geosupport 23b_23.2`.

  **CHANGES:**

  * Make generated `geosupport` script idempotent and do not try to create sybolic links if they already exist.
