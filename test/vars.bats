#!/usr/bin/env bats

@test "Reads a variable from the list specified and sticks it in the output variable if the output variable isn't already specified" {
  . ../helpers/vars.sh

  PHP_FPM_MAX_FILESIZE=10m

  read-var NGINX_PHP_CLIENT_MAX_BODY PHP_FPM_MAX_FILESIZE -- 8m

  [ "${NGINX_PHP_CLIENT_MAX_BODY}" = "10m" ]
}

@test "Reads the default value as the value if the variable isn't already specified and none of the candidate variables are found" {
  . ../helpers/vars.sh

  read-var NGINX_PHP_CLIENT_MAX_BODY PHP_FPM_MAX_FILESIZE -- 8m

  [ "${NGINX_PHP_CLIENT_MAX_BODY}" = "8m" ]
}

@test "Returns an error if no value is found" {
  . ../helpers/vars.sh

  run read-var NGINX_PHP_CLIENT_MAX_BODY PHP_FPM_MAX_FILESIZE

  [ "${status}" -ne 0  ]
}

@test "If the value is already specified don't change it" {
  . ../helpers/vars.sh

  NGINX_PHP_CLIENT_MAX_BODY=10m

  read-var NGINX_PHP_CLIENT_MAX_BODY PHP_FPM_MAX_FILESIZE -- 8m

  [ "${NGINX_PHP_CLIENT_MAX_BODY}" = "10m" ]
}
