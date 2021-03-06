#!/usr/bin/env bash

echo "post release script"

if [ ! -s app/etc/env.php ]
then
  echo "This is the first deploy? You must set magento env.php"
  exit 3
fi

chmod -R 775 .
chown -R www:www-data .
su - www

composer install

echo "Import magento config"
php bin/magento app:config:import --no-interaction

echo "Check setup:upgrade status"
# use --no-ansi to avoid color characters
message=$(php bin/magento setup:db:status --no-ansi)

if [[ ${message:0:3} == "All" ]]; then
  echo "No setup upgrade - clear cache";
  php bin/magento cache:clean
else
  echo "Run setup:upgrade - maintenance mode"
  php bin/magento maintenance:enable
  php bin/magento setup:upgrade --keep-generated
  php bin/magento maintenance:disable
  php bin/magento cache:flush
fi

php bin/magento deploy:mode:set development

#exit from user www
exit

#make stuff writable
chmod -R 777 .
chown -R www:www-data .