#!/usr/bin/env bash

set -e

# operation to make before the switch of the release folder
#bin/magento deploy:mode:set production
#
#php bin/magento config:set dev/js/enable_js_bundling 1
#php bin/magento config:set dev/js/minify_files 1
#php bin/magento config:set dev/static/sign 0
#php bin/magento config:set dev/js/merge_files 0
#
#php bin/magento config:set dev/css/merge_css_files 1
#php bin/magento config:set dev/css/minify_files 1
#
#bin/magento setup:upgrade
#bin/magento setup:di:compile
#bin/magento setup:static-content:deploy -f
#bin/magento cache:clean
#bin/magento cache:flush

echo "๐ฆ Copy env.php to release candidate dir!"
cp ../../../shared/magento/app/etc/env.php app/etc/env.php

echo "๐ผ Composer install"
php /usr/local/bin/composer --no-interaction --no-dev --no-progress install

echo "โ๏ธ remove cached stuff"
rm -rf pub/static/*
rm -rf var/view_preprocessed/*
rm -rf var/cache/*
rm -rf var/generation/*
rm -rf var/page_cache/*

echo "๐ฎ๐ป fix access rights"
chmod 777 -R var pub generated

echo "๐ Set setting to combine assets"
#https://devdocs.magento.com/guides/v2.4/frontend-dev-guide/themes/js-bundling.html
#https://devdocs.magento.com/guides/v2.4/config-guide/prod/config-reference-most.html
php bin/magento config:set dev/js/enable_js_bundling 1
php bin/magento config:set dev/js/minify_files 1
php bin/magento config:set dev/static/sign 0
php bin/magento config:set dev/js/merge_files 0

php bin/magento config:set dev/css/merge_css_files 1
php bin/magento config:set dev/css/minify_files 1

echo "๐ upgrade magento to new modules and stuff"
php bin/magento setup:upgrade --keep-generated

echo "๐จ๐ผโ๐ set shop to production mode"
php bin/magento deploy:mode:set production

echo "โ๏ธ compile things"
php bin/magento setup:di:compile
echo "๐ช deploy compiled stuff"
php bin/magento setup:static-content:deploy -f
echo "๐ฎ๐ป fix access rights"
chmod 777 -R var pub generated
echo "๐งน running Magento clean cache commands"
php bin/magento cache:clean
php bin/magento cache:flush
echo "โป๏ธ flushed cache"

#make stuff writable
echo "๐ฎ๐ป fix access rights"
chmod -R 777 .
chown -R www:www-data .
