#!/usr/bin/env bash

# check and edit this path (public path of magento)

if [ ! -f app/etc/env.php ]
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

echo "✂️ remove cached stuff"
rm -rf pub/static/*
rm -rf var/view_preprocessed/*
rm -rf var/cache/*
rm -rf var/generation/*
rm -rf var/page_cache/*

echo "⚙️ compile things"
php bin/magento setup:di:compile
echo "👨🏼‍🚀 set shop to production mode"
php bin/magento deploy:mode:set production
echo "🪂 deploy compiled stuff"
php bin/magento setup:static-content:deploy
echo "👮🏻 fix access rights"
chmod 777 -R var pub generated
echo "🧹 running Magento clean cache commands"
php bin/magento cache:clean
php bin/magento cache:flush

#exit from user www
echo "♱ get back to root mode"
exit

#make stuff writable
echo "👮🏻 fix access rights"
chmod -R 777 .
chown -R www:www-data .