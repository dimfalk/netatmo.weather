# skip ifs

skip_if_net_down <- function(){

  if(!curl::has_internet()){

    testthat::skip("Internet connection is not available. Skipping.")
  }
}



skip_if_host_down <- function(){

  if(!curl::nslookup("api.netatmo.com") == "51.145.143.28"){

    testthat::skip("api.netatmo.com is not available. Skipping.")
  }
}



skip_if_no_auth <- function() {

  if (!any(keyring::keyring_list()[["keyring"]] == "netatmo")) {

    testthat::skip("No authentication information available. Skipping.")
  }
}



skip_if_no_token <- function() {

  if (!exists(".sig")) {

    testthat::skip("No Oauth 2.0 token available. Skipping.")
  }
}
