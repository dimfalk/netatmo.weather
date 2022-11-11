test_that("Creating a new keyring works.", {

  skip_on_cran()

  keyring::keyring_create(keyring = "rpkg-dev",
                          password = Sys.getenv("KEYRING_PASSWORD"))

  expect_true("rpkg-dev" %in% keyring::keyring_list()[["keyring"]])

  keyring::keyring_delete("rpkg-dev")
})


test_that("Messaging as expected.", {

  expect_no_error(set_credentials())

  expect_no_warning(set_credentials())

  expect_message(set_credentials())
})
