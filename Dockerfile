FROM php:7.4-apache

#Apache ENVs
# ENV APACHE_RUN_USER www-data
# ENV APACHE_RUN_GROUP www-data
#ENV APACHE_LOCK_DIR ./.apache/lock
#ENV APACHE_LOG_DIR ./.apache/log
#ENV APACHE_SERVER_NAME localhost
ENV LD_LIBRARY_PATH=/usr/local/instantclient


# START JOOMLA EXTENSIONS
RUN apt-get update; \
	apt-get install -y --no-install-recommends \
		libbz2-dev \
		libgmp-dev \
		libjpeg-dev \
		libldap2-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
		libxml2-dev \
		libfreetype6-dev \
		zlib1g-dev
		
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
	docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
	docker-php-ext-install -j "$(nproc)" \
		bz2 \
		gd \
		gmp \
		ldap \
		mysqli \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		zip \
		pdo \
		mysqli \
		pdo_mysql \
		soap \
		exif
# END JOOMLA EXTENSIONS

# START MY EXTENSIONS
RUN apt-get update && apt-get install -y --fix-missing \
    libmagickwand-dev --no-install-recommends \
	ghostscript \
	unzip \
	libaio1 \
	&& pecl install xdebug-3.0.4 \
	&& docker-php-ext-enable xdebug \
	&& pecl install imagick \
	&& docker-php-ext-enable imagick
# END MY EXTENSIONS

# START ORACLE INSTALL
COPY ./instantclient.zip /tmp/instantclient21.1.zip
COPY ./instantclient-sdk-21.1.zip /tmp/instantclient-sdk-21.1.zip

RUN unzip /tmp/instantclient21.1.zip -d /usr/local/instantclient \
	&& unzip /tmp/instantclient-sdk-21.1.zip -d /usr/local/instantclient \
	&& echo 'instantclient,/usr/local/instantclient' | pecl install oci8-2.2.0 \
	&& docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/local/instantclient \
	&& docker-php-ext-install oci8 \
	&& docker-php-ext-enable oci8 \
	&& echo /usr/local/instantclient/ > /etc/ld.so.conf.d/oracle-insantclient.conf \
	&& ldconfig
# END ORACLE INSTALL

# INITIALIZE
COPY ./.php/conf.d/php.ini /usr/local/etc/php/php.ini
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY .apache/etc/apache2/sites-enabled/ /etc/apache2/sites-available/

RUN chown -R www-data:www-data /var/www/html \
	&& a2enmod rewrite \
	&& a2enmod headers