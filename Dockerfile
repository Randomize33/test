# Используем официальный образ Ubuntu
FROM ubuntu:22.04

# Устанавливаем переменные окружения для автоматического выбора часового пояса
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV COMPOSER_ALLOW_SUPERUSER=1

# Устанавливаем зависимости и обновления
RUN apt-get update && \
    apt-get install -y software-properties-common wget gnupg2 curl unzip git

# Добавляем репозиторий MariaDB
RUN wget -qO - https://mariadb.org/mariadb_release_signing_key.asc | apt-key add - && \
    add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.iweb.com/repo/10.4/ubuntu focal main'

# Добавляем репозиторий для PHP 7.4
RUN add-apt-repository ppa:ondrej/php

# Устанавливаем MariaDB, PHP и Apache
RUN apt-get update && \
    apt-get install -y mariadb-server php7.4 php7.4-mysql php7.4-cli php7.4-curl php7.4-zip php7.4-mbstring php7.4-xml php7.4-json apache2 libapache2-mod-php7.4

# Настраиваем MariaDB
RUN service mysql start && \
    mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY 'root';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;"

# Настраиваем Apache для использования PHP
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod php7.4

# Устанавливаем Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Устанавливаем дополнительные зависимости для Yii2
RUN apt-get install -y php7.4-intl php7.4-gd

# Копируем содержимое Composer в рабочую директорию
WORKDIR /var/www/html

# Очищаем директорию и устанавливаем Yii2 Basic App
RUN rm -rf /var/www/html/* && \
    composer create-project --prefer-dist yiisoft/yii2-app-basic .

# Настраиваем права доступа
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Открываем порты для MariaDB и Apache
EXPOSE 3306 80

# Команда по умолчанию для запуска MariaDB и Apache
CMD service mysql start && service apache2 start && tail -f /dev/null
