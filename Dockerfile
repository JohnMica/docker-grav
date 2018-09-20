FROM php:7.2-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"
LABEL name="grav"

# Enable Apache Rewrite Module
RUN a2enmod rewrite

# Install dependencies
RUN  set -ex; && apt-get update && apt-get install -y \
        unzip \
        wget \
        libfreetype6-dev \
        #libjpeg62-turbo-dev \
        libpng-dev \
        libyaml-dev \
# seems phph 7.2 didnt have the above dependenciy available before so we'll need the following
        libjpeg-dev \
        zlib1g-dev \
        libpng16-16 \
# if you want to use the git-sync, you'll need the git on this image
        #  git \
            ; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get clean && \

    && docker-php-ext-install opcache \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
# this is the original command, above is the new one
    # && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip

RUN pecl install apcu \
    && pecl install yaml \
    && docker-php-ext-enable apcu yaml

# Define env variable for grav
ENV SOURCE="/usr/src/grav"

# afte the install we'll update the user
# Set user to www-data
# RUN chown www-data:www-data /var/www
# USER www-data



# Define Grav version and expected SHA1 signature
# ENV GRAV_VERSION 1.5.1
# ENV GRAV_SHA1 5292b05d304329beefeddffbf9f542916012c221

# This is the simple install with removal of the source once it has been used
RUN set -ex; \
    wget https://getgrav.org/download/core/grav/latest && \
    unzip latest && \
    mkdir -p "$SOURCE" && \
    cp -r grav-admin/. "$SOURCE" && \
    rm -rf grav-admin latest && \
    rm -rf "$SOURCE"/user && \

    chown -R www-data:www-data "$SOURCE"

 # Install grav
 # WORKDIR /var/www
 # RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
 #   echo "$GRAV_SHA1 grav-admin.zip" | sha1sum -c - && \
 #  unzip grav-admin.zip && \
 #  mv -T /var/www/grav-admin /var/www/html && \
 #  rm grav-admin.zip
 
# local volume to be copied inside container
COPY ./ /var/www/html/user
COPY docker-entrypoint.sh /

# Return to root user
# USER root


RUN chmod +x /docker-entrypoint.sh && \
    chown root:root /docker-entrypoint.sh


# Copy init scripts
# COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
