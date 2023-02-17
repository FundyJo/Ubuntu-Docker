#!/bin/bash

# Prüfen, ob die Volumes schon erstellt wurden
if [ "$(docker volume ls -q -f name=db_data)" ] && [ "$(docker volume ls -q -f name=nextcloud_data)" ]; then
    echo "Volumes 'db_data' und 'nextcloud_data' sind schon vorhanden."
    exit 0
fi

# Installation von Docker, Docker.io und Docker-Compose

apt update

echo "Es wird überprüft ob bereits schon Docker.io installiert wurde ..."

if command -v docker.io >/dev/null 2>&1; then
    echo "Docker.io ist bereits installiert."
else
    echo "Docker.io ist noch nicht installiert."
    echo "Installiere Docker.io"
    echo " "
    echo "                     ACHTUNG"
    echo " Dieses Prozess kann etwas länger dauern abhängend"
    echo "   von der Internet Geschwindigkeit und weiteren"
    echo "   Faktoren gedulden sie sich bitte daher etwas"
    echo " "
    apt install -y docker.io
fi

if command -v docker-compose >/dev/null 2>&1; then
    echo "Docker-Compose is installed."
else
    echo "Docker-Compose is not installed."
    echo " "
    echo "                     ACHTUNG"
    echo " Dieses Prozess kann etwas länger dauern abhängend"
    echo "   von der Internet Geschwindigkeit und weiteren"
    echo "   Faktoren gedulden sie sich bitte daher etwas"
    echo " "
    apt install -y docker-compose
fi


# Volume erstellen
docker volume create db_data
docker volume create nextcloud_data

# Benutzereingabe für Nextcloud
echo "Geben Sie bitte den gewünschten Nextcloud-Benutzernamen ein: "
read nextcloud_user
echo "Geben Sie bitte das gewünschte Nextcloud-Passwort ein: "
read -s nextcloud_password
echo "Bitte bestätigen Sie das Passwort erneut: "
read -s nextcloud_password_confirmation

while [[ "$nextcloud_password" != "$nextcloud_password_confirmation" ]]; do
    echo "Passwörter stimmen nicht überein. Bitte versuchen Sie es erneut."
    echo "Geben Sie bitte das gewünschte Nextcloud-Passwort ein: "
    read -s nextcloud_password
    echo "Bitte bestätigen Sie das Passwort erneut: "
    read -s nextcloud_password_confirmation
done

# Benutzereingabe für MySQL
echo "Geben Sie bitte den gewünschten MySQL-Benutzernamen ein: "
read mysql_user
echo "Geben Sie bitte das gewünschte MySQL-Passwort ein: "
read -s mysql_password
echo "Bitte bestätigen Sie das Passwort erneut: "
read -s mysql_password_confirmation

while [[ "$mysql_password" != "$mysql_password_confirmation" ]]; do
    echo "Passwörter stimmen nicht überein. Bitte versuchen Sie es erneut."
    echo "Geben Sie bitte das gewünschte MySQL-Passwort ein: "
    read -s mysql_password
    echo "Bitte bestätigen Sie das Passwort erneut: "
    read -s mysql_password_confirmation
done

# Docker-Compose-Datei erstellen
cat > docker-compose.yml << EOF
version: '3'

services:
  db:
    image: mysql:5.7
    restart: always # Container automatisch starten
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: $mysql_user
      MYSQL_PASSWORD: $mysql_password
    volumes:
      - db_data:/var/lib/mysql
  app:
    image: nextcloud
    restart: always # Container automatisch starten
    ports:
      - "80:80"
    volumes:
      - nextcloud_data:/var/www/html
    depends_on:
      - db
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: $mysql_user
      MYSQL_PASSWORD: $mysql_password
      NEXTCLOUD_ADMIN_USER: $nextcloud_user
      NEXTCLOUD_ADMIN_PASSWORD: $nextcloud_password

volumes:
  db_data:
  nextcloud_data:
EOF

# Docker-Compose ausführen
docker-compose up -d

# Überprüfen ob das der Container gestartet wurde und läuft
if docker ps -a | grep nextcloud >/dev/null 2>&1; then
  echo "Der Container ist nun erreichbar unter (localhost:80)"
else
  echo "Ein Fehler ist aufgetreten."
fi

