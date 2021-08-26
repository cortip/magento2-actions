#!/bin/bash

set -e


PROJECT_PATH="$(pwd)"


echo "project path is $PROJECT_PATH";

which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )
eval $(ssh-agent -s)
mkdir ~/.ssh/ && echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa
echo "$SSH_CONFIG" > /etc/ssh/ssh_config && chmod 600 /etc/ssh/ssh_config



echo "Create artifact and send to server!"

cd $PROJECT_PATH


echo "Deploying to production server";

mkdir -p deployer/scripts/
cp -R /opt/config/pipelines/scripts/production deployer/scripts/production

echo 'creating bucket dir'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "mkdir -p $HOST_DEPLOY_PATH_BUCKET"



tar cfz "$BUCKET_COMMIT" deployer/scripts/production magento
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  "$BUCKET_COMMIT" production:$HOST_DEPLOY_PATH_BUCKET


cd /opt/config/php-deployer

echo 'Deploying production ...';


#create dirs if not exists first deploy



echo '------> Deploying bucket ...';
# deploy bucket
./vendor/bin/dep deploy-bucket production \
-o bucket-commit=$BUCKET_COMMIT \
-o host_bucket_path=$HOST_DEPLOY_PATH_BUCKET \
-o deploy_path_custom=$HOST_DEPLOY_PATH \
-o write_use_sudo=$WRITE_USE_SUDO

echo "------> cd $HOST_DEPLOY_PATH/release/magento/ && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/production/release_setup.sh";
# setup magento
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null production "cd $HOST_DEPLOY_PATH/release/magento/ && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/production/release_setup.sh"
echo '------> Done with release_setup.sh';


echo '------> Deploying release ...';

DEFAULT_DEPLOYER="deploy"
if [ $INPUT_DEPLOYER = "no-permission-check" ]
then
  DEFAULT_DEPLOYER="deploy:no-permission-check"
fi

# deploy release
./vendor/bin/dep $DEFAULT_DEPLOYER production \
-o bucket-commit=$BUCKET_COMMIT \
-o host_bucket_path=$HOST_DEPLOY_PATH_BUCKET \
-o deploy_path_custom=$HOST_DEPLOY_PATH \
-o write_use_sudo=$WRITE_USE_SUDO

#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "chown -R www-data:www-data $HOST_DEPLOY_PATH && chmod -R 775 $HOST_DEPLOY_PATH"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/production/post_release_setup.sh"

#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "chown -R www-data:www-data $HOST_DEPLOY_PATH && chmod -R 775 $HOST_DEPLOY_PATH"


#echo "📀 upgrade magento to new modules and stuff"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && php bin/magento setup:upgrade"
#
#echo "✂️ remove cached stuff"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && rm -rf pub/static/* && rm -rf var/view_preprocessed/* && rm -rf var/cache/* && rm -rf var/generation/* && rm -rf var/page_cache/*"
#
#echo "👮🏻 fix access rights"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && chmod 777 -R var pub generated"
#
#echo "👨🏼‍🚀 set shop to production mode"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && php bin/magento deploy:mode:set production"
#
#echo "⚙️ compile things"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && php bin/magento setup:di:compile"
#
#echo "🪂 deploy compiled stuff"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && php bin/magento setup:static-content:deploy"
#
#echo "👮🏻 fix access rights"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && chmod 777 -R var pub generated"
#
#echo "🧹 running Magento clean cache commands"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && php bin/magento cache:clean && php bin/magento cache:flush"
#
#echo "👮🏻 fix access rights again"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  production "cd $HOST_DEPLOY_PATH/current/magento/ && chmod -R 777 . && chown -R www:www-data ."
