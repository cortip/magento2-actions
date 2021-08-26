#!/usr/bin/env bash

set -e

export MAGE_RUN_CODE=default

PROJECT_PATH="$(pwd)"

cd $PROJECT_PATH/magento

php -dmemory_limit=-1 /usr/local/bin/composer install --no-dev --no-progress
chmod +x bin/magento

#mysqladmin -h mysql -u root -pmagento status

if [ $INPUT_ELASTICSUITE = 1 ]
then
  php -dmemory_limit=-1 bin/magento setup:install --admin-firstname="local" --admin-lastname="local" --admin-email="local@local.com" --admin-user="local" --admin-password="local123" --base-url="http://magento.build/" --backend-frontname="admin" --db-host="mysql" --db-name="magento" --db-user="root" --db-password="magento" --use-secure=0 --use-rewrites=1 --use-secure-admin=0 --session-save="db" --currency="EUR" --language="en_US" --timezone="Europe/Rome" --cleanup-database --skip-db-validation --es-hosts="elasticsearch:9200" --es-user="" --es-pass=""
elif [ $INPUT_ELASTICSEARCH = 1 ]
then
  php -dmemory_limit=-1 bin/magento setup:install --admin-firstname="local" --admin-lastname="local" --admin-email="local@local.com" --admin-user="local" --admin-password="local123" --base-url="http://magento.build/" --backend-frontname="admin" --db-host="mysql" --db-name="magento" --db-user="root" --db-password="magento" --use-secure=0 --use-rewrites=1 --use-secure-admin=0 --session-save="db" --currency="EUR" --language="en_US" --timezone="Europe/Rome" --cleanup-database --skip-db-validation --elasticsearch-host="elasticsearch" --elasticsearch-port=9200
else
  php -dmemory_limit=-1 bin/magento setup:install --admin-firstname="local" --admin-lastname="local" --admin-email="local@local.com" --admin-user="local" --admin-password="local123" --base-url="http://magento.build/" --backend-frontname="admin" --db-host="mysql" --db-name="magento" --db-user="root" --db-password="magento" --use-secure=0 --use-rewrites=1 --use-secure-admin=0 --session-save="db" --currency="EUR" --language="en_US" --timezone="Europe/Rome" --cleanup-database --skip-db-validation
fi

--key=magento \

#mysql < backups/magento.sql

php bin/magento config:set dev/js/enable_js_bundling 1
php bin/magento config:set dev/js/minify_files 1
php bin/magento config:set dev/static/sign 0
php bin/magento config:set dev/js/merge_files 0

php bin/magento config:set dev/css/merge_css_files 1
php bin/magento config:set dev/css/minify_files 1

php -dmemory_limit=-1 bin/magento setup:di:compile
#php -dmemory_limit=-1 bin/magento deploy:mode:set --skip-compilation production
php -dmemory_limit=-1 bin/magento deploy:mode:set production

bin/magento setup:static-content:deploy
#bin/magento setup:static-content:deploy en_US  -a adminhtml
#bin/magento setup:static-content:deploy fr_FR -f -s standard -a adminhtml
#bin/magento setup:static-content:deploy fr_FR -f -s standard  -t Creativestyle/theme-creativeshop

composer dump-autoload -o

rm app/etc/env.php
