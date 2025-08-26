#!/bin/bash
set -e

# install node exporter (Prometheus) - using v1.6.1 as example
NODE_EXPORTER_VERSION="1.6.1"
useradd --no-create-home --shell /bin/false node_exporter || true

cd /tmp
curl -sSL -o node_exporter.tar.gz \
  "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

tar xzf node_exporter.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service <<'SERVICE'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now node_exporter
