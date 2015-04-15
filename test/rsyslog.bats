#!/usr/bin/env bats

function setup {
  mkdir -p "${BATS_TMPDIR}/rsyslog"
  __TMPDIR="${BATS_TMPDIR}/rsyslog"

  # Make sure we are using gnu ln because we need the -T flag
  if [ -n "$(which gln)" ]; then
    LN="gln"
  else
    LN="ln"
  fi
}

function teardown {
  rm -rf "${__TMPDIR}"
}

@test "Creates a symlink from /var/run/rsyslog/log.sock to <prefix>/dev/log" {
  . ../helpers/rsyslog.sh

  # This triggers that the link is present
  mkdir -p "${__TMPDIR}/dev"
  touch "${__TMPDIR}/log.sock"

  link-rsyslog "${__TMPDIR}/log.sock" "${__TMPDIR}"

  [ -L "${__TMPDIR}/dev/log" ]
  [ "$(readlink "${__TMPDIR}/dev/log")" = "${__TMPDIR}/log.sock" ]
}
