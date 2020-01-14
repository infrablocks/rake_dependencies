#!/usr/bin/env bash

[ -n "$DEBUG" ] && set -x
set -e
set -o pipefail

gem update --system
gem uninstall bundler
rm /usr/local/bin/bundle
rm /usr/local/bin/bundler
gem install bundler
