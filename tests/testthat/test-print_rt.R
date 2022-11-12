skip_if_no_token()

skip_if_no_auth()

test_that("Printing RT works.", {

  expect_output(print_rt())

  rt <- cyphr::decrypt(readRDS(test_path("testdata", "rt.rds")), k)

  expect_equal(print_rt() |> capture.output(), paste0("&refresh_token=", rt))
})
