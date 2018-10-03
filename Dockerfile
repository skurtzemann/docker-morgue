FROM alpine:3.8
MAINTAINER Sébastieb Kurtzemann "seb@kurtzemann.fr"

RUN apk add --no-cache \
    bash \
    postfix \
    git \
    apache2 \
    php7 \
    php7-apache2 \
    php7-curl \
    php7-mysqli \
    php7-openssl \
    php7-json \
    php7-phar \
    php7-pdo \
    php7-pdo_mysql \
    php7-iconv \
    php7-mbstring \
    php7-dom \
    php7-xml \
    php7-xmlwriter \
    php7-tokenizer \
    php7-ctype \
    php7-session \
    php7-simplexml

RUN cd /var/www/ \
  && git clone https://github.com/etsy/morgue.git morgue \
  && mv /var/www/morgue/config/example.json /var/www/morgue/config/example.json.orig \
  && mkdir -p /run/apache2 \
  && chgrp www-data /run/apache2 \
  && chmod 775 /run/apache2 \
  && chown apache:apache logs \
  && chmod g+w /var/log/apache2 \
  && addgroup apache wheel

ENV MORGUE_GIT_SHA1 b170a9649fe3bcd6ed25016e709ad87fb0e6c6d9
RUN cd /var/www/morgue \
  && git checkout ${MORGUE_GIT_SHA1} \
  && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php --install-dir=/var/www/morgue \
  && php -r "unlink('composer-setup.php');" \
  && php composer.phar update

RUN apk del git \
  && rm -rf /var/cache/apk/* \
  && rm -rf /var/www/localhost

RUN postconf "smtputf8_enable = no" \
  && postfix start

ADD httpd.conf /etc/apache2/httpd.conf
ADD htpasswd /etc/htpasswd/.htpasswd
ADD entrypoint.sh /

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["httpd","-D","FOREGROUND"]
