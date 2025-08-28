#!/bin/bash
set -euo pipefail

# Logging for debugging
exec > >(tee /var/log/nginx-setup.log) 2>&1
echo "Starting nginx setup at $(date)"

# Update packages
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install nginx and openssl
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx openssl curl

# Create document roots
mkdir -p /var/www/html/test-website1
mkdir -p /var/www/html/test-website2

# Get instance metadata
HOSTNAME=$(hostname)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "N/A")
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "N/A")

# Create sample HTML files (using unquoted heredoc for variable substitution)
cat > /var/www/html/test-website1/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Test Website 1</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .info { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .healthy { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Welcome to test1.exclcloud.com</h1>
        <div class="info">
            <p><strong>Document Root:</strong> /var/www/html/test-website1/</p>
            <p><strong>Server Hostname:</strong> $HOSTNAME</p>
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>Generated at:</strong> $(date)</p>
            <p class="healthy">✅ Server Status: HEALTHY</p>
        </div>
        <p>This is <strong>Test Website 1</strong> served by nginx on an EC2 instance behind an Application Load Balancer.</p>
    </div>
</body>
</html>
HTML

cat > /var/www/html/test-website2/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Test Website 2</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #fff8f0; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #e74c3c; border-bottom: 2px solid #e67e22; padding-bottom: 10px; }
        .info { background: #fdf2e9; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .healthy { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to test2.exclcloud.com</h1>
        <div class="info">
            <p><strong>Document Root:</strong> /var/www/html/test-website2/</p>
            <p><strong>Server Hostname:</strong> $HOSTNAME</p>
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Availability Zone:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>Generated at:</strong> $(date)</p>
            <p class="healthy">✅ Server Status: HEALTHY</p>
        </div>
        <p>This is <strong>Test Website 2</strong> served by nginx on an EC2 instance behind an Application Load Balancer.</p>
    </div>
</body>
</html>
HTML

# Create a default health check page (this is critical for ALB health checks)
cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Load Balancer Health Check</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f8fff8; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #27ae60; text-align: center; }
        .status { text-align: center; font-size: 1.2em; margin: 20px 0; }
        .healthy { color: #27ae60; font-weight: bold; }
        .info { background: #f0f0f0; padding: 10px; border-radius: 5px; margin: 10px 0; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🟢 Server Health Check</h1>
        <div class="status healthy">✅ STATUS: OK</div>
        <div class="info">
            <p><strong>Server:</strong> $HOSTNAME</p>
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Zone:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>Checked at:</strong> $(date)</p>
        </div>
    </div>
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

# Create DEFAULT site configuration (for health checks and fallback)
cat > /etc/nginx/sites-available/default <<'NGCONF'
server {
    listen 80 default_server;
    server_name _;

    root /var/www/html;
    index index.html index.htm;

    access_log /var/log/nginx/default_access.log;
    error_log /var/log/nginx/default_error.log;

    # Health check endpoint - CRITICAL for ALB health checks
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
        access_log off;
    }

    # Root endpoint for default health checks
    location / {
        try_files $uri $uri/ =404;
    }
}
NGCONF

# Create nginx configurations for specific domains
cat > /etc/nginx/sites-available/test1 <<'NGCONF'
server {
    listen 80;
    server_name test1.exclcloud.com;
    
    root /var/www/html/test-website1;
    index index.html index.htm;

    access_log /var/log/nginx/test1_access.log;
    error_log /var/log/nginx/test1_error.log;

    # Health check endpoint
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
        access_log off;
    }

    location / {
        try_files $uri $uri/ =404;
    }
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

    access_log /var/log/nginx/test1_ssl_access.log;
    error_log /var/log/nginx/test1_ssl_error.log;

    # Health check endpoint
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
        access_log off;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
NGCONF

cat > /etc/nginx/sites-available/test2 <<'NGCONF'
server {
    listen 80;
    server_name test2.exclcloud.com;
    
    root /var/www/html/test-website2;
    index index.html index.htm;

    access_log /var/log/nginx/test2_access.log;
    error_log /var/log/nginx/test2_error.log;

    # Health check endpoint
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
        access_log off;
    }

    location / {
        try_files $uri $uri/ =404;
    }
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

    access_log /var/log/nginx/test2_ssl_access.log;
    error_log /var/log/nginx/test2_ssl_error.log;

    # Health check endpoint
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
        access_log off;
    }

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

    # Nginx status endpoint for monitoring
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
    }

    # Health check endpoint (accessible from ALB)
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
        access_log off;
    }

    # Default status page
    location / {
        return 200 "Nginx Status Server - OK\n";
        add_header Content-Type text/plain;
    }
}
NGCONF

# Enable sites
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/test1 /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/test2 /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/status /etc/nginx/sites-enabled/

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Test nginx configuration
echo "Testing nginx configuration..."
if nginx -t; then
    echo "✅ Nginx configuration test passed"
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Start and enable nginx
systemctl enable nginx
systemctl restart nginx

# Wait a moment for nginx to fully start
sleep 5

# Check if nginx is running
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running successfully"
else
    echo "❌ Nginx failed to start"
    systemctl status nginx --no-pager
    exit 1
fi

# Test local connections
echo "Testing local nginx connections..."
echo "Testing default site..."
if curl -f http://localhost/ > /dev/null 2>&1; then
    echo "✅ Default site test passed"
else
    echo "❌ Default site test failed"
fi

echo "Testing health endpoint..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Health endpoint test passed"
else
    echo "❌ Health endpoint test failed"
fi

echo "Testing status endpoint..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Status endpoint test passed"
else
    echo "❌ Status endpoint test failed"
fi

echo "✅ Nginx setup completed successfully at $(date)"
echo "🌐 Available endpoints:"
echo "   - Default site: http://localhost/"
echo "   - Health check: http://localhost/health"
echo "   - Status server: http://localhost:8080/health"
echo "   - Nginx metrics: http://localhost:8080/nginx_status"