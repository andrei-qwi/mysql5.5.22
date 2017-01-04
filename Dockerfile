FROM debian:jessie

ENV PATH $PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts

ADD docker-entrypoint.sh /usr/local/bin/

RUN set -x \
# Install dependencies
        && apt-get update \
        && apt-get install -y perl --no-install-recommends \
        && apt-get install -y libaio1 pwgen binutils wget \
# Add mysql user
	&& groupadd -r mysql && useradd -r -g mysql mysql \
# Configure gosu
        && wget -q -O /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64 \
        && chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
# Install mysql
	&& mkdir /docker-entrypoint-initdb.d \
        && wget -q https://downloads.mysql.com/archives/get/file/mysql-5.5.22-debian6.0-x86_64.deb \
	&& dpkg -i mysql-5.5.22-debian6.0-x86_64.deb \
	&& ln -s /opt/mysql/server-5.5 /usr/local/mysql \
# Cleanup
        && rm mysql-5.5.22-debian6.0-x86_64.deb \
	&& cd /usr/local/mysql \
	&& rm -rf mysql-test \
	&& rm -rf sql-bench \
	&& rm -rf bin/*-debug \
	&& rm -rf bin/*_embedded \
	&& find ./ -type f -name "*.a" -delete \
#Finish installation
	&& { find /usr/local/mysql -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& mkdir -p /etc/mysql/conf.d \
	&& { \
                echo '[mysqld]'; \
                echo 'skip-host-cache'; \
                echo 'skip-name-resolve'; \
                echo 'datadir = /var/lib/mysql'; \
                echo '!includedir /etc/mysql/conf.d/'; \
        } > /etc/mysql/my.cnf \
	&& mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
# Final cleanup
	&& apt-get purge -y --auto-remove binutils wget \
        && rm -rf /var/lib/apt/lists/*

EXPOSE 3306

USER mysql

CMD ["docker-entrypoint.sh", "mysqld"]
