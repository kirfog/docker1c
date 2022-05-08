FROM centos:7 as builder
RUN yum -y update
RUN yum -y install epel-release
WORKDIR /opt

FROM builder AS app
COPY opt/*.tar.gz /opt/
ARG ver1c
RUN yum -y install cabextract lcms2
RUN yum -y install https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
RUN tar zxf *.tar.gz && /opt/*.run --mode unattended --enable-components server && rm /opt/*.* -rf
RUN mkdir /var/log/1c/
RUN ln -s /opt/1cv8/x86_64/$ver1c/srv1cv83 /etc/init.d/srv1cv83
RUN ln -s /opt/1cv8/x86_64/$ver1c/srv1cv83.conf /etc/sysconfig/srv1cv83
CMD chown usr1cv8: -R /home/usr1cv8 && chown usr1cv8: -R /var/log/1c && /etc/init.d/srv1cv83 start && /bin/bash 

FROM builder AS db
COPY opt/*.tar.bz2 /opt/
ARG verpg
ARG passpg
RUN yum -y install centos-release-scl-rh bzip2
RUN for f in *.tar.bz2; do tar jxf "$f"; done && yum -y localinstall /opt/*/* && rm /opt/postgres* -rf && rm /opt/*.* -rf
RUN sed -i '/en_US/d' /etc/yum.conf
RUN yum -y reinstall glibc-common
RUN echo $passpg > /opt/password
RUN chown postgres:postgres /opt/password
RUN chmod 600 /opt/password
RUN echo "/usr/pgsql-$verpg/bin/initdb -D /var/lib/pgsql/$verpg/data/ --locale=ru_RU.UTF8 -A md5 --pwfile=/opt/password" > /opt/run
RUN echo "/usr/pgsql-$verpg/bin/pg_ctl -D /var/lib/pgsql/$verpg/data/ start" >> /opt/run
RUN echo "PGPASSWORD=$passpg psql -U postgres" >> /opt/run
RUN chown postgres:postgres /opt/run
RUN chmod +x /opt/run
CMD chown -R postgres:postgres /var/lib/pgsql/ && su postgres -c '/opt/run'

FROM builder AS web
COPY opt/*.tar.gz /opt/
ARG ver1c
RUN yum -y install httpd mod_ssl
RUN tar zxf *.tar.gz && /opt/*.run --mode unattended --enable-components ws && rm /opt/*.* -rf
CMD /usr/sbin/httpd -D FOREGROUND