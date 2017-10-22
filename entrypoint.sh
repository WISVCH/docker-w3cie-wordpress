#!/bin/bash

# mute CMD from official wordpress image entrypoint.
sed -i -e 's/^exec "$@"/#exec "$@"/g' /usr/local/bin/docker-entrypoint.sh

# Run the docker-entrypoint of official wordpress image to do the installation.
bash /usr/local/bin/docker-entrypoint.sh $1

# Update hostname and restart mail tools.
#line=$(head -n 1 /etc/hosts)
#line2=$(echo $line | awk '{print $2}')
#echo "$line $line2.localdomain" >> /etc/hosts
#postfix start

# Wait until WordPress has been installed
until wp core version --allow-root; do
  sleep 1;
done;

# Add Analytics ID to custom wp-config.php
echo "define('ANALYTICS_ID', '${ANALYTICS_ID}');" >> /var/www/wp-config-custom.php

# Append extra code to wp-config.php
wp core config \
  --force \
  --allow-root \
  --skip-check \
  --dbname=${WORDPRESS_DB_NAME} \
  --dbuser=${WORDPRESS_DB_USER} \
  --dbpass=${WORDPRESS_DB_PASSWORD} \
  --dbhost=${WORDPRESS_DB_HOST} \
  --dbprefix=${WORDPRESS_DB_PREFIX} \
  --extra-php <<PHP
    require_once('/var/www/wp-config-custom.php');
PHP

# Remove default / inactive plugins
echo
echo "Removing themes and plugins..."

wp plugin delete $(wp plugin list --field=name --allow-root) --allow-root
wp theme delete  $(wp theme list  --field=name --allow-root)  --allow-root

# Install theme
echo
echo "Installing theme..."

if [[ "${W3CIE_THEME}" ]]; then
  wp theme install ${W3CIE_THEME} --activate --force --allow-root;
fi

# Install plugins
echo
echo "Installing plugins..."

if [[ "${W3CIE_PLUGINS}" ]]; then
  for i in $(echo ${W3CIE_PLUGINS} | sed "s/,/ /g")
  do
    wp plugin install $i --activate --force --allow-root;
  done
fi

# Remove default / inactive themes
echo
echo "Removing leftover theme..."

wp theme delete $(wp theme list --field=name --status=inactive --allow-root) --allow-root

# Fix permissions
echo
echo "Setting permissions..."

chown -R www-data /var/www/html/*
chown    www-data /var/www/wp-config-custom.php

echo
echo "...done!"

# Unset variables to prevent leaking through (e.g.) phpinfo()
unset WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD WORDPRESS_DB_HOST WORDPRESS_DB_PREFIX WORDPRESS_VERSION WORDPRESS_SHA1 W3CIE_THEME W3CIE_PLUGINS ANALYTICS_ID

# execute CMD
exec "$@"