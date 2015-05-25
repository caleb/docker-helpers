#!/usr/bin/env bash

#
# This function tests if this container is linked to an rsyslog container and links
# the /var/run/rsyslog/log.sock socket to /dev/log where everything expects it to be
#
function link-rsyslog {
  local source="${1:-/var/run/rsyslog/log.sock}"
  local dest_prefix="${2:-}"

  if [ -d "$(dirname "${source}")" ]; then
    ln -sf "${source}" "${dest_prefix}"/dev/log
  fi
}

function has-rsyslog {
  # if /dev/log.sock exists and is a socket or a symlink that points to a socket
  if [ -S /dev/log ]; then
    return 0
  elif [ -L /dev/log ] && [ -S "$(readlink /dev/log)" ]; then
    return 0
  else
    return 1
  fi
}
