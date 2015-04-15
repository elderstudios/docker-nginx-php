FROM phusion/baseimage:0.9.16

MAINTAINER Aran Wilkinson "aran.wilkinson@elder-studios.co.uk"
ENV DEBIAN_FRONTEND noninteractive

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

# Enable SSH
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Update system
RUN apt-get update && apt-get dist-upgrade -y

# Install useful packages
RUN apt-get install -y curl wget build-essential python-software-properties

# Add latest PHP 5.6 and Nginx packages
RUN add-apt-repository -y ppa:ondrej/php5-5.6
RUN add-apt-repository -y ppa:nginx/stable

# Update system
RUN apt-get update 

# Install PHP and Extensions
RUN apt-get install -y --force-yes \
	php5-cli \
	php5-json \
	php5-intl \
	php5-fpm \
	php5-curl\
	php5-mcrypt

# Set timezone up for PHP
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

# Install Nginx
RUN apt-get install -y nginx

# Configure Nginx and PHP-FPM
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
 
# Prepare directory
RUN mkdir -p /var/www
RUN usermod -u 1000 www-data
RUN usermod -a -G users www-data
RUN chown -R www-data:www-data /var/www

# Configure Nginx Vhost
ADD config/nginx/default   /etc/nginx/sites-available/default

# Configure runit
RUN mkdir                  /etc/service/nginx
ADD config/init/nginx.sh   /etc/service/nginx/run
RUN chmod +x               /etc/service/nginx/run
RUN mkdir                  /etc/service/phpfpm
ADD config/init/php-fpm.sh  /etc/service/phpfpm/run
RUN chmod +x               /etc/service/phpfpm/run

EXPOSE 80
# End Nginx-PHP

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*