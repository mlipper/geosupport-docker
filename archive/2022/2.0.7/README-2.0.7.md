# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### January 11th, 2023

* **Version 2.0.7 available.** This release wraps `Geosupport 22c_22.31`.

  **CHANGES:**

  * Data updates reflecting post-redistricting political boundary changes for City Council and Election districts that were implemented by the NYC Board of Elections on October 6th, 2022.
  * Version 22.31 is a special "intracycle" release that may not be immediately available for download directly from the Department of City Planning.
  * Fix for `exportDist` command of generated `build.sh` which did not account for the unversioned `tgz` file changed in `2.0.6`.
