#!/usr/bin/env bash

set -xe;

DEBIAN_FRONTEND=noninteractive
APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# PHP tools (installed globally)
COMPOSER_VERSION=1.9.0
DRUSH_VERSION=8.3.0
DRUSH_LAUNCHER_VERSION=0.6.0
DRUPAL_CONSOLE_LAUNCHER_VERSION=1.9.2
WPCLI_VERSION=2.3.0
PLATFORMSH_CLI_VERSION=3.47.0
HUB_VERSION=2.12.3
TERMINUS_VERSION=2.0.1

apt-get -y --no-install-recommends install apt-transport-https wget

sed -i 's/main/main contrib non-free/' /etc/apt/sources.list; \
# git-lfs repo
curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add -; \
echo 'deb https://packagecloud.io/github/git-lfs/debian stretch main' | tee /etc/apt/sources.list.d/github_git-lfs.list; \
echo 'deb-src https://packagecloud.io/github/git-lfs/debian stretch main' | tee -a /etc/apt/sources.list.d/github_git-lfs.list;

mkdir -p /usr/share/man/man1 /usr/share/man/man7; \
apt-get update; \
apt-get -y --no-install-recommends install >/dev/null \
        software-properties-common \
        dirmngr \
        cron \
        dnsutils \
        git \
        git-lfs \
        ghostscript \
        imagemagick \
        iputils-ping \
        less \
        mc \
        mysql-client \
        nano \
        procps \
        pv \
        rsync \
        supervisor \
        unzip \
        webp \
        zip

# Note: essential build tools (g++, gcc, make, etc) are included upstream as persistent packages.
# See https://github.com/docker-library/php/blob/4af0a8734a48ab84ee96de513aabc45418b63dc5/7.2/stretch/fpm/Dockerfile#L18-L37
buildDeps=" \
        libc-client2007e-dev \
        libfreetype6-dev \
        libgpgme11-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libldap2-dev \
        libmagickcore-dev \
        libmagickwand-dev \
        libmemcached-dev \
        libmhash-dev \
        libpng-dev \
        libpq-dev \
        libwebp-dev \
        libssh2-1-dev \
        libxpm-dev \
        libxslt1-dev \
        libzip-dev \
        unixodbc-dev \
"; \
        apt-get update >/dev/null; \

ACCEPT_EULA=Y \
apt-get -y --no-install-recommends install >/dev/null \
        $buildDeps \
        libc-client2007e \
        libfreetype6 \
        libgpgme11 \
        libicu57 \
        libjpeg62-turbo \
        libldap-2.4-2 \
        libmagickcore-6.q16-3 \
        libmagickwand-6.q16-3 \
        libmemcached11 \
        libmemcachedutil2 \
        libmhash2 \
        libpng16-16 \
        libpq5 \
        libssh2-1 \
        libxpm4 \
        libxslt1.1 \
        libzip4

# SSH2 must be installed from source for PHP 7.x
git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2 && rm -rf /usr/src/php/ext/ssh2/.git

docker-php-ext-configure >/dev/null gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
        --with-webp-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-xpm-dir=/usr/include/; \
docker-php-ext-configure >/dev/null imap --with-kerberos --with-imap-ssl; \
docker-php-ext-configure >/dev/null ldap --with-libdir=lib/x86_64-linux-gnu/; \
docker-php-ext-configure >/dev/null pgsql --with-pgsql=/usr/local/pgsql/; \
docker-php-ext-configure >/dev/null zip --with-libzip; \
\
docker-php-ext-install >/dev/null -j$(nproc) \
        bcmath \
        bz2 \
        calendar\
        exif \
        gd \
        gettext \
        imap \
        intl \
        ldap \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        soap \
        sockets \
        ssh2 \
        xsl \
        zip \
;\
pecl update-channels; \
pecl install >/dev/null </dev/null \
        apcu \
        gnupg \
        imagick \
        memcached \
        redis \
        xdebug
docker-php-ext-enable \
        apcu \
        gnupg \
        imagick \
        memcached \
        redis

# Hub
curl -fsSL "https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz" -o /usr/local/bin/hub; \
# Composer
curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer; \
# Drush 8 (global fallback)
curl -fsSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush8; \
# Drush Launcher
curl -fsSL "https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar" -o /usr/local/bin/drush; \
# Drupal Console Launcher
curl -fsSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" -o /usr/local/bin/drupal; \
# Wordpress CLI
curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp; \
# Platform.sh CLI
curl -fsSL "https://github.com/platformsh/platformsh-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar" -o /usr/local/bin/platform; \
# Make all downloaded binaries executable in one shot
(cd /usr/local/bin && chmod +x composer drush8 drush drupal wp platform hub);

# Set drush8 as a global fallback for Drush Launcher
su -l -m circleci -c 'echo "export DRUSH_LAUNCHER_FALLBACK=/usr/local/bin/drush8" | tee -a $BASH_ENV'

# Composer based dependencies
# Add composer bin directory to PATH
su -l -m circleci -c 'echo \"export PATH="$PATH:$HOME/.composer/vendor/bin"\" | tee -a $BASH_ENV'

# Install cgr to use it in-place of `composer global require`
su -l -m circleci -c "composer global require consolidation/cgr >/dev/null"
# Composer parallel install plugin
su -l -m circleci -c 'composer global require hirak/prestissimo >/dev/null'
# Drupal Coder & WP Coding Standards w/ a matching version of PHP_CodeSniffer
su -l -m circleci -c 'cgr drupal/coder wp-coding-standards/wpcs phpcompatibility/phpcompatibility-wp > /dev/null'
su -l -m circleci -c 'phpcs --config-set installed_paths "$HOME/.composer/global/drupal/coder/vendor/drupal/coder/coder_sniffer/,$HOME/.composer/global/wp-coding-standards/wpcs/vendor/wp-coding-standards/wpcs/"'
# Terminus
su -l -m circleci -c "cgr pantheon-systems/terminus:${TERMINUS_VERSION} >/dev/null"
# Cleanup
su -l -m circleci -c "composer clear-cache"

# Drush modules
su -l -m circleci -c 'drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush >/dev/null'
su -l -m circleci -c 'drush cc drush'