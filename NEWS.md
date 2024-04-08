# version 0.5.20

## features

- `set_device()` now allows to define arbitrary - but still valid! - MAC addresses to be used with `get_measure()`
- `as_datatable()` now allows to convert the list of xts objects returned by `get_measure()` to a single data.table object


## enhancements

- `get_publicdata()` now allows to include observations fetched from API response when `meas = TRUE`
- `get_publicdata(tiles = TRUE)` and `get_measure()` now have a progress bar included
- `get_publicdata()` now returns a `"NAMain"` column instead of `"base_station"`, in compliance with official naming convention

- `get_measure()` now internally splitting up large queries exceeding 1024 values into chunks
- `get_measure()` now internally skipping iterations without data returned instead of failing
- `get_measure()` now warns the user if the number of queries exceeds 500 per hour, violating API guidelines
- `get_measure()` now returns xts objects coming with a `CREATED_WITH` and `CREATED_AT` attribute

- `set_credentials()` now stores the client id/secret making use of `{keyring}`
- `get_period()` now accepts intervals in accordance with ISO 8601, also taking `%H:%M` information into account


## bug fixes 

- attributes of sf object acquired by `get_publicdata()` are now assumed to be spatially constant
- internal pre-check `curl::nslookup("api.netatmo.com")` updated to recent public IP
- explicit and consistent `"UTC"` timezone definition 
- `get_measure()` does not dismiss the last value anymore, based on the period queried
