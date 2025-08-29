#!/bin/bash
set -euo pipefail

echo "=== Starting Nginx Setup ==="

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install nginx
echo "Installing Nginx..."
sudo apt-get install -y nginx

# Create a simple HTML page for testing
echo "Creating test HTML pages..."
sudo mkdir -p /var/www/html

# Main index page
sudo cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to $(hostname)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .info { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to Your Application</h1>
            <p>Server: $(hostname)</p>
            <p>Time: $(date)</p>
        </div>
        <div class="info">
            <h2>Environment: DEV</h2>
            <p>This is your application running on EC2 instance behind ALB</p>
            <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "N/A")</p>
            <p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "N/A")</p>
        </div>
    </div>
</body>
</html>
EOF

# Health check endpoint
sudo cat > /var/www/html/health <<EOF
OK
EOF

# Create nginx configuration
echo "Configuring Nginx..."
sudo cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm;
    
    server_name _;
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    # Main application
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Nginx status endpoint for monitoring (optional)
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        deny all;
    }
}

# Server block for test1.exclcloud.com
server {
    listen 80;
    server_name test1.exclcloud.com;
    
    root /var/www/html;
    index index.html;
    
    location /health {
        access_log off;
        return 200 "OK - test1.exclcloud.com\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}

# Server block for test2.exclcloud.com
server {
    listen 80;
    server_name test2.exclcloud.com;
    
    root /var/www/html;
    index index.html;
    
    location /health {
        access_log off;
        return 200 "OK - test2.exclcloud.com\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Test nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Enable and start nginx
echo "Starting Nginx service..."
sudo systemctl enable nginx
sudo systemctl restart nginx

# Wait for nginx to start
sleep 5

# Verify nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✓ Nginx is running successfully"
else
    echo "✗ Nginx failed to start"
    sudo systemctl status nginx
    exit 1
fi

# Test the health endpoint locally
echo "Testing health endpoint..."
if curl -f http://localhost/health; then
    echo "✓ Health endpoint is responding"
else
    echo "✗ Health endpoint test failed"
    exit 1
fi

echo "=== Nginx Setup Completed Successfully ==="