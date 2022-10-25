test_that("Printing RT works.", {

  expect_output(print_rt())

  expect_equal(print_rt() |> capture.output(), "&refresh_token=3.1415926536")
})
