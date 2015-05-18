#!/usr/bin/env bats

@test "Default link name using the default port" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_9000_TCP=tcp://1.2.3.4:9000
  PHP_FPM_PORT=tcp://1.2.3.4:9000

  read-link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "php-fpm" ]
  [ "${TEST_PORT}" = "9000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a specified port that's different from the first published" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_8000_TCP=tcp://1.2.3.4:8000
  PHP_FPM_PORT=tcp://1.2.3.4:7000

  read-link TEST php-fpm 8000 tcp

  [ "${TEST_ADDR}" = "php-fpm" ]
  [ "${TEST_PORT}" = "8000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a manually overridden port" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  TEST_PORT=7000

  read-link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "php-fpm" ]
  [ "${TEST_PORT}" = "7000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Output prefix is the same as the link name without a default port or proto" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_9000_TCP=tcp://1.2.3.4:9000
  PHP_FPM_PORT=tcp://1.2.3.4:9000

  read-link PHP_FPM php-fpm

  [ "${PHP_FPM_ADDR}" = "php-fpm" ]
  [ "${PHP_FPM_PORT}" = "9000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Output prefix is the same as the link name" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_9000_TCP=tcp://1.2.3.4:9000
  PHP_FPM_PORT=tcp://1.2.3.4:9000

  read-link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "php-fpm" ]
  [ "${PHP_FPM_PORT}" = "9000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Output prefix is the same as the link name with an overridden port" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  PHP_FPM_PORT=7000

  read-link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "php-fpm" ]
  [ "${PHP_FPM_PORT}" = "7000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Detects a link based on port when the link name is not found, and an ambassador is not being used" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_NAME=/test/php-fpm
  PHP_PORT_9000_TCP=tcp://1.2.3.4:9000
  PHP_PORT=tcp://1.2.3.4:8000
  PHP_ENV_MY_ENVIRONMENT_VARIABLE=ohhai

  read-link OUT does-not-exist-php-fpm 9000 tcp

  [ "${OUT_ADDR}" = "php-fpm" ]
  [ "${OUT_PORT}" = "9000" ]
  [ "${OUT_PROTO}" = "tcp" ]
  [ "${OUT_ENV_MY_ENVIRONMENT_VARIABLE}" = "ohhai" ]
}

@test "Detects a link based on an overridden port when the link name is not found, and an ambassador is not being used" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_NAME=/test/php-fpm
  PHP_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_PORT=tcp://1.2.3.4:8000
  PHP_ENV_MY_ENVIRONMENT_VARIABLE=ohhai

  OUT_PORT=7000

  read-link OUT does-not-exist-php-fpm 9000 tcp

  [ "${OUT_ADDR}" = "php-fpm" ]
  [ "${OUT_PORT}" = "7000" ]
  [ "${OUT_PROTO}" = "tcp" ]
  [ "${OUT_ENV_MY_ENVIRONMENT_VARIABLE}" = "ohhai" ]
}

@test "Error when output prefix is the same as the link name with an overridden port that is not published" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT_8000_TCP=tcp://1.2.3.4:8000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  PHP_FPM_PORT=9000

  run read-link PHP_FPM php-fpm 8000 tcp

  [ "${status}" -ne 0 ]
}

@test "An overridden address, but not port with a container that exists" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:7000

  # The user overridden port
  PHP_FPM_ADDR=2.3.4.5

  read-link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "2.3.4.5" ]
  [ "${PHP_FPM_PORT}" = "7000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "An overridden address, but not port with a container that does not exist" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # The user overridden port
  PHP_FPM_ADDR=2.3.4.5

  read-link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "2.3.4.5" ]
  [ "${PHP_FPM_PORT}" = "9000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "An overridden address, make sure the environment variables are exported" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:7000
  PHP_FPM_ENV_MYVAR=myval

  # The user overridden port
  PHP_FPM_ADDR=2.3.4.5

  read-link MYPREFIX php-fpm 9000 tcp

  [ "${MYPREFIX_ENV_MYVAR}" = "myval" ]
}

@test "A completely overridden address" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  PHP_FPM_ADDR=2.3.4.5
  PHP_FPM_PORT=2222
  PHP_FPM_PROTO=udp

  read-link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "2.3.4.5" ]
  [ "${PHP_FPM_PORT}" = "2222" ]
  [ "${PHP_FPM_PROTO}" = "udp" ]
}

@test "Doesn't error out when a required link doesn't publish a port and the user doesn't specify a port" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm

  run require-link PHP_FPM php-fpm

  [ "${status}" -eq 0 ]
}

@test "Exports linked environment variables" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_ENV_SOME_VAR="some val"
  PHP_FPM_ENV_ANOTHER_VAR="another val"

  read-link MY_PREFIX php-fpm

  [ "${MY_PREFIX_ENV_SOME_VAR}" = "some val" ]
  [ "${MY_PREFIX_ENV_ANOTHER_VAR}" = "another val" ]
}

@test "Exports linked environment variables when output prefix clobbers the link name" {
  . ../helpers/links.sh

  AMBASSADOR_NAME=/test/ambassador

  # This triggers that the link is present
  PHP_FPM_NAME=/test/php-fpm
  PHP_FPM_ENV_SOME_VAR="some val"
  PHP_FPM_ENV_ANOTHER_VAR="another val"

  read-link PHP_FPM php-fpm

  [ "${PHP_FPM_ENV_SOME_VAR}" = "some val" ]
  [ "${PHP_FPM_ENV_ANOTHER_VAR}" = "another val" ]
}

@test "Uses a manually specified ambassador if one is present and a manual link is not found" {
  . ../helpers/links.sh

  # This triggers that the link is present
  MY_AMBASSADOR_NAME=/test/my-ambassador
  AMBASSADOR=my-ambassador

  read-link PHP_FPM php-fpm 7000 tcp

  [ "${PHP_FPM_ADDR}" = "my-ambassador" ]
  [ "${PHP_FPM_PORT}" = "7000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Uses a manually specified ambassador and an overridden port if one is found" {
  . ../helpers/links.sh

  # This triggers that the link is present
  MY_AMBASSADOR_NAME=/test/my-ambassador
  AMBASSADOR=my-ambassador
  PHP_FPM_PORT=8000

  read-link PHP_FPM php-fpm 7000 tcp

  [ "${PHP_FPM_ADDR}" = "my-ambassador" ]
  [ "${PHP_FPM_PORT}" = "8000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Uses an implied ambassador named \"ambassador\" if one is present and a manual link is not found" {
  . ../helpers/links.sh

  # This triggers that the link is present
  AMBASSADOR_NAME=/test/ambassador

  read-link PHP_FPM php-fpm 7000 tcp

  [ "${PHP_FPM_ADDR}" = "ambassador" ]
  [ "${PHP_FPM_PORT}" = "7000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Uses an implied ambassador named \"ambassador\" and a manually overridden port if specified " {
  . ../helpers/links.sh

  # This triggers that the link is present
  AMBASSADOR_NAME=/test/ambassador
  PHP_FPM_PORT=8000

  read-link PHP_FPM php-fpm 7000 tcp

  [ "${PHP_FPM_ADDR}" = "ambassador" ]
  [ "${PHP_FPM_PORT}" = "8000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Errors when an ambassador is specified but not found" {
  . ../helpers/links.sh

  # This triggers that the link is present
  AMBASSADOR=my-ambassador

  run read-link PHP_FPM php-fpm 7000 tcp

  [ "${status}" -ne 0 ]
}
