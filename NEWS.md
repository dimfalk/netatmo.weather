# version 0.5.3

## features

- `set_device()` now allows to define arbitrary - but still valid! - MAC addresses to be used with `get_measure()`
- `as_datatable()` now allows to convert the list of xts objects returned by `get_measure()` to a single data.table object


## enhancements

- Credentials are now stored in the "netatmo" keyring
- `get_publicdata(tiles = TRUE)` and `get_measure()` now have a progress bar included
- `get_publicdata()` now allows to include observations fetched from API response when `meas = TRUE`


## bug fixes 

- attributes of sf object acquired by `get_publicdata()` are now assumed to be spatially constant
- internal pre-check `curl::nslookup("api.netatmo.com")` updated to recent public IP
- explicit and consistent `"Europe/Berlin"` timezone definition 
