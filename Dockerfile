#使用国内网易镜像可以加快构建速度
FROM php:fpm-alpine
#维护者
MAINTAINER dsk <393573645@qq.com>
#国内repo源，让本地构建速度更快。
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
#RUN echo "http://mirrors.ustc.edu.cn/alpine/v3.3/main/" > /etc/apk/repositories

#添加php源码中的扩展，添加mysqli,pdo-mysql,opcache,gettext,mcrypt等扩展
RUN set -ex \
        && docker-php-ext-install opcache  pdo_mysql mysqli sockets

#memcached
ENV MEMCACHED_DEPS zlib-dev zlib libmemcached-libs libmemcached-dev cyrus-sasl-dev
ENV PHPIZE_DEPS autoconf file g++ gcc libc-dev make pkgconf re2c libmcrypt-dev  zlib \
        yaml-dev pcre-dev

#redis属于pecl扩展，需要使用pecl命令来安装，同时需要添加依赖的库
RUN apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache --update --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install redis-3.1.2 \
    && pecl install channel://pecl.php.net/mcrypt-1.0.2 \
    && pecl install memcached \
	&& pecl install yaf \
	&& apk add curl-dev \
	&& echo "no" | pecl install yar \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-enable sockets \
	&& docker-php-ext-enable memcached \
	&& docker-php-ext-enable yaf \
	&& docker-php-ext-enable yar \
	&& apk add nginx npm bash \
    && npm install pm2 -g \
    && rm -rf /usr/share/php \
    && rm -rf /tmp/* \
    && apk del .memcached-deps .phpize-deps \
    && mkdir -p /run/nginx \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && cp /usr/local/etc/php/php.ini-production  /usr/local/etc/php/php.ini \
    && mkdir /usr/local/php/bin \
    && echo 'yaf.environ=development' >> /usr/local/etc/php/php.ini \
    && ln -s /usr/local/bin/php  /usr/local/php/bin/php \
    && mkdir /app/data/udp_server/ \
    && sed -i -e "s/pm\s*=\s*dynamic/pm = static/g" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i -e "s/pm\.max_children\s*=\s*5/pm.max_children = 200/g" /usr/local/etc/php-fpm.d/www.conf


