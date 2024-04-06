# version 0.5.18

## features

- `set_device()` now allows to define arbitrary - but still valid! - MAC addresses to be used with `get_measure()`
- `as_datatable()` now allows to convert the list of xts objects returned by `get_measure()` to a single data.table object


## enhancements

- Credentials are now stored in the "netatmo" keyring
- `get_publicdata(tiles = TRUE)` and `get_measure()` now have a progress bar included
- `get_publicdata()` now allows to include observations fetched from API response when `meas = TRUE`
- `get_measure()` now internally splitting up large queries exceeding 1024 values into chunks
- `get_measure()` now internally skipping iterations without data returned instead of failing
- `"base_station"` column returned by `get_publicdata()` renamed to `"NAMain"`, in compliance with official naming convention
- xts objects returned by `get_measure()` now come with a `CREATED_WITH` and `CREATED_AT` attribute
- `get_period()` now accepts intervals in accordance with ISO 8601, also taking `%H:%M` information into account


## bug fixes 

- attributes of sf object acquired by `get_publicdata()` are now assumed to be spatially constant
- internal pre-check `curl::nslookup("api.netatmo.com")` updated to recent public IP
- explicit and consistent `"UTC"` timezone definition 
- `get_measure()` does not dismiss the last value anymore, based on the period queried
