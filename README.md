# geosupport-docker

Dockerfile for accessing Geosupport as a Docker data volume

Provides a "data-packed" volume which will download, unzip, patch and install
the specified release/version of Geosupport.

### Volumes

Populates managed volume `/opt/geosupport/server/current`.

#### About Geosupport

Geosupport is the City of New York's official geocoder of record. The
application is written and maintained by [the Department of City Planning](http://nyc.gov/planning).
