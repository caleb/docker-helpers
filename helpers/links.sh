#!/usr/bin/env bash

#
# read-link(output_prefix, link_name, default_port="", default_proto="tcp", required=false)
#
# Sets some environment variables with some defaults related to required network services.
#
# `output_prefix` is the variable prefix that will be used. For example, if the prefix is `POSTFIX` then
# the output variables will be:
#
#     * POSTFIX_ADDR
#     * POSTFIX_PORT
#     * POSTFIX_PROTO
#
# If you specify `required` as `true` then we test if the host in the resulting
# `_ADDR` environment variable exists, and if it doesn't we print a helpful message and return a non-zero result
#
# If you specify the environment variable AMBASSADOR=<some ambassador host> then that host will be used as the default instead of the host that is passed in
#
# Example:
#
# In a container where none of the output variables are overridden, and this link is read
#
#    read-link NGINX_PHP_FPM php-fpm 9000 tcp
#
# these variables will be set:
#
#    NGINX_PHP_FPM_ADDR=php-fpm
#    NGINX_PHP_FPM_PORT=9000
#    NGINX_PHP_FPM_PROTO=tcp
#
# The same, run in a container with the environment variable `NGINX_PHP_FPM_ADDR=ambassador`
#
#    NGINX_PHP_FPM_ADDR=ambassador
#    NGINX_PHP_FPM_PORT=9000
#    NGINX_PHP_FPM_PROTO=tcp
#
function read-link {
  local output_prefix="${1}"
  local link_name="${2}"
  local default_port="${3:-""}"
  local default_proto="${4:-""}"
  local required="${5:-false}"

  local addr_var="${output_prefix}_ADDR"
  local port_var="${output_prefix}_PORT"
  local proto_var="${output_prefix}_PROTO"
  local ambassador="${AMBASSADOR}"

  function export_var {
    local var="${1}"
    local value="${2}"

    eval "export ${var}=\"${value}\""
  }

  # If the *_ADDR var isn't set, assume the default
  if [ -z "${!addr_var}" ]; then
    # Use the ambassador if that variable is provided
    if [ -n "${AMBASSADOR}" ]; then
      export_var "${addr_var}" "${AMBASSADOR}"
    else
      export_var "${addr_var}" "${link_name}"
    fi
  fi

  if [ -z "${!port_var}" ]; then
    export_var "${port_var}" "${default_port}"
  fi

  if [ -z "${!proto_var}" ]; then
    export_var "${proto_var}" "${default_proto}"
  fi

  if [ "${required,,}" = "true" ]; then
    ping -c 1 "${!addr_var}" > /dev/null 2>&1
    if [ $? -eq 1 ]; then
      echo "Required host ${!addr_var} could not be reached"
      exit 1
    fi
  fi
}

#
# require-link(output_prefix, link_name, port, proto=tcp)
#
# require-link calls readlink with its parameters, but passes `true` for the `required` parameter
#
function require-link {
  local output_prefix="${1}"
  local link_name="${2}"
  local default_port="${3:-""}"
  local default_proto="${4:-""}"

  read-link "${output_prefix}" "${link_name}" "${default_port}" "${default_proto}" true
}
