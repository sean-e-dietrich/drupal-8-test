#!/bin/bash

set -eo pipefail

# APT Variables
DEBIAN_FRONTEND=noninteractive
APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Set up BASH_ENV if it was not set for us.
BASH_ENV=${BASH_ENV:-$HOME/.bashrc}

# PHP tools (installed globally)
COMPOSER_VERSION=1.9.0
DRUSH_VERSION=8.3.0
DRUSH_LAUNCHER_VERSION=0.6.0
DRUPAL_CONSOLE_LAUNCHER_VERSION=1.9.2
WPCLI_VERSION=2.3.0
PLATFORMSH_CLI_VERSION=3.47.0
HUB_VERSION=2.12.3
TERMINUS_VERSION=2.0.1

# Avoid ssh prompting when connecting to new ssh hosts
mkdir -p $HOME/.ssh && echo "StrictHostKeyChecking no" >> "$HOME/.ssh/config"

sudo sed -i 's/main/main contrib non-free/' /etc/apt/sources.list

sudo apt-get update
sudo apt-get -y --no-install-recommends install >/dev/null \
        apt-transport-https

# git-lfs repo
curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | sudo apt-key add -
echo 'deb https://packagecloud.io/github/git-lfs/debian stretch main' | sudo tee /etc/apt/sources.list.d/github_git-lfs.list
echo 'deb-src https://packagecloud.io/github/git-lfs/debian stretch main' | sudo tee -a /etc/apt/sources.list.d/github_git-lfs.list

sudo mkdir -p /usr/share/man/man1 /usr/share/man/man7
sudo apt-get update

sudo apt-get -y --no-install-recommends install >/dev/null \
        wget \
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
        unixodbc-dev"

sudo apt-get update >/dev/null

ACCEPT_EULA=Y \
sudo apt-get -y --no-install-recommends install >/dev/null \
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
        gconf-service \
        libasound2 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgcc1 \
        libgconf-2-4 \
        libgdk-pixbuf2.0-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        ca-certificates \
        fonts-liberation \
        libappindicator1 \
        libnss3 \
        lsb-release \
        xdg-utils \
        libzip4

# SSH2 must be installed from source for PHP 7.x
sudo git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2
sudo rm -rf /usr/src/php/ext/ssh2/.git

sudo docker-php-ext-configure >/dev/null gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
        --with-webp-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-xpm-dir=/usr/include/
sudo docker-php-ext-configure >/dev/null imap --with-kerberos --with-imap-ssl
sudo docker-php-ext-configure >/dev/null ldap --with-libdir=lib/x86_64-linux-gnu/
sudo docker-php-ext-configure >/dev/null pgsql --with-pgsql=/usr/local/pgsql/
sudo docker-php-ext-configure >/dev/null zip --with-libzip

sudo docker-php-ext-install >/dev/null -j$(nproc) \
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
        zip

sudo pecl update-channels
sudo pecl install >/dev/null </dev/null \
        apcu \
        gnupg \
        imagick \
        memcached \
        redis \
        xdebug
sudo docker-php-ext-enable \
        apcu \
        gnupg \
        imagick \
        memcached \
        redis

# Hub
sudo curl -fsSL "https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz" -o /usr/local/bin/hub
# Composer
sudo curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer
# Drush 8 (global fallback)
sudo curl -fsSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush8
# Drush Launcher
sudo curl -fsSL "https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar" -o /usr/local/bin/drush
# Drupal Console Launcher
sudo curl -fsSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" -o /usr/local/bin/drupal
# Wordpress CLI
sudo curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp
# Platform.sh CLI
sudo curl -fsSL "https://github.com/platformsh/platformsh-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar" -o /usr/local/bin/platform
# Make all downloaded binaries executable in one shot
cd /usr/local/bin
sudo chmod +x composer drush8 drush drupal wp platform hub

# Configure the GitHub Oauth token if it is available
if [ -n "$GITHUB_TOKEN" ]; then
  composer -n config --global github-oauth.github.com $GITHUB_TOKEN
fi

# Install cgr to use it in-place of `composer global require`
composer global require consolidation/cgr >/dev/null
# Composer parallel install plugin
composer global require hirak/prestissimo >/dev/null

(
  echo 'export PATH="$PATH:$HOME/.composer/vendor/bin:$HOME/bin:$HOME/.npm-global/bin"'
  echo 'export TERMINUS_HIDE_UPDATE_MESSAGE=1'
  echo "export ARTIFACTS_DIR='artifacts'"
  echo "export ARTIFACTS_FULL_DIR='/tmp/artifacts'"
) >> $BASH_ENV

source $BASH_ENV

# Create Artifacts Directory
mkdir -p $ARTIFACTS_FULL_DIR || true

echo 'Contents of BASH_ENV:'
cat $BASH_ENV
echo

# Drupal Coder & WP Coding Standards w/ a matching version of PHP_CodeSniffer
cgr drupal/coder wp-coding-standards/wpcs phpcompatibility/phpcompatibility-wp > /dev/null
phpcs --config-set installed_paths "$HOME/.composer/global/drupal/coder/vendor/drupal/coder/coder_sniffer/,$HOME/.composer/global/wp-coding-standards/wpcs/vendor/wp-coding-standards/wpcs/"
# Terminus
cgr pantheon-systems/terminus:${TERMINUS_VERSION} >/dev/null
# Cleanup
composer clear-cache

# Drush modules
cd /tmp
drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush >/dev/null
drush cc drush

# Install Apache Example Config
sudo cp ~/project/.circleci/example.conf /etc/apache2/sites-available/example.conf
sudo a2ensite example
sudo service apache2 start

 mkdir ~/.npm-global
 #npm config set prefix '~/.npm-global'

# Install Page Res
sudo npm install -g pageres-cli --unsafe-perm=true
