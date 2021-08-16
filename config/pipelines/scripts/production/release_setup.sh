#!/usr/bin/env bash

set -e

# operation to make before the switch of the release folder
composer install

php bin/magento config:set dev/js/enable_js_bundling 1
php bin/magento config:set dev/js/minify_files 1
php bin/magento config:set dev/static/sign 0
php bin/magento config:set dev/js/merge_files 0

php bin/magento config:set dev/css/merge_css_files 1
php bin/magento config:set dev/css/minify_files 1

bin/magento deploy:mode:set production
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f
bin/magento cache:clean
bin/magento cache:flush