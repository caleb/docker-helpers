#!/usr/bin/env bash

#
# This function tests if this container is linked to an rsyslog container and links
# the /var/run/rsyslog/log.sock socket to /dev/log where everything expects it to be
#
function link_rsyslog {
  if [ -d /var/run/rsyslog ]; then
    ln -sf /var/run/rsyslog/log.sock /dev/log
  fi
}
