# MODULES/ASG/SCRIPTS/NGINX-SETUP.SH
# ==============================================================================

#!/bin/bash
set -euo pipefail

# Update packages
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install nginx and openssl
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx openssl curl

# Create document roots
mkdir -p /var/www/html/test-website1
mkdir -p /var/www/html/test-website2

# Create sample HTML files
cat > /var/www/html/test-website1/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Test Website 1</title>
</head>
<body>
    <h1>Welcome to test1.exclcloud.com</h1>
    <p>This is served from /var/www/html/test-website1/</p>
    <p>Server: $(hostname)</p>
</body>
</html>
HTML

cat > /var/www/html/test-website2/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Test Website 2</title>
</head>
<body>
    <h1>Welcome to test2.exclcloud.com</h1>
    <p>This is served from /var/www/html/test-website2/</p>
    <p>Server: $(hostname)</p>
</body>
</html>
HTML

# Create SSL directory
mkdir -p /etc/nginx/ssl

# Generate self-signed certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/test1.key \
  -out /etc/nginx/ssl/test1.crt \
  -subj "/C=US/ST=CA/L=SF/O=Test1/CN=test1.exclcloud.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/test2.key \
  -out /etc/nginx/ssl/test2.crt \
  -subj "/C=US/ST=CA/L=SF/O=Test2/CN=test2.exclcloud.com"

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create nginx configurations
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
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/html/test-website1;
    index index.html index.htm;

    access_log /var/log/nginx/test1_access.log;
    error_log /var/log/nginx/test1_error.log;

    location / {
        try_files $uri $uri/ =404;
    }
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
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/html/test-website2;
    index index.html index.htm;

    access_log /var/log/nginx/test2_access.log;
    error_log /var/log/nginx/test2_error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGCONF

# Create status server for monitoring
cat > /etc/nginx/sites-available/status <<'NGCONF'
server {
    listen 8080;
    server_name localhost;

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        deny all;
    }

    location / {
        return 200 "Nginx Status Server\n";
        add_header Content-Type text/plain;
    }
}
NGCONF

# Enable sites
ln -sf /etc/nginx/sites-available/test1 /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/test2 /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/status /etc/nginx/sites-enabled/

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Test nginx configuration
nginx -t

# Start and enable nginx
systemctl enable nginx
systemctl restart nginx

echo "Nginx setup completed successfully"