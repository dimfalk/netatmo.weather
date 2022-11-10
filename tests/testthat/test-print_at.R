test_that("Printing AT works.", {

  skip_if_no_token()

  skip_if_no_auth()

  expect_output(print_at())

  at <- cyphr::decrypt(readRDS(test_path("testdata", "at.rds")), k)

  expect_equal(print_at() |> capture.output(), paste0("&access_token=", at))
})
