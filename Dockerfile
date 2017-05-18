FROM    phpdockerio/php7-fpm:latest
# The following extensions are already included on the base image: APC, cURL, JSON, MCrypt (libsodium on 7.1), OPCache, Readline, XML and Zip.

# https://github.com/phusion/baseimage-docker/issues/58
RUN     echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install selected extensions and other stuff
RUN     apt-get update \
        && apt-get -y --no-install-recommends install apt-utils \ 
        && apt-get -y --no-install-recommends install php7.0-memcached php7.0-pgsql php7.0-sqlite3 \ 
        php-gd php7.0-gd php7.0-bcmath php7.0-imap php7.0-intl php7.0-mbstring php7.0-xdebug \ 
        php7.0-xmlrpc php7.0-apcu git nodejs nodejs-legacy \
        && apt-get -y --no-install-recommends install npm \
        && npm install -g bower

RUN     apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install Composer
RUN     curl -sS https://getcomposer.org/installer | php &&  mv composer.phar /usr/local/bin/composer

# Configure PHP CLI
RUN     sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini \
        && sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini \
        && sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/cli/php.ini \
        && sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini

# Configure PHP-FPM
RUN     sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini \
        && sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini \
        && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini \
        && sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/fpm/php.ini \
        && sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini \
        && sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini \
        && sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini


ADD     ./config.json  /root/.composer/
RUN     echo "{}" > ~/.composer/composer.json

# Create the directory and set permissions
# Switch to www-data user
# Obtain the latest code
# Installing Dependencies

RUN     mkdir -p /var/www \
        && chown -R www-data:www-data /var/www \
        && su -s /bin/bash www-data \ 
        && cd /var/www \ 
        && rm -rf html \
        && git clone https://github.com/academic/vipa \ 
        && cd vipa  \
        && composer update -vvv -o \
        && bower update --allow-root \
        && php app/console assets:install web --symlink \
        && php app/console assetic:dump  \
        && php app/console doctrine:schema:drop --force  \
        && php app/console doctrine:schema:create  \
        && php app/console vipa:install  \
        && php app/console vipa:install:samples  \
        && php app/console vipa:install:initial-data


WORKDIR "/application"