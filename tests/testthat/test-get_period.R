test_that("Type and length as expected.", {

  expect_type(get_period(), "integer")

  expect_length(get_period(), 2)
})

test_that("Function working as intended.", {

  to <- lubridate::now() |> lubridate::floor_date(unit = "hour")

  from <- to - 60 * 5 * 1024

  expect_equal(get_period(), c(from, to) |> as.numeric())



  to <- lubridate::now() |> lubridate::floor_date(unit = "hour")

  from <- to - 60 * 60 * 1024

  expect_equal(get_period(res = 60), c(from, to) |> as.numeric())



  to <- lubridate::now() |> lubridate::floor_date(unit = "hour")

  from <- to - 60 * 60 * 24

  expect_equal(get_period(x = "recent"), c(from, to) |> as.numeric())



  expect_equal(get_period(x = c("2022-06-01", "2022-06-04")), c(1654034400, 1654293600))
})

test_that("Fallbacks working as intended.", {

  expect_warning(get_period(x = c("2021-01-01", "2022-01-01"), res = 60))
})
