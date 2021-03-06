#!/usr/bin/env bash

function read-var {
  local output
  output="${1}" && shift

  function export_var {
    local var="${1}"
    local value

    if [ "${#@}" -gt 1 ]; then
      value="${2}"
      eval "export ${var}=\"${value}\""
    elif [ "${#@}" -eq 1 ]; then
      eval "export ${var}"
    fi
  }

  local var
  local default_value
  local -a vars=("${output}")
  local -a candidate_vars=()
  local -a links=()

  local link
  local next_is_default=""
  local found_default_marker=""
  local value=""

  for var in "${@}"; do
    # Pull out the links
    if [[ "${var}" =~ ^@ ]]; then
      link="${var##@}"
      links+="${link}"
    elif [[ "${var}" = "--" ]]; then
      next_is_default=true
      found_default_marker=true
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
  elif [ -n "${found_default_marker}" ]; then
    export_var "${output}" "${default_value}"
  else
    echo "The no value was found for the variable \"${output}\". Tried \"${@}\"" >&2
    exit 1
  fi
}
