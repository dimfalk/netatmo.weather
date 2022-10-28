test_that("Printing RT works.", {

  skip_if_no_token()

  expect_output(print_rt())

  expect_equal(print_rt() |> capture.output(), "&refresh_token=")
})
