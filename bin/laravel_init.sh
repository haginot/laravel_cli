#!/bin/bash

WORKING_DIR="$HOME/Sites"
APP_NAME="link"
DB_NAME="laravel_link"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -w|--working)
    WORKING_DIR="$2"
    shift
    shift
    ;;
    -n|--name)
    APP_NAME="$2"
    shift
    shift
    ;;
    --db-name)
    DB_NAME="$2"
    shift
    shift
    ;;
    *)
    POSITIONAL+=("$1") 
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" 

mkdir -p $WORKING_DIR
cd $WORKING_DIR

LARAVEL_INSTALLED=`composer global show | grep -c laravel/installer`
VALET_INSTALLED=`composer global show | grep -c laravel/valet`

if [ "$LARAVEL_INSTALLED" -gt "0" ]; then
  echo "ralavel/installer is installed"
else
  composer global require "laravel/installer"
fi

if [ "$VALET_INSTALLED" -gt "0" ]; then
  echo "rlaravel/valet is installed"
else
  composer global require "laravel/valet"
fi

COMPOSER_PATH_DEFINED=`echo $PATH | grep -oc "\.composer\/vendor\/bin"`

if [ "$COMPOSER_PATH_DEFINED" -lt "1" ]; then
  echo "export PATH=\"$HOME/.composer/vendor/bin:$PATH\"" >> $HOME/.bash_profile
fi

if [ -d "$APP_NAME" ]; then
  read -p "link application will be deleted. Are you sure? [Y/n]: " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf $WORKING_DIR/$APP_NAME
    mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;"
  else
    exit;
  fi
fi

mysql -u root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
laravel new $APP_NAME

cd $WORKING_DIR/$APP_NAME

sed -i -e "s/DB_DATABASE=homestead/DB_DATABASE=$DB_NAME/g" $WORKING_DIR/$APP_NAME/.env
sed -i -e 's/DB_USERNAME=homestead/DB_USERNAME=root/g' $WORKING_DIR/$APP_NAME/.env
sed -i -e 's/DB_PASSWORD=secret/DB_PASSWORD=""/g' $WORKING_DIR/$APP_NAME/.env

php artisan make:auth

php artisan migrate
