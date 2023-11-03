# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

The latest news about this project.

### November 21st, 2022

* **Version 2.0.5 available.** This release wraps `Geosupport 22c_22.3`.

  **CHANGES:**

  Deprecation notice per Department of City Planning[^1]:

  > * Sanborn Volume and Page Information (**DEPRECATED**)

  The following enhancements are available in this release[^2]:

  > * DSNY Commercial Waste Zones (**ADDED**)

[^1]: From the Department of City Planning's *Geosupport System User Bulletin 22-03.pdf*:
  "Please be informed that the Sanborn Volume and Page information returned in functions 1A, 2, BL, and BN of the Geosupport System has been deprecated, as no source data is available to maintain a reliable level of accuracy or currency."
  `Geosupport` and `Geoclient` will continue to return this information but it may be removed in future releases.

[^2]: DCP has added a new data field containing DSNY commercial waste zone designations for relevant centerline-based addresses. The new field will contain 4 characters consisting of the borough initials `MN`, `BX`, `BK`, `QN`, and `SI`, a one-digit number, and an optional suffix letter (currently `A` or `B`).
  `Geoclient` returns this information as `sanitationCommercialWasteZone` for relevant addresses.
