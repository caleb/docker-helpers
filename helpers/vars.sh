#!/usr/bin/env bash

function read-var {
  output="${1}" && shift

  function export_var {
    var="${1}"

    if [ "${#@}" -gt 1 ]; then
      value="${2}"
      eval "export ${var}=\"${value}\""
    elif [ "${#@}" -eq 1 ]; then
      eval "export ${var}"
    fi
  }

  # if the output variable is already set, just export it
  if [ -n "${!output}" ]; then
    export_var "${output}"
    return
  fi

  local default_value=""
  declare -a vars=()

  local next_is_default=""
  local value=""

  for var in ${@}; do
    value="${!var}"
    if [ "${var}" = "--" ]; then
      next_is_default=true
      continue
    fi

    if [ -n "${next_is_default}" ]; then
      default_value="${var}"
      break
    fi

    if [ -n "${value}" ]; then
      value="${value}"
      break
    fi
  done

  if [ -n "${value}" ]; then
    export_var "${output}" "${value}"
  elif [ -n "${default_value}" ]; then
    export_var "${output}" "${default_value}"
  else
    echo "The no value was found for the variable \"${output}\". Tried \"${@}\"" >&2
    exit 1
  fi
}
