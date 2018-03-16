FROM php:7.2-fpm-alpine

LABEL maintainer="Arne Stappen <mehh@agoat.xyz>"

# Install packages we need
RUN apk add --no-cache \
		rsync \
		bash \
# Install PHP extensions we need
	&& apk add --no-cache --virtual .build-deps \
		coreutils \
		libwebp-dev \
		libpng-dev \
		jpeg-dev \
		freetype-dev \
		tiff-dev \
		icu-dev \
	&& docker-php-ext-configure gd \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
		--with-webp-dir=/usr \
		--with-freetype-dir=/use \
	&& docker-php-ext-install -j$(nproc) gd exif opcache intl mbstring pdo_mysql \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache --virtual .php-rundeps $runDeps \
	&& apk del .build-deps
		
# Add the composer tool
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && mkdir /.composer \
	&& chown www-data:www-data /.composer


ENV CONTAO_VERSION 4.4.15

RUN set -ex \
	&& curl -fL -o contao.tar.gz \
		"https://download.contao.org/${CONTAO_VERSION}/tar" \
	&& tar -xzf contao.tar.gz -C /usr/src/ \
	&& rm contao.tar.gz \
	&& chown root:root /usr/src/contao-${CONTAO_VERSION} \
# For some reasons, slashes in the packages names are escaped
	&& sed -i -e 's/\\\//\//g' /usr/src/contao-${CONTAO_VERSION}/composer.json
	
VOLUME /var/www/html

COPY *.sh /
COPY php.ini /usr/local/etc/php/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
