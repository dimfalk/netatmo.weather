test_that("Output class is as expected.", {

  expect_s3_class(get_extent(x = c(6.89, 51.34, 7.13, 51.53)), c("sfc_POINT", "sfc"))
})

test_that("Function working as intended.", {

  expect_equal(get_extent(x = c(353034.1, 5689295.3, 370288.6, 5710875.9), epsg = 25832) |> sf::st_coordinates() |> as.numeric() |> head(10), c(353034.1, 370288.6, 370288.6, 353034.1, 353034.1, 5689295.3, 5689295.3, 5710875.9, 5710875.9, 5689295.3))

  expect_equal(get_extent(x = "Aachen") |> sf::st_coordinates() |> as.numeric() |> round(2) |> head(10), c(5.97, 6.22, 6.22, 5.97, 5.97, 50.64, 50.64, 50.86, 50.86, 50.64))

  expect_equal(get_extent(x = "52070") |> sf::st_coordinates() |> as.numeric() |> round(2) |> head(10), c(6.07, 6.12, 6.12, 6.07, 6.07, 50.77, 50.77, 50.81, 50.81, 50.77))
})

test_that("Fallbacks working as intended.", {

  expect_error(get_extent(x = "Freiburg"))

  expect_error(get_extent(x = "Aix La Chapelle"))

  expect_warning(get_extent(x = "Neuenkirchen"))

  expect_error(get_extent(x = "99999"))

  expect_error(get_extent(x = "02114568201"))
})
