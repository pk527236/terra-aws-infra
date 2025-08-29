#!/bin/bash
set -euo pipefail

# Enable detailed logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data execution at $(date)"

# Update system first
echo "Updating system packages..."
sudo apt-get update -y

# Write nginx setup script
cat > /tmp/nginx-setup.sh <<'NGINX'
${nginx}
NGINX
chmod +x /tmp/nginx-setup.sh

# Run nginx setup with proper error handling
echo "Running nginx setup..."
if sudo bash /tmp/nginx-setup.sh; then
    echo "Nginx setup completed successfully"
else
    echo "Nginx setup failed with exit code $?"
    exit 1
fi

# Verify nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "Nginx is running successfully"
else
    echo "Nginx is not running, attempting to start..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

# Test health endpoint
echo "Testing health endpoint..."
sleep 10  # Give nginx time to fully start
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "Health endpoint is responding correctly"
else
    echo "Health endpoint test failed"
    # Show nginx status and logs for debugging
    sudo systemctl status nginx
    sudo tail -20 /var/log/nginx/error.log
fi

echo "User data execution completed at $(date)"