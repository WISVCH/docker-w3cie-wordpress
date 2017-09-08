FROM wordpress:php7.1-fpm-alpine
LABEL maintainer="W3Cie \"w3cie@ch.tudelft.nl\""

# Install additional tools.
# RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
#     apk --no-cache add git

# Download and install WP-CLI
RUN curl  -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv    wp-cli.phar /usr/local/bin/wp

# Custom php.ini for sendmail path
COPY php.ini       /usr/local/etc/php/conf.d/php.ini
COPY wp-config.php /var/www/wp-config-custom.php

WORKDIR /var/www/html

# Custom entrypoint to install WP & replace wp-config
# As we replace the original entrypoint from wordpress Dockerfile
# we need to run that also in our replacement to actually install
# the wordpress and start the PHP.
COPY ./entrypoint.sh /custom-entrypoint.sh
RUN  chmod +x        /custom-entrypoint.sh

ENTRYPOINT ["/custom-entrypoint.sh"]

CMD ["php-fpm"]