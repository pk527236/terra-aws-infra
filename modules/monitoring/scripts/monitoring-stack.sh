#!/bin/bash
set -euo pipefail

# Enable detailed logging
exec > >(tee /var/log/monitoring-setup.log) 2>&1
echo "Starting monitoring stack setup at $(date)"

# Update system
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget apt-transport-https software-properties-common gnupg2

# Create service users
useradd --no-create-home --shell /bin/false prometheus || true
useradd --no-create-home --shell /bin/false alertmanager || true

# Install Docker (for easier service management)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker
usermod -aG docker ubuntu

# Install Docker Compose (from Terraform template var)
DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION}"
curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create monitoring directory structure
mkdir -p /opt/monitoring/{prometheus,grafana,alertmanager,jenkins}
cd /opt/monitoring

# ------------------------------------------------------------------------------
# Prometheus configuration (TEMPLATE-ENABLED)
#  - Interpolates ${AWS_REGION} and ${env}
#  - Escapes ${1} with $${1} to avoid Terraform templating
# ------------------------------------------------------------------------------
cat > prometheus/prometheus.yml <<PROM_CONFIG
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    ec2_sd_configs:
      - region: ${AWS_REGION}
        port: 9100
        filters:
          - name: "tag:Environment"
            values: ["${env}"]
          - name: "instance-state-name"
            values: ["running"]
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        regex: '(.*)'
        target_label: __address__
        replacement: '$${1}:9100'

  - job_name: 'nginx-exporter'
    ec2_sd_configs:
      - region: ${AWS_REGION}
        port: 9113
        filters:
          - name: "tag:Environment"
            values: ["${env}"]
          - name: "instance-state-name"
            values: ["running"]
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance
      - source_labels: [__meta_ec2_private_ip]
        regex: '(.*)'
        target_label: __address__
        replacement: '$${1}:9113'

  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
PROM_CONFIG

# Create alert rules (no Terraform interpolation needed here)
mkdir -p prometheus/rules
cat > prometheus/rules/alerts.yml <<'ALERT_RULES'
groups:
- name: instance_alerts
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for instance {{ $labels.instance }}"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 85% for instance {{ $labels.instance }}"

  - alert: DiskSpaceLow
    expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 20
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Low disk space"
      description: "Disk space is below 20% for instance {{ $labels.instance }}"

  - alert: NginxDown
    expr: nginx_up == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Nginx is down on {{ $labels.instance }}"
      description: "Nginx has been down for more than 2 minutes on {{ $labels.instance }}"

  - alert: HighNginxConnections
    expr: nginx_connections_active > 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High number of Nginx connections"
      description: "Nginx has {{ $value }} active connections on {{ $labels.instance }}"
ALERT_RULES

# Create Alertmanager configuration (static sample)
cat > alertmanager/alertmanager.yml <<'AM_CONFIG'
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alertmanager@yourdomain.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'email-notifications'

receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'admin@yourdomain.com'
    subject: '🚨 Alert: {{ .GroupLabels.alertname }}'
    html: |
      <h3>Alert Details</h3>
      <table>
      {{ range .Alerts }}
      <tr><td><b>Alert:</b></td><td>{{ .Annotations.summary }}</td></tr>
      <tr><td><b>Description:</b></td><td>{{ .Annotations.description }}</td></tr>
      <tr><td><b>Instance:</b></td><td>{{ .Labels.instance }}</td></tr>
      <tr><td><b>Severity:</b></td><td>{{ .Labels.severity }}</td></tr>
      <tr><td><b>Time:</b></td><td>{{ .StartsAt }}</td></tr>
      {{ end }}
      </table>

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
AM_CONFIG

# Create Grafana provisioning
mkdir -p grafana/provisioning/{dashboards,datasources}

cat > grafana/provisioning/datasources/prometheus.yml <<'GRAFANA_DS'
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://prometheus:9090
  isDefault: true
GRAFANA_DS

cat > grafana/provisioning/dashboards/dashboard.yml <<'GRAFANA_DASH'
apiVersion: 1
providers:
- name: 'default'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  editable: true
  options:
    path: /var/lib/grafana/dashboards
GRAFANA_DASH

# Create Grafana dashboards directory
mkdir -p grafana/dashboards

# Download popular dashboards
curl -o grafana/dashboards/node-exporter-full.json https://grafana.com/api/dashboards/1860/revisions/37/download
curl -o grafana/dashboards/nginx-overview.json https://grafana.com/api/dashboards/12708/revisions/1/download

# Docker Compose (no Terraform interpolation required)
cat > docker-compose.yml <<'COMPOSE'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/rules:/etc/prometheus/rules
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.listen-address=0.0.0.0:9090'
      - '--web.enable-lifecycle'
      - '--storage.tsdb.retention.time=30d'
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.listen-address=0.0.0.0:9093'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.0.0
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    networks:
      - monitoring

  jenkins:
    image: jenkins/jenkins:2.401.3-lts
    container_name: jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:v1.6.1
    container_name: node-exporter
    ports:
      - "9100:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  alertmanager_data:
  grafana_data:
  jenkins_data:
COMPOSE

# Set proper permissions
chown -R 472:472 grafana/
chown -R 65534:65534 prometheus/
chown -R 65534:65534 alertmanager/

# Start all services
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Verify services are running
docker-compose ps

# Install AWS CLI for Jenkins
docker exec jenkins apt-get update
docker exec jenkins apt-get install -y awscli

# ------------------------------------------------------------------------------
# Jenkins Job (TEMPLATE-ENABLED)
#  - Interpolates ${AWS_REGION} and ${ASG_NAME}
#  - Escapes Groovy/Jenkins env ${...} with $${...}
# ------------------------------------------------------------------------------
cat > jenkins-job-config.xml <<JENKINS_JOB
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>Auto-deployment pipeline for web applications</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.92">
    <script>
pipeline {
    agent any
    
    environment {
        AWS_REGION = '${AWS_REGION}'
        ASG_NAME   = '${ASG_NAME}'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/pk527236/terra-aws-infra.git'
            }
        }
        
        stage('Get ASG Instances') {
            steps {
                script {
                    def instances = sh(
                        script: '''
                            aws autoscaling describe-auto-scaling-groups \
                                --auto-scaling-group-names ${ASG_NAME} \
                                --region ${AWS_REGION} \
                                --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
                                --output text
                        ''',
                        returnStdout: true
                    ).trim().split()
                    
                    env.INSTANCE_IDS = instances.join(' ')
                    echo "Found instances: $${env.INSTANCE_IDS}"
                }
            }
        }
        
        stage('Deploy to Instances') {
            steps {
                script {
                    def instanceIds = env.INSTANCE_IDS.split()
                    
                    for (instanceId in instanceIds) {
                        echo "Deploying to instance: ${instanceId}"
                        
                        sh """
                            aws ssm send-command \
                                --region ${AWS_REGION} \
                                --document-name "AWS-RunShellScript" \
                                --instance-ids ${instanceId} \
                                --parameters 'commands=[
                                    "cd /var/www/html/test-website1",
                                    "git clone https://github.com/pk527236/terra-aws-infra.git temp || true",
                                    "cp -r temp/website1/* . 2>/dev/null || echo No website1 content",
                                    "rm -rf temp",
                                    "cd /var/www/html/test-website2",
                                    "git clone https://github.com/pk527236/terra-aws-infra.git temp || true", 
                                    "cp -r temp/website2/* . 2>/dev/null || echo No website2 content",
                                    "rm -rf temp",
                                    "chown -R www-data:www-data /var/www/html",
                                    "systemctl reload nginx"
                                ]'
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
            slackSend color: 'good', message: "✅ Deployment successful for $${env.JOB_NAME} #$${env.BUILD_NUMBER}"
        }
        failure {
            echo 'Deployment failed!'
            slackSend color: 'danger', message: "❌ Deployment failed for $${env.JOB_NAME} #$${env.BUILD_NUMBER}"
        }
    }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
JENKINS_JOB

echo "Monitoring stack setup completed at $(date)"
echo ""
echo "🎉 Services are now accessible at:"
echo "  📊 Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "  📈 Grafana:    http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000 (admin/admin123)"
echo "  🚨 Alertmanager: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9093"
echo "  🔨 Jenkins:    http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "📋 Next steps:"
echo "1. Configure Grafana datasources and import dashboards"
echo "2. Update Alertmanager with your email settings"
echo "3. Set up Jenkins with your GitHub repository"
echo "4. Add AWS credentials to Jenkins for deployment"
