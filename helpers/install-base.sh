#!/usr/bin/env bash

#
# Install runit and monit
#
apt-get update
apt-get install -y monit runit curl socat msmtp
rm -rf /var/lib/apt/lists/*

#
# Install mo, the bash mustache templating engine
#
curl https://raw.githubusercontent.com/caleb/mo/master/mo > /usr/local/bin/mo
chmod +x /usr/local/bin/mo

#
# Install gosu
#
# grab gosu for easy step-down from root
gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
arch="$(dpkg --print-architecture)" \
	&& set -x \
	&& curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$arch" \
	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$arch.asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu
