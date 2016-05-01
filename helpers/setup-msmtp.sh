#!/usr/bin/env bash

#
# Read MSMTP_* variables and create the config file
#
if [ ! -f /etc/msmtprc ]; then
  MSMTP_ALIASES="${MSMTP_ALIASES:-/etc/aliases}"

  echo "account default" > /etc/msmtprc
  for var in ${!MSMTP_*}; do
    msmtp_var="${var#MSMTP_}"
    msmtp_var="${msmtp_var,,}"
    msmtp_val="${!var}"

    # If the variable is an alias, add it to the aliases file
    if [[ "${msmtp_var}" =~ ^ALIAS.*$ ]]; then
      echo "${msmtp_val}" >> "${MSMTP_ALIASES}"
    else
      echo "${msmtp_var} ${msmtp_val}" >> /etc/msmtprc
    fi
  done
fi

# Link msmtp to /usr/sbin/sendmail to software can find it
if [ ! -f /usr/sbin/sendmail ]; then
  ln -s /usr/bin/msmtp /usr/sbin/sendmail
fi
