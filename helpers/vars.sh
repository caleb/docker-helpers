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

  local default_value=""
  declare -a vars=("${output}")
  declare -a candidate_vars=()
  declare -a links=()

  local next_is_default=""
  local value=""

  for var in "${@}"; do
    # Pull out the links
    if [[ "${var}" =~ ^@ ]]; then
      link="${var##@}"
      links+="${link}"
    elif [[ "${var}" = "--" ]]; then
      next_is_default=true
    elif [ -n "${next_is_default}" ]; then
      default_value="${var}"
      break
    else
      candidate_vars+=("${var}")
    fi
  done

  # We start our vars with the output var and candidate vars
  for var in "${candidate_vars[@]}"; do
    vars+=("${var}")
  done

  # Go through the links and add variants of the candidates with the link prefix
  for link in "${links[@]}"; do
    for var in "${candidate_vars[@]}"; do
      vars+=("${link}_ENV_${var}")
    done
  done

  for var in "${vars[@]}"; do
    if [ -n "${!var}" ]; then
      value="${!var}"
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
