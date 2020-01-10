FROM php:7.1-fpm

RUN apt-get update -y \
    && apt-get install -y nginx curl vim wget gnupg git \
    && wget -O - https://download.newrelic.com/548C16BF.gpg | apt-key add -  \
    && echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list \
    && wget  https://storage.googleapis.com/asia.artifacts.ans-frontend.appspot.com/newrelic-php5-9.5.0.252-linux.tar.gz \
    && tar -xvf newrelic-php5-9.5.0.252-linux.tar.gz 
   # && bash newrelic-php5-9.5.0.252-linux/newrelic-install install
   # && sed -i 's/newrelic.license = ""/newrelic.license = "LICENSE_KEY"/' /etc/php/7.1/fpm/conf.d/20-newrelic.ini  \
   # && sed -i 's/newrelic.appname = "PHP Application"/newrelic.appname = "APP_NAME"/g' /etc/php/7.1/fpm/conf.d/20-newrelic.ini

RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis

# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"

RUN docker-php-ext-install pdo_mysql \
    && docker-php-ext-install opcache \
    && apt-get install libicu-dev -y \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && apt-get remove libicu-dev icu-devtools -y
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/php-opocache-cfg.ini

RUN  bash newrelic-php5-9.5.0.252-linux/newrelic-install install \
    && mkdir -p /var/www/html/opencart
COPY nginx-site.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /etc/entrypoint.sh
COPY index.php /var/www/html/opencart

COPY --chown=www-data:www-data . /var/www/html/opencart

WORKDIR /var/www/html/opencart

EXPOSE 80 

ENTRYPOINT ["/etc/entrypoint.sh"]
