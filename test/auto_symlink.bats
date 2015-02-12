#!/usr/bin/env bats

dir="${BATS_TMPDIR}/auto_symlinks"

function setup {
  mkdir -p "${dir}"

  # Make sure we are using gnu ln because we need the -T flag
  if [ -n "$(which gln)" ]; then
    LN="gln"
  else
    LN="ln"
  fi
}

@test "Creates symlinks from the default environment variable (SYMLINK)" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${dir}/source"

  SYMLINK="${dir}/source":"${dir}/dest"

  auto_symlink "" "${LN}"

  [ -L "${dir}/dest" ]
}

@test "Creates symlinks from multiple default-prefixed variables (SYMLINK_*)" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${dir}/source"
  mkdir -p "${dir}/source2"
  mkdir -p "${dir}/source3"

  SYMLINK_0="${dir}/source":"${dir}/dest"
  SYMLINK_1="${dir}/source2":"${dir}/dest2"
  SYMLINK_2="${dir}/source3":"${dir}/dest3"

  auto_symlink "" "${LN}"

  [ -L "${dir}/dest" ]
  [ -L "${dir}/dest2" ]
  [ -L "${dir}/dest3" ]
}

@test "Creates symlinks from a custom prefix" {
  . ../helpers/auto_symlink.sh

  mkdir -p "${dir}/source"
  mkdir -p "${dir}/source2"
  mkdir -p "${dir}/source3"

  MY_SYMLINK_0="${dir}/source":"${dir}/dest"
  MY_SYMLINK_1="${dir}/source2":"${dir}/dest2"
  MY_SYMLINK_2="${dir}/source3":"${dir}/dest3"

  auto_symlink "MY" "${LN}"

  [ -L "${dir}/dest" ]
  [ -L "${dir}/dest2" ]
  [ -L "${dir}/dest3" ]
}
