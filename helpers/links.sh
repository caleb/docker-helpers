#!/usr/bin/env bash

#
# read_link(output_prefix, link_name, default_port="", default_proto="tcp", required=true)
#
# Looks for a linked container named `link_name` and
# sets envrionment variables `output_prefix`_ADDR, `output_prefix`_PORT, and
# `output_prefix`_PROTO based on the containers linked.
#
# If the variables `output_prefix`_port or `output_prefix`_addr are already set
# this does nothing (allowing the container runner to manually specify a host/port)
#
# The optional parameter `default_port` is the port to use to look for a link if
# a link by `link_name` isn't found. Setting `required` to true casuses the script
# to `exit 1` printing an error message. Set to `false` to allow missing links
#
# Example:
#
# In a container with the link `php-fpm` with a published port 8000 on ip 1.2.3.4:
#
#    read_link NGINX_PHP_FPM php-fpm 9000 tcp
#
# will result in:
#
#    NGINX_PHP_FPM_ADDR=1.2.3.4
#    NGINX_PHP_FPM_PORT=8000
#    NGINX_PHP_FPM_PROTO=tcp
#
# The same, run in a container with a link `fpm` with published port 9000 on 1.2.3.4:
#
#    NGINX_PHP_FPM_ADDR=1.2.3.4
#    NGINX_PHP_FPM_PORT=9000
#    NGINX_PHP_FPM_PROTO=tcp
#
# If run with a link named `fpm` on port 8000 on 1.2.3.4 an error will be printed
# and the script will exit with code 1.
#
function require_link {
  output_prefix="${1}"
  link_name="${2}"
  default_port="${3:-""}"
  default_proto="${4:-""}"

  read_link "${output_prefix}" "${link_name}" "${default_port}" "${default_proto}" true
}

function read_link {
  output_prefix="${1}"
  link_name="${2}"
  default_port="${3:-""}"
  default_proto="${4:-""}"
  required="${5:-false}"

  # Uppercase and convert - to _
  env_link_name="${link_name^^}"
  env_link_name="${env_link_name//-/_}"

  addr_var="${output_prefix}_ADDR"
  port_var="${output_prefix}_PORT"
  proto_var="${output_prefix}_PROTO"

  # If the PORT variable clashes with docker's default *_PORT, detect if the user
  # overrode it
  clobbers_docker_port_env=false
  if [ "${port_var}" = "${env_link_name}_PORT" ]; then
    clobbers_docker_port_env=true
  fi

  function export_var {
    var="${1}"
    value="${2}"
    clobber="${3:-false}"

    if [ $clobber = true ] || [ -z "${!var}" ]; then
      eval "export ${var}=\"${value}\""
    fi
  }

  # set the default port to the port specified by the user, if there is one
  if [ -n "${!port_var}" ]; then
    if [[ "${!port_var}" =~ ^[0-9]+$ ]]; then
      default_port="${!port_var}"
    elif [ $clobbers_docker_port_env = false ]; then
      # if we aren't clobbering the docker port variable (and thus it /should/ be
      # populated with somethin other than a numerb e.g. tcp://1.2.3.4:1234) make sure
      # the port is a number
      echo "You specified a port (via ${port_var}=${!port_var}) that is not a number" >&2
      exit 1
        elif [[ $clobbers_docker_port_env = true ]] && [[ ! "${!port_var}" =~ ^[^:]+://[^:]+:[0-9]+$ ]]; then
      # If we are clobbering the docker port variable, raise an error if it was set
      # to somethign besides the standard docker format
      echo "You specified a port (via ${port_var}=${!port_var}) that is not a number" >&2
      exit 1
    fi
  fi

  # set the default protocol to the protocol specified by the user, if there is one
  if [ -n "${!proto_var}" ]; then
    default_proto="${!proto_var}"
  elif [ -z "${default_proto}" ]; then
    # Just use tcp if the user hasn't specified a manual protocol
    default_proto="tcp"
  fi

  # If the user specified an address, use that
  if [ -n "${!addr_var}" ]; then
    # if a port is set, leave it be, else set it to the default port
    export_var "${port_var}" "${default_port}"
    # if a proto is set, leave it be, else set it to the default proto
    export_var "${proto_var}" "${default_proto}" $clobbers_docker_port_env

    return
  fi

  # Test if the link with the given name exists
  link_test_var="${env_link_name}_NAME"
  link_first_addr_var="${env_link_name}_PORT"
  if [ -n "${!link_test_var}" ]; then
    link_port_var="${env_link_name}_PORT_${default_port}_${default_proto^^}"

    # If the link exists, use the value of that to export the variables
    link_port_value="${!link_port_var}"
    if [ -n "${link_port_value}" ]; then
      proto="${link_port_value%%://*}"
      addr="${link_port_value#*://}"
      addr="${addr%:*}"
      port="${link_port_value##*:}"

      export_var "${addr_var}" "${addr}"
      export_var "${port_var}" "${port}" $clobbers_docker_port_env
      export_var "${proto_var}" "${proto}"
    elif [ $clobbers_docker_port_env = false ] && [ -n "${!link_first_addr_var}" ]; then
      link_first_addr_value="${!link_first_addr_var}"
      # If the link exists, but the default port was not found, check to see the first port that was exposed
      proto="${link_first_addr_value%%://*}"
      addr="${link_first_addr_value#*://}"
      addr="${addr%:*}"
      port="${link_first_addr_value##*:}"

      export_var "${addr_var}" "${addr}"
      export_var "${port_var}" "${port}" $clobbers_docker_port_env
      export_var "${proto_var}" "${proto}"
    else
      echo "The port ${default_port} isn't exported by the container '${link_name}' on the ${default_proto} protocol" >&2
      exit 1
    fi
  fi

  # if we require this link, print an error and exit if all the properties aren't set
  if [ "${required}" = "true" ] || [ "${required}" = "yes" ]; then
    if [ -z "${!addr_var}" ] || [ -z "${!port_var}" ] || [ -z "${!proto_var}" ]; then
      echo "You must specify a link named ${link_name} running at port ${default_port} or specify the variables ${output_prefix}_ADDR (and optionally ${output_prefix}_PORT and ${output_prefix}_PROTO)" >&2
      exit 1
    fi
  fi
}
