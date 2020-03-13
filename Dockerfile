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
ENV DEBIAN_FRONTEND="noninteractive"
ENV LIB_DEPS="zlib1g-dev libzip-dev"
ENV NODE_VERSION=12
ENV SONAR_CLI="4.4.0.2170"
ENV TOOLS_DEPS="apt-utils curl git graphviz make rsync software-properties-common unzip zip wget"

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

# Install sonar-scanner
RUN cd /tmp \
  && wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_CLI-linux.zip \
  && unzip sonar-scanner-cli-$SONAR_CLI-linux.zip -d /opt \
  && ln -s /opt/sonar-scanner-$SONAR_CLI-linux/bin/sonar-scanner /usr/bin/sonar-scanner \
  && rm -f sonar-scanner-cli-$SONAR_CLI-linux.zip

# Install node
RUN curl -sL "https://deb.nodesource.com/setup_$NODE_VERSION.x" | bash - \
  && apt-get install $APT_OPTION nodejs build-essential

# Install lighthouse
RUN npm install -g lighthouse

# Perform Clean Up
RUN rm -rf $COMPOSER_HOME/cache && apt-get purge -y --auto-remove $BUILD_DEPS