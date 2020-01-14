#!/usr/bin/env bash

[ -n "$DEBUG" ] && set -x
set -e
set -o pipefail

gem update --system
bundle update --bundler
