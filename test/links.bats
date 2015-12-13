#!/usr/bin/env bats

@test "Default link name using the default port" {
  . ../helpers/links.sh

  read-link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "php-fpm" ]
  [ "${TEST_PORT}" = "9000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a manually overridden addr" {
  . ../helpers/links.sh

  # The user overridden port
  TEST_ADDR=other-host

  read-link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "other-host" ]
  [ "${TEST_PORT}" = "9000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a manually overridden port" {
  . ../helpers/links.sh

  # The user overridden port
  TEST_PORT=7000

  read-link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "php-fpm" ]
  [ "${TEST_PORT}" = "7000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a manually overridden proto" {
  . ../helpers/links.sh

  # The user overridden port
  TEST_PROTO=udp

  read-link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "php-fpm" ]
  [ "${TEST_PORT}" = "9000" ]
  [ "${TEST_PROTO}" = "udp" ]
}
