set -xe; \
	# Create man direcotries, otherwise some packages may not install (e.g. postgresql-client)
	# This should be a temporary workaround until fixed upstream: https://github.com/debuerreotype/debuerreotype/issues/10
	mkdir -p /usr/share/man/man1 /usr/share/man/man7; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		software-properties-common \
		dirmngr \
		cron \
		dnsutils \
		git \
		git-lfs \
		ghostscript \
		# html2text binary - used for self-testing (php-fpm)
		#html2text \
		imagemagick \
		iputils-ping \
		less \
		# cgi-fcgi binary - used for self-testing (php-fpm)
		#libfcgi-bin \
		mc \
		msmtp \
		mysql-client \
		nano \
		openssh-client \
		openssh-server \
		postgresql-client \
		procps \
		pv \
		rsync \
		sudo \
		supervisor \
		unzip \
		webp \
		zip \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

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
	# Necessary for msodbcsql17 (MSSQL)
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
		libzip4 \
		msodbcsql17 \
	;\
	# SSH2 must be installed from source for PHP 7.x
	git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2 && rm -rf /usr/src/php/ext/ssh2/.git; \
	\
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
		# mcrypt is deprecated in 7.1 and removed in 7.2. See Deprecated features.
		# mcrypt \
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
		# Use memcached (not memcache) for PHP 7.x
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
		xdebug \
	;\
	docker-php-ext-enable \
		apcu \
		gnupg \
		imagick \
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
	;\
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*
