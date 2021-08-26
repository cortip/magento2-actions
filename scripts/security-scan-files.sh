#!/usr/bin/env bash

set -e

export MAGE_RUN_CODE=default

PROJECT_PATH="$(pwd)"

cd $PROJECT_PATH/magento
/usr/local/bin/composer install --no-dev --no-progress

mwscan .


