# Ubuntu with test & deploy tools:
#
# VERSION 1.0
# 
# Image used for Code Quality.

# Base Image.
From ubuntu:18.04

# Set MetaData
LABEL maintainer="Gobinath Mallaiyan <gobinathm@gmail.com>"
LABEL description="Docker Image for Drupal Quality Check"
LABEL version="1.0"

# build arguments
ARG PHP_VERSION="7.3"

# Environment Variables
ENV APT_OPTION="-yq --no-install-recommends"
ENV BUILD_DEPS="autoconf file g++ gcc libc-dev pkg-config re2c"
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME=$TOOLS_TARGET_DIR/.composer
ENV DEBIAN_FRONTEND="noninteractive"
ENV DRUPAL_CHECK_VERSION="1.0.9"
ENV DRUPAL_TOOLS_DIR="/drupaltools"
ENV LIB_DEPS="zlib1g-dev libzip-dev"
ENV PATH="$PATH:/src/bin:$TOOLS_TARGET_DIR:$TOOLS_TARGET_DIR/.composer/vendor/bin"
ENV SONAR_CLI="4.4.0.2170"
ENV TOOLS_DEPS="apt-utils curl git graphviz make rsync software-properties-common unzip zip wget"
ENV TOOLS_TARGET_DIR="/tools"
ENV TOOLS_VERSION="1.20.0"

# Prepare system by upgrading existing
RUN apt-get update 

# Install Build Dependancies. 
RUN apt-get install $APT_OPTION $BUILD_DEPS $LIB_DEPS $TOOLS_DEPS

# Install Required Packages.
RUN apt-get install $APT_OPTION\
  build-essential \
  chromium-browser \
  chromium-chromedriver 

# Custom Builing a PHP installation as we want rather than re-using an existing PHP Image.
# Register PPA to download PHP
RUN add-apt-repository ppa:ondrej/php

# Update all missing items once again
RUN apt-get --yes update --fix-missing

# Install PHP Packages
RUN apt-get install $APT_OPTION php$PHP_VERSION-cli \
  php$PHP_VERSION-dev \
  php$PHP_VERSION-fpm \
  php$PHP_VERSION-intl \
  php$PHP_VERSION-json \
  php$PHP_VERSION-pdo \
  php$PHP_VERSION-mysql \
  php$PHP_VERSION-zip \
  php$PHP_VERSION-gd \
  php$PHP_VERSION-mbstring \
  php$PHP_VERSION-curl \
  php$PHP_VERSION-xml \
  php$PHP_VERSION-bcmath \
  php$PHP_VERSION-json \
  php$PHP_VERSION-psr \
  php$PHP_VERSION-xhprof \
  php$PHP_VERSION-yaml

# install php ast extension
WORKDIR /tmp
RUN git clone https://github.com/nikic/php-ast.git && cd php-ast\
  && phpize && ./configure && make && make install && cd .. \
  && rm -rf php-ast \
  && echo "date.timezone=America/New York" >> /etc/php/$PHP_VERSION/cli/php.ini \
  && echo "memory_limit=-1" >> /etc/php/$PHP_VERSION/cli/php.ini \
  && echo "phar.readonly=0" >> /etc/php/$PHP_VERSION/cli/php.ini \
  && echo "extension=ast.so" >> /etc/php/$PHP_VERSION/cli/php.ini \
  && echo "pcov.enabled=0" >> /etc/php/$PHP_VERSION/cli/php.ini

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# PHP Tools Install & Configure
RUN mkdir -p $TOOLS_TARGET_DIR && curl -Ls https://github.com/jakzal/toolbox/releases/download/v$TOOLS_VERSION/toolbox.phar -o $TOOLS_TARGET_DIR/toolbox \
  && chmod +x $TOOLS_TARGET_DIR/toolbox \
  && php $TOOLS_TARGET_DIR/toolbox install

# copy composer configurations
COPY composer.json /$DRUPAL_TOOLS_DIR/composer.json
COPY composer.lock /$DRUPAL_TOOLS_DIR/composer.lock

# Install Dependency
WORKDIR $DRUPAL_TOOLS_DIR
RUN COMPOSER_MEMORY_LIMIT=-1 composer install

RUN git clone https://git.drupalcode.org/sandbox/coltrane-1921926.git drupalsecure \
    && git clone https://github.com/klausi/pareviewsh.git \
    && rm -rf ./drupalsecure/.git/ ./pareviewsh/.git/ \
    && curl -Ls https://github.com/mglaman/drupal-check/releases/download/$DRUPAL_CHECK_VERSION/drupal-check.phar -o $TOOLS_TARGET_DIR/drupal-check \
    && chmod +x $TOOLS_TARGET_DIR/drupal-check

# Drupal Tools mapping to TOOLBox
RUN ln -s $DRUPAL_TOOLS_DIR/vendor/bin/phpcs $TOOLS_TARGET_DIR \
    && ln -s $DRUPAL_TOOLS_DIR/pareviewsh/pareview.sh $TOOLS_TARGET_DIR/pareview \
    && chmod +x $TOOLS_TARGET_DIR/pareview \
    && phpcs --config-set installed_paths $DRUPAL_TOOLS_DIR/vendor/drupal/coder/coder_sniffer/,$DRUPAL_TOOLS_DIR/vendor/phpcompatibility/php-compatibility,$DRUPAL_TOOLS_DIR/drupalsecure

# Install sonar-scanner
RUN cd /tmp \
  && wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_CLI-linux.zip \
  && unzip sonar-scanner-cli-$SONAR_CLI-linux.zip -d /opt \
  && ln -s /opt/sonar-scanner-$SONAR_CLI-linux/bin/sonar-scanner /usr/bin/sonar-scanner \
  && rm -f sonar-scanner-cli-$SONAR_CLI-linux.zip

# Install node
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install $APT_OPTION nodejs build-essential

# Install lighthouse
RUN npm install -g lighthouse

# Perform Clean Up
RUN rm -rf $COMPOSER_HOME/cache && apt-get purge -y --auto-remove $BUILD_DEPS

# set workdir
WORKDIR $TOOLS_TARGET_DIR
