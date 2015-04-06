#!/usr/bin/env bash

SYSLOG_FORWARDER_VERSION=1.0

#
# Install runit and monit
#
apt-get update
apt-get install -y monit runit curl
rm -rf /var/lib/apt/lists/*

#
# Install mo, the bash mustache templating engine
#
curl https://raw.githubusercontent.com/caleb/mo/master/mo > /usr/local/bin/mo

#
# Install syslog_forwarder
#
curl -L https://github.com/caleb/syslog_forwarder/releases/download/v${SYSLOG_FORWARDER_VERSION}/syslog_forwarder-linux-amd64-v${SYSLOG_FORWARDER_VERSION}.tar.gz > /tmp/syslog_forwarder.tar.gz

tar xzf /tmp/syslog_forwarder.tar.gz -C /usr/local/bin
rm /tmp/syslog_forwarder.tar.gz
