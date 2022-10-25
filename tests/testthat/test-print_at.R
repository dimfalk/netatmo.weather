test_that("Printing AT works.", {

  expect_output(print_at())

  expect_equal(print_at() |> capture.output(), "&access_token=6.2831853072")
})
