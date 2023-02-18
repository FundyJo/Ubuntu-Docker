# Nextcloud ✗ Docker Installation

Dieses Script ist für die erleichterte Installation über Docker von Nextcloud gedacht.
Dabei werden über User Eingaben direkt Benutzername und Passwort von Nextcloud als auch für die dazu gehörige Datenbank gesetzt ... die Daten werden auf einen erstellten Volumen gespeichert wobei jeweils eins für die Datenbank zuständig ist und das andere für Nextcloud.

## Installation

Das Script muss als Sudo User ausgeführt werden! 

```bash
chmod +x docker-nexcloud-install.sh
./docker-nexcloud-install.sh
```

## Benötigte Eingaben

```bash
- Nextcloud Nutzername
- Nextcloud Passwort
- MySQL Benutzername
- MySQL Passwort
```
##### Copyright 17/02/2023 Timo Schiener
