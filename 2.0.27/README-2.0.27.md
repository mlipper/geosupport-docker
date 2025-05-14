# geosupport-docker v2.0

Dockerfiles for installing, configuring and using the NYC Department of City Planning's Geosupport application from a Docker container.

## NEWS

### Upcoming Changes to Hosted Geoclient Services

This fall, all Geoclient service endpoints (URLs) are being consolidated into a single endpoint hosted in the Azure cloud.

**IMPORTANT:** *In order to avoid service disruption, your application **MUST** be using the new Geoclient v2 endpoint (URL) by **October 1st, 2025**.* 
On October 1st:

* *All Geoclient services (v1 & v2) hosted from OTI's on-premise datacenters will be disconnected.*
* *All Geoclient v1 endpoints (cloud-hosted included) will be removed.*

See [Upcoming Changes to Hosted Geoclient Services](https://mlipper.github.io/geoclient/docs/current/user-guide/changes.html) for:

* Detailed information on affected service endpoints (URLs)
* Instructions on getting access to the new Geoclient v2 cloud-hosted endpoint (URL)
* Technical considerations on switching to the new endpoint (URL)

### May 20, 2025

* **Version 2.0.27 available.** This release wraps `Geosupport 25b_25.2`.

  From the Department of City Planning's [Geosupport System User Bulletin 25-02](https://s-media.nyc.gov/agencies/dcp/assets/files/pdf/data-tools/bytes/geosupport-bulletin/geosupport-user-bulletin-2502.pdf):

    > Release `25B` includes street name/code deletions, changes, and additions as well as changes to property-related, building-related, and other types of geography. Many of the street name/code deletions, changes, and additions included in Release 25B are related to educational facility nomenclature.  These modifications are part of a multi-cycle research effort to make additional city schools, both public and private, traceable in Geosupport to adhere to public safety protocols.

  According to the bulletin, there are no Geosupport code changes for version `25.2`.

  **CHANGES:**

  * Feature
  * Issue #8 - "Add pass-through actions to release.sh for calling build.sh." implemented.
