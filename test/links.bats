#!/usr/bin/env bats

@test "Default link name using the default port" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_9000_TCP=tcp://1.2.3.4:9000
  PHP_FPM_PORT=tcp://1.2.3.4:9000

  read_link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "1.2.3.4" ]
  [ "${TEST_PORT}" = "9000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a specified port that's different from the first published" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_8000_TCP=tcp://1.2.3.4:8000
  PHP_FPM_PORT=tcp://1.2.3.4:7000

  read_link TEST php-fpm 8000 tcp

  [ "${TEST_ADDR}" = "1.2.3.4" ]
  [ "${TEST_PORT}" = "8000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Default link name with a manually overridden port" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  TEST_PORT=7000

  read_link TEST php-fpm 9000 tcp

  [ "${TEST_ADDR}" = "1.2.3.4" ]
  [ "${TEST_PORT}" = "7000" ]
  [ "${TEST_PROTO}" = "tcp" ]
}

@test "Output prefix is the same as the link name" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_9000_TCP=tcp://1.2.3.4:9000
  PHP_FPM_PORT=tcp://1.2.3.4:9000

  read_link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "1.2.3.4" ]
  [ "${PHP_FPM_PORT}" = "9000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Output prefix is the same as the link name with an overridden port" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  PHP_FPM_PORT=7000

  read_link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "1.2.3.4" ]
  [ "${PHP_FPM_PORT}" = "7000" ]
  [ "${PHP_FPM_PROTO}" = "tcp" ]
}

@test "Output prefix is the same as the link name with an overridden port that is not published" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:7000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  PHP_FPM_PORT=9000

  run read_link PHP_FPM php-fpm 8000 tcp

  [ "${status}" -eq 1 ]
}

@test "A completely overridden address" {
  . ../helpers/links.sh

  # This triggers that the link is present
  PHP_FPM_NAME=test/php-fpm
  PHP_FPM_PORT_7000_TCP=tcp://1.2.3.4:8000
  PHP_FPM_PORT=tcp://1.2.3.4:8000

  # The user overridden port
  PHP_FPM_ADDR=2.3.4.5
  PHP_FPM_PORT=2222
  PHP_FPM_PROTO=udp

  read_link PHP_FPM php-fpm 9000 tcp

  [ "${PHP_FPM_ADDR}" = "2.3.4.5" ]
  [ "${PHP_FPM_PORT}" = "2222" ]
  [ "${PHP_FPM_PROTO}" = "udp" ]
}
