test_that("Output class is as expected.", {

  expect_s3_class(unlist_response(r_list), c("sf", "tbl_df", "tbl", "data.frame"))
})

test_that("Column names are as expected.", {

  expect_equal(unlist_response(r_list) |> colnames(),
               c("status", "time_server", "base_station", "timezone", "country",
                 "altitude", "city", "street", "mark", "n_modules", "NAModule1",
                 "NAModule2", "NAModule3", "geometry"))
})

test_that("Dimensions are as expected.", {

  expect_equal((unlist_response(r_list) |> dim())[[2]], 14)
})
