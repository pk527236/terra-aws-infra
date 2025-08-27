# MODULES/ASG/SCRIPTS/MONITORING-SETUP.SH
# ==============================================================================

#!/bin/bash
set -euo pipefail

# Install Node Exporter
NODE_EXPORTER_VERSION="1.6.1"
useradd --no-create-home --shell /bin/false node_exporter || true

cd /tmp
curl -sSL -o node_exporter.tar.gz \
  "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

tar xzf node_exporter.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service for node_exporter
cat > /etc/systemd/system/node_exporter.service <<'SERVICE'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

# Install Nginx Exporter
NGINX_EXPORTER_VERSION="0.11.0"
useradd --no-create-home --shell /bin/false nginx_exporter || true

curl -sSL -o nginx_exporter.tar.gz \
  "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz"

tar xzf nginx_exporter.tar.gz
cp nginx-prometheus-exporter /usr/local/bin/
chown nginx_exporter:nginx_exporter /usr/local/bin/nginx-prometheus-exporter

# Create systemd service for nginx_exporter
cat > /etc/systemd/system/nginx_exporter.service <<'SERVICE'
[Unit]
Description=Nginx Exporter
After=network.target

[Service]
User=nginx_exporter
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost:8080/nginx_status
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

# Reload systemd and start services
systemctl daemon-reload
systemctl enable --now node_exporter
systemctl enable --now nginx_exporter

echo "Monitoring setup completed successfully"