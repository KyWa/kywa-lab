#!/usr/bin/env bash

systemctl enable --now podman.socket

### SETUP NETWORK VOLUMES ###
podman volume create --opt type=nfs --opt o=async --opt device=10.0.0.10:/volume1/containers/photoprism_app photoprism_app
podman volume create --opt type=nfs --opt o=async --opt device=10.0.0.10:/volume1/containers/phootoprism_db photoprism_db
podman volume create --opt type=nfs --opt o=async --opt device=10.0.0.10:/volume1/containers/nginxproxy/ nginxproxy

### CREATE CONTAINERS ###

# Portainer
podman run -d -p 8000 -p 9443 --privileged --name portainer --restart unless-stopped -v /var/run/podman/podman.sock:/var/run/docker.sock portainer/portainer-ce

# Proxy Manager
podman run --name=proxy-manager -d --cpus "0.5" --memory "512Mb" -p 80:80 -p 443:443 -p 81:81 -v nginxproxy:/data:z -v nginxproxy:/etc/letsencrypt:z --restart unless-stopped jc21/nginx-proxy-manager:latest

# Portal
podman run --name=portal -d --cpus "0.5" --memory "512Mb" --restart unless-stopped -p 8080:80 -p 8443:443 -e PUID=1000 -e PGID=1000 -e TZ=America/Chicago lscr.io/linuxserver/heimdall:latest

# Photoprism
podman run -d --net photoprism --name=photoprism_db -e MARIADB_USER=photoprism -e MARIADB_PASSWORD=photoprism -e MARIADB_DATABASE=photoprism -e MARIADB_ROOT_PASSWORD=insecure --restart unless-stopped docker.io/mariadb:10.8 mysqld --innodb-buffer-pool-size=512M --transaction-isolation=READ-COMMITTED --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --max-connections=512 --innodb-rollback-on-timeout=OFF --innodb-lock-wait-timeout=120

podman run --name=photoprism_app -d -e PHOTOPRISM_ADMIN_PASSWORD=insecure -e PHOTOPRISM_SITE_URL=http://services.kywa.io/ -e PHOTOPRISM_ORIGINALS_LIMIT=5000 -e PHOTOPRISM_HTTP_COMPRESSION=gzip -e PHOTOPRISM_LOG_LEVEL=info -e PHOTOPRISM_PUBLIC=false -e PHOTOPRISM_READONLY=false -e PHOTOPRISM_EXPERIMENTAL=false -e PHOTOPRISM_DISABLE_CHOWN=false -e PHOTOPRISM_DISABLE_WEBDAV=false -e PHOTOPRISM_DISABLE_SETTINGS=false -e PHOTOPRISM_DISABLE_TENSORFLOW=false -e PHOTOPRISM_DISABLE_FACES=false -e PHOTOPRISM_DISABLE_CLASSIFICATION=false -e PHOTOPRISM_DISABLE_RAW=false -e PHOTOPRISM_RAW_PRESETS=false -e PHOTOPRISM_JPEG_QUALITY=85 -e PHOTOPRISM_DETECT_NSFW=false -e PHOTOPRISM_UPLOAD_NSFW=true -e PHOTOPRISM_DATABASE_DRIVER=mysql -e PHOTOPRISM_DATABASE_SERVER=photoprism_db:3306 -e PHOTOPRISM_DATABASE_NAME=photoprism -e PHOTOPRISM_DATABASE_USER=photoprism -e PHOTOPRISM_DATABASE_PASSWORD=photoprism -e PHOTOPRISM_SITE_CAPTION="AI-Powered Photos App" -e PHOTOPRISM_SITE_DESCRIPTION="Walker Photos" -e PHOTOPRISM_SITE_AUTHOR="Kyle Walker"  -v photoprism_app:/photoprism/originals -v /data/photoprism/storage/:/photoprism/storage:z --net photoprism --restart unless-stopped --network-alias photoprism -p 2342 -w /photoprism docker.io/photoprism/photoprism:latest
