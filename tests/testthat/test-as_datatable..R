test_that("Output class is as expected.", {

  expect_s3_class(meas_temp60min_dt, c("data.table", "data.frame"))
})

test_that("Column names are as expected.", {

  expect_equal(meas_temp60min_dt |> colnames(),
               c("p_id", "time", "ta", "lon", "lat", "z"))
})

test_that("Column types are as expected.", {

  expect_equal(meas_temp60min_dt |> lapply(X = _, typeof) |> unlist(),
               c(p_id = "integer", time = "double", ta = "double", lon = "double",
                 lat = "double", z = "integer"))
})
