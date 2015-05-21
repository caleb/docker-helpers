#!/usr/bin/env bash

#
# read-link(output_prefix, link_name, default_port="", default_proto="tcp", required=false)
#
# Looks for a linked container named `link_name` and
# sets envrionment variables `output_prefix`_ADDR, `output_prefix`_PORT, and
# `output_prefix`_PROTO based on the containers linked.
#
# This function also exports an associative array of the environment variables set
# in the linked container
#
# If the variables `output_prefix`_port or `output_prefix`_addr are already set
# this does nothing (allowing the container runner to manually specify a host/port)
#
# The optional parameter `default_port` is the port to use to look for a link if
# a link by `link_name` isn't found. Setting `required` to true casuses the script
# to `exit 1` printing an error message. Set to `false` to allow missing links
#
# If an ambassador pattern is being used, you can specify the ambassador with the
# AMBASSADOR variable. Specify the alias of your ambassador link.
#
# If you don't specify an ambassador explicitly and a container link named
# "ambassador" is found, then that acts as a fallback
#
# Example:
#
# In a container with the link `php-fpm` with a published port 8000 on ip 1.2.3.4:
#
#    read-link NGINX_PHP_FPM php-fpm 9000 tcp
#
# will result in:
#
#    NGINX_PHP_FPM_ADDR=1.2.3.4
#    NGINX_PHP_FPM_PORT=8000
#    NGINX_PHP_FPM_PROTO=tcp
#    NGINX_PHP_ENV_<variable name>=<value>
#
# The same, run in a container with a link `fpm` with published port 9000 on 1.2.3.4:
#
#    NGINX_PHP_FPM_ADDR=1.2.3.4
#    NGINX_PHP_FPM_PORT=9000
#    NGINX_PHP_FPM_PROTO=tcp
#    NGINX_PHP_ENV_<environment variable name>=<value>
#
# If run with a link named `fpm` on port 8000 on 1.2.3.4 an error will be printed
# and the script will exit with code 1.
#
function read-link {
  # Turns a lowercased, dasherized string into an environment variable
  # my-volume-name -> MY_VOLUME_NAME
  function environmentalize {
    local v="${1^^}"
    v="${v//-/_}"
    printf "${v}"
  }

  function hostname_from_link_var {
    if [[ "${1}" =~ ^/[^/]+/(.*)$ ]]; then
      printf "${BASH_REMATCH[1]}"
    else
      printf ""
    fi
  }

  output_prefix="${1}"
  link_name="${2}"
  default_port="${3:-""}"
  default_proto="${4:-""}"
  required="${5:-false}"

  env_link_name="$(environmentalize "${link_name}")"

  local addr_var="${output_prefix}_ADDR"
  local port_var="${output_prefix}_PORT"
  local proto_var="${output_prefix}_PROTO"

  local link_test_var="${env_link_name}_NAME"
  local link_default_port_var="${env_link_name}_PORT"

  function export_var {
    var="${1}"
    value="${2}"

    eval "export ${var}=\"${value}\""
  }

  function export_port {
    port_spec="${1}"
    link_var_value="${2}"

    proto="${port_spec%%://*}"
    addr="${port_spec#*://}"
    addr="${addr%:*}"
    port="${port_spec##*:}"

    if [ -n "${link_var_value}" ]; then
      export_var "${addr_var}" "$(hostname_from_link_var "${link_var_value}")"
    else
      export_var "${addr_var}" "${addr}"
    fi
    export_var "${port_var}" "${port}"
    export_var "${proto_var}" "${proto}"
  }

  # Determine the port to check for
  declare -a ports
  ports=()
  if [ -n "${default_port}" ]; then
    # default to the port specified by the caller
    ports=($ports "${default_port}")
  fi

  if [[ "${!link_default_port_var}" =~ ^[^:]+://[^:]+:([0-9]+)$ ]]; then
    # If a default link port exists and is in the right format, grab it
    ports=($ports "${BASH_REMATCH[1]}")
  fi

  # set the default port to the port specified by the user, if there is one
  # or use the first exported port found
  if [ -n "${!port_var}" ]; then
    if [[ "${!port_var}" =~ ^[0-9]+$ ]]; then

      ports=("${!port_var}")
    elif [ "${link_default_port_var}" != "${port_var}" ] || \
           [[ ! "${!port_var}" =~ ^[^:]+://[^:]+:([0-9]+)$ ]]; then
      # If we are clobbering the docker port variable, raise an error if it was set
      # to something besides the standard docker format
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

  # Determine the default port to use
  if [ -n "${!link_test_var}" ]; then
    port_found=""
    # Loop through the possible ports and find the first one that is exported
    for port in "${ports[@]}"; do
      link_port_var="${env_link_name}_PORT_${port}_${default_proto^^}"
      if [ -n "${!link_port_var}" ]; then
        port_found="${port}"
        break
      fi
    done

    if [ -n "${port_found}" ]; then
      default_port="${port_found}"
    elif [ -n "${!addr_var}" ]; then
      # If they specified an address, and no port was found in the linked container
      # then just use the first port since we can't determine if the port is open
      # on the target machine
      default_port="${ports[0]}"
    else
      # Use the first port in the list, we may error out later depending on
      # other variables
      default_port="${ports[0]}"
    fi
  else
    # Just use the first port as our default port
    default_port="${ports[0]}"
  fi

  # If the user specified an address, we can exit early since we have everything
  # we need
  if [ -n "${!addr_var}" ]; then
    # Set the PORT variable to the default port
    export_var "${port_var}" "${default_port}"
    # if a proto is set, leave it be, else set it to the default proto
    export_var "${proto_var}" "${default_proto}"
  elif [ -n "${!link_test_var}" ] && [ -n "${default_port}" ]; then
    # If a link exists with the candidate name, and we are looking for a port, test
    # to ensure that container exports that port
    link_port_var="${env_link_name}_PORT_${default_port}_${default_proto^^}"

    # If the link exists, use the value of that to export the variables
    link_port_value="${!link_port_var}"

    # If the specified container IS an ambassador, allow the port to be
    # un-exported and plow ahead
    container_is_ambassador_test_var="${env_link_name}_ENV___AMBASSADOR__"
    if [ -n "${link_port_value}" ]; then
      export_port "${link_port_value}" "${!link_test_var}"
    elif [ -n "${!container_is_ambassador_test_var}" ]; then
      export_var "${addr_var}" "$(hostname_from_link_var "${!link_test_var}")"
      export_var "${port_var}" "${default_port}"
      export_var "${proto_var}" "${default_proto}"
    else
      echo "The port ${default_port} isn't published by the container '${link_name}' on the ${default_proto} protocol" >&2
      exit 1
    fi
  else
    #
    # Try to find an ambassador, falling back to sniffing the link based on the
    # port and protocol given
    #
    if [ -n "${default_port}" ] && [ -n "${default_proto}" ]; then
      ambassador_var="AMBASSADOR"
      ambassador_default="ambassador"
      ambassador_default_link_var="AMBASSADOR_NAME"

      # If the user manually specified an ambassador, use that one
      if [ -n "${!ambassador_var}" ]; then
        ambassador="${!ambassador_var}"
        ambassador_link_var="$(environmentalize "${ambassador}")_NAME"
        if [ -n "${!ambassador_link_var}" ]; then
          # if we found the ambassador named use that as the addr, downcased
          export_var "${addr_var}" "${ambassador,,}"
          export_var "${port_var}" "${default_port}"
          export_var "${proto_var}" "${default_proto}"
        else
          echo "You specified an ambassador but a linked ambassador named ${ambassador} was not found." >&2
          exit 1
        fi
      elif [ -n "${!ambassador_default_link_var}" ]; then
        # If the default ambassador "ambassador" was linked in, use that
        export_var "${addr_var}" "${ambassador_default}"
        export_var "${port_var}" "${default_port}"
        export_var "${proto_var}" "${default_proto}"
      else
        #
        # As a last resort, try to find a container that exposes the specified port
        #
        for var in $(compgen -v); do
          if [[ "${var}" =~ ^([A-Z0-9_]+)_PORT_${default_port}_${default_proto^^}$ ]]; then
            # Since we sniffed the link, set the link_name so we can set up the environment later
            env_link_name="${BASH_REMATCH[1]}"
            link_var="${env_link_name}_NAME"
            export_port "${!var}" "${!link_var}"
          fi
        done
      fi

      # A link with the specified name was not found
      # if we require this link, print an error and exit if all the properties aren't set
      if [ "${required}" = "true" ] || [ "${required}" = "yes" ]; then
        if [ -n "${default_port}" ]; then
          if [ -z "${!addr_var}" ] || [ -z "${!port_var}" ] || [ -z "${!proto_var}" ]; then
            echo "You must specify a link named ${link_name} running at port ${default_port} or specify the variables ${output_prefix}_ADDR (and optionally ${output_prefix}_PORT and ${output_prefix}_PROTO)" >&2
            exit 1
          fi
        else
          echo "You must specify a link named ${link_name}" >&2
          exit 1
        fi
      fi
    fi
  fi

  #
  # Set up the environment variables
  #
  env_prefix="${env_link_name}_ENV_"
  env_output_prefix="${output_prefix}_ENV_"
  eval "
for var in \${!${env_prefix}*}; do
  var_name=\"\${var/${env_prefix}/}\"
  export ${env_output_prefix}\${var_name}=\"\${!var}\"
done
"
}

#
# require-link(output_prefix, link_name, port, proto=tcp)
#
# require-link calls readlink with its parameters, but passes `true` for the `required` parameter
#
function require-link {
  output_prefix="${1}"
  link_name="${2}"
  default_port="${3:-""}"
  default_proto="${4:-""}"

  read-link "${output_prefix}" "${link_name}" "${default_port}" "${default_proto}" true
}
