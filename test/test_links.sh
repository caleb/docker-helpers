#!/usr/bin/env bash

. bash-tap-bootstrap

plan tests 4

is "1" "1" "Test 0"
is "1" "1" "Test 1"
is "1" "1" "Test 2"
is "2" "1" "Test 3"
