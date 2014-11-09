##
# Drupal/SSH with Nginx, PHP5 and SQLite
##
FROM debian
MAINTAINER http://www.github.com/b7alt/ by b7alt

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update 
RUN apt-get upgrade -y

# NGinx PHP
RUN apt-get install -y supervisor openssh-server nginx php5-fpm php5-sqlite php5-gd php5-cli php5 php5-json php5-cli php5-curl curl php5-mcrypt php5-xdebug mcrypt libmcrypt-dev emacs php-apc wget

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/bin --version=1.0.0-alpha8

# MySql
RUN apt-get install -y mysql-server mysql-client php5-mysql



#RUN update-rc.d nginx disable
#RUN update-rc.d php5-fpm disable
#RUN update-rc.d supervisor disable
#RUN update-rc.d mysql disable
#RUN update-rc.d ssh disable

EXPOSE 22 80 3306

# Drush

RUN composer global require drush/drush:~7.0.0@alpha
RUN ln -sf ~/.composer/vendor/bin/drush /usr/bin/drush



# Drush install with pear
#RUN apt-get install -y php-pear
#RUN pear channel-discover pear.drush.org 
#RUN pear install drush/drush
#RUN drush version
#RUN pear upgrade drush/drush

RUN mkdir -p /var/run/sshd /srv/drupal/www /srv/drupal/config /srv/data /srv/logs /tmp

ADD site.conf /srv/drupal/config/site.conf
ADD nginx.conf /nginx.conf
ADD php-fpm.conf /php-fpm.conf
ADD supervisord.conf /supervisord.conf
ADD settings.php.append /settings.php.append

# php5-apc
RUN sed -i '$a apc.shm_size=128M' /etc/php5/conf.d/20-apc.ini
RUN sed -i '$a apc.include_once_override=0' /etc/php5/conf.d/20-apc.ini

# php parameters
RUN sed -i 's|max_execution_time = 30|max_execution_time = 180 |g' /etc/php5/fpm/php.ini
RUN sed -i 's|memory_limit = 128M|memory_limit = 256M|g' /etc/php5/fpm/php.ini
RUN echo sendmail_path=`which true` >> /etc/php5/fpm/php.ini

#RUN /etc/init.d/mysql start

#RUN /usr/sbin/mysqld &&  mysqladmin --protocol=TCP --host=127.0.0.1 -u root password drupal

ENV DRUPAL_PASSWORD drupal

RUN /usr/sbin/mysqld & \
    sleep 10s &&\
    mysqladmin --protocol=TCP --host=127.0.0.1 -u root password $DRUPAL_PASSWORD &&\
    mysql -uroot -pdrupal -e "CREATE DATABASE drupal; GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY '$DRUPAL_PASSWORD'; FLUSH PRIVILEGES;"


ENV DRUPAL_DISTRO commons

# Drupal distro Install
RUN cd /tmp && drush dl $DRUPAL_DISTRO && mv /tmp/$DRUPAL_DISTRO*/* /srv/drupal/www/ && rm -rf /tmp/*
RUN chmod a+w /srv/drupal/www/sites/default && mkdir /srv/drupal/www/sites/default/files
RUN chmod a+w /srv/drupal/www/sites/default/files
RUN cp /srv/drupal/www/sites/default/default.settings.php /srv/drupal/www/sites/default/settings.php
RUN chown -R www-data:www-data /srv/drupal/www/
RUN chmod a+w /srv/drupal/www/sites/default/settings.php
RUN chown www-data:www-data /srv/data
RUN chmod a+w /srv/drupal/www/sites/default/files


#RUN apt-get install -y sendmail



#RUN /usr/sbin/mysqld & \
    sleep 10s &&\
    cd /srv/drupal/www/ && su - www-data && drush -v si commons --db-url=mysql://drupal:drupal@127.0.0.1/www80 --account-name=admin --account-pass=test --account-mail=admin@test.aaaaaaaa --site-mail=noreply@test.com --site-name="Commons" --yes




#drush -v site-install --db-url=mysql://root@localhost/commons --site-name=QASite --account-name=admin --account-pass=commons --account-mail=admin@example.com --site-mail=site@example.com -v -y commons commons_anonymous_welcome_text_form.commons_anonymous_welcome_title="Oh hai" commons_anonymous_welcome_text_form.commons_anonymous_welcome_body="No shirts, no shoes, no service." commons_create_first_group.commons_first_group_title="Internet People" commons_create_first_group.commons_first_group_body="This is the first group on the page."

#    cd /srv/drupal/www/ && drush -y site-install standard --account-name=admin --account-pass=test --db-url=mysql://drupal:drupal@localhost/www80 --site-name="Your Site Name"

#--db-url=mysql://dbuser:dbpassword@localhost:port/dbname --db-su=root-user --db-su-pw=root-password --site-name="Your Site Name"


#RUN cat /settings.php.append >> /srv/drupal/www/sites/default/settings.php

RUN echo "root:root" | chpasswd

ENTRYPOINT [ "/usr/bin/supervisord", "-n", "-c", "/supervisord.conf", "-e", "trace" ]

#CMD ["bash"]