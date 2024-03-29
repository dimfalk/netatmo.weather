test_that("Output class is as expected.", {

  expect_s3_class(set_device("70:ee:50:13:54:bc"), c("sf", "tbl_df", "tbl", "data.frame"))
})

test_that("Column names are as expected.", {

  expect_equal(set_device("70:ee:50:13:54:bc") |> colnames(),
               c("status", "time_server", "base_station", "timezone", "country",
                 "altitude", "city", "street", "mark", "n_modules", "NAModule1",
                 "NAModule2", "NAModule3", "geometry"))
})

test_that("Dimensions are as expected.", {

  expect_equal(set_device("70:ee:50:13:54:bc") |> dim(), c(1, 14))
})
