FROM php:5.6-apache

ADD https://github.com/mplesha/NoviNano/releases/download/v1.0/20180706_novinano_ts_976c110733e7eff58704180706072907_archive.zip /var/www/html
ADD https://github.com/mplesha/NoviNano/releases/download/v1.0/20180706_novinano_ts_976c110733e7eff58704180706072907_installer.php /var/www/html/installer.php

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
        libzip-dev zlib1g-dev \
   && chown -R www-data:www-data /var/www/html \
   && chmod +x installer.php \
   && docker-php-ext-install mysql mysqli zip

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]