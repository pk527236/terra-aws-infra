# MODULES/ASG/SCRIPTS/USER-DATA.TPL
# ==============================================================================

#!/bin/bash
set -euo pipefail

# Enable detailed logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data execution at $(date)"

# Write nginx setup script
cat > /tmp/nginx-setup.sh <<'NGINX'
${nginx}
NGINX
chmod +x /tmp/nginx-setup.sh

# Write monitoring setup script
cat > /tmp/monitoring-setup.sh <<'MON'
${monitoring}
MON
chmod +x /tmp/monitoring-setup.sh

# Run the scripts
echo "Running nginx setup..."
bash /tmp/nginx-setup.sh

echo "Running monitoring setup..."
bash /tmp/monitoring-setup.sh

echo "User data execution completed at $(date)"