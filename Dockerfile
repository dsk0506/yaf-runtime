ARG   PHP_VERSION="${PHP_VERSION:-7.3.3}"
FROM  php:${PHP_VERSION}-fpm-alpine

ARG     PHPREDIS_VERSION="${PHPREDIS_VERSION:-4.2.0}"
ENV     PHPREDIS_VERSION="${PHPREDIS_VERSION}"
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD     https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz /tmp/

RUN     apk update                       && \
        \
        apk upgrade                      && \
        \
        docker-php-source extract        && \
        \
        apk add --no-cache                  \
            --virtual .build-dependencies   \
                $PHPIZE_DEPS                \
                zlib-dev                    \
                cyrus-sasl-dev              \
                git                         \
                autoconf                    \
                g++                         \
                libtool                     \
                make                        \
                curl-dev                    \
                pcre-dev                 && \
        \
        apk add --no-cache                  \
            tini                            \
            libintl                         \
            icu                             \
            icu-dev                         \
            libxml2-dev                     \
            postgresql-dev                  \
            freetype-dev                    \
            libjpeg-turbo-dev               \
            libpng-dev                      \
            gmp                             \
            gmp-dev                         \
            libmemcached-dev                \
            imagemagick-dev                 \
            libzip-dev                      \
            libssh2                         \
            libssh2-dev                     \
            libmcrypt-dev                     \
            libxslt-dev                  && \
        \
        tar xfz /tmp/${PHPREDIS_VERSION}.tar.gz   && \
        \
        mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis    && \
        \
        git clone https://github.com/php-memcached-dev/php-memcached.git /usr/src/php/ext/memcached/    && \
        \
        docker-php-ext-configure memcached      &&  \
        \
        docker-php-ext-configure gd                 \
            --with-freetype-dir=/usr/include/       \
            --with-jpeg-dir=/usr/include/       &&  \
        \
        docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
            intl                                                \
            bcmath                                              \
            xsl                                                 \
            zip                                                 \
            soap                                                \
            mysqli                                              \
            pdo                                                 \
            pdo_mysql                                           \
            pdo_pgsql                                           \
            gmp                                                 \
            redis                                               \
            iconv                                               \
            gd                                                  \
            sockets                                             \
            memcached                                       &&  \
        \
        docker-php-ext-configure opcache --enable-opcache           &&  \
        \
        docker-php-ext-install opcache                              &&  \
        \
        pecl install                                                    \
            apcu imagick yaf yar channel://pecl.php.net/mcrypt-1.0.2  &&  \
        \
        docker-php-ext-enable                                           \
            apcu imagick yaf yar mcrypt                                 &&  \
        \
        apk del .build-dependencies                                 &&  \
        \
        docker-php-source delete                                    &&  \
        \
        rm -rf /tmp/* /var/cache/apk/* \
        && apk add nginx npm bash \
        && npm install pm2 -g \
        && mkdir -p /run/nginx \
        && echo "daemon off;" >> /etc/nginx/nginx.conf \
        && mkdir -p /usr/local/php/bin  \
        && ln -s /usr/local/bin/php  /usr/local/php/bin/php \
        &&  sed -i -e "s/\/proc\/self\/fd\/2/\/app\/data\/fpm_error_log.log/g" /usr/local/etc/php-fpm.d/docker.conf \
        && cp  /usr/local/etc/php/php.ini-production   /usr/local/etc/php/php.ini \
        && echo "yaf.environ=development" >> /usr/local/etc/php/php.ini \
        && sed -i -e "s/pm\s*=\s*dynamic/pm = static/g" /usr/local/etc/php-fpm.d/www.conf \
        && sed -i -e "s/pm\.max_children\s*=\s*5/pm.max_children = 200/g" /usr/local/etc/php-fpm.d/www.conf



