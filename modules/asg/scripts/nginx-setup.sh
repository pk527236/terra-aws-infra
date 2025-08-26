#!/bin/bash
set -e

# Update packages
apt-get update -y
apt-get upgrade -y

# Install nginx and openssl
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx openssl

# Create document roots
mkdir -p /var/www/html/test-website1
mkdir -p /var/www/html/test-website2

cat > /var/www/html/test-website1/index.html <<'HTML'
<h1>Welcome to test1.exclcloud.com</h1>
HTML

cat > /var/www/html/test-website2/index.html <<'HTML'
<h1>Welcome to test2.exclcloud.com</h1>
HTML

# Create SSL directory
mkdir -p /etc/nginx/ssl

# Self-signed cert for test1
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/test1.key \
  -out /etc/nginx/ssl/test1.crt \
  -subj "/CN=test1.exclcloud.com/O=Test1"

# Self-signed cert for test2
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/test2.key \
  -out /etc/nginx/ssl/test2.crt \
  -subj "/CN=test2.exclcloud.com/O=Test2"

# Nginx site configs
cat > /etc/nginx/sites-available/test1 <<'NGCONF'
server {
    listen 80;
    server_name test1.exclcloud.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name test1.exclcloud.com;

    ssl_certificate /etc/nginx/ssl/test1.crt;
    ssl_certificate_key /etc/nginx/ssl/test1.key;

    root /var/www/html/test-website1;
    index index.html;

    access_log /var/log/nginx/test1_access.log;
    error_log /var/log/nginx/test1_error.log;
}
NGCONF

cat > /etc/nginx/sites-available/test2 <<'NGCONF'
server {
    listen 80;
    server_name test2.exclcloud.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name test2.exclcloud.com;

    ssl_certificate /etc/nginx/ssl/test2.crt;
    ssl_certificate_key /etc/nginx/ssl/test2.key;

    root /var/www/html/test-website2;
    index index.html;

    access_log /var/log/nginx/test2_access.log;
    error_log /var/log/nginx/test2_error.log;
}
NGCONF

# Enable sites (Ubuntu layout)
ln -sf /etc/nginx/sites-available/test1 /etc/nginx/sites-enabled/test1
ln -sf /etc/nginx/sites-available/test2 /etc/nginx/sites-enabled/test2

# Disable default site to avoid conflicts
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
fi

# Ensure correct permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Validate and restart nginx
nginx -t
systemctl enable nginx
systemctl restart nginx
