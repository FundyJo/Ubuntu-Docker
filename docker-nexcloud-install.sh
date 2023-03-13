#!/bin/bash

# Feststellen der Linux-Distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
else
    OS=$(uname -s)
fi

# Installation von Docker, Docker.io und Docker-Compose
if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    apt update
    if command -v docker >/dev/null 2>&1; then
        echo "Docker wird installiert."
    else
        apt install -y docker
    fi
    if command -v docker.io >/dev/null 2>&1; then
        echo "Docker.io ist bereits installiert."
    else
        echo "Docker.io wird installiert."
        apt install -y docker.io
    fi
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "Docker-Compose wird installiert."
        apt install -y docker-compose
    fi
elif [ "$OS" == "centos" ] || [ "$OS" == "fedora" ]; then
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "Docker-Compose wird installiert."
        curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
else
    echo "Ihre Linux-Distribution wird derzeit nicht unterstützt."
    exit 1
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

echo "Passwörter stimmen überein!"
echo "Achtung der Container wird nun aufgesetzt und verbunden!"

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
      echo " "
      echo "                     NOTIZ"
      echo " Die erreichbarkeit der Website dauert im normal Fall"
      echo "   20 - 30 Sekunden da der Container vollstädige starten"
      echo "     muss ... gedulden sie sich bitte daher etwas"
      echo " "
else
  echo "Ein Fehler ist aufgetreten."
fi
