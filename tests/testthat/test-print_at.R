test_that("Printing AT works.", {

  skip_if_no_token()

  expect_output(print_at())

  expect_equal(print_at() |> capture.output(), "&access_token=")
})
