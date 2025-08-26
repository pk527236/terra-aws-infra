#!/bin/bash
set -xe

# write nginx setup script
cat > /tmp/nginx-setup.sh <<'NGINX'
${nginx}
NGINX
chmod +x /tmp/nginx-setup.sh

# write monitoring setup script
cat > /tmp/monitoring-setup.sh <<'MON'
${monitoring}
MON
chmod +x /tmp/monitoring-setup.sh

# run the scripts
bash /tmp/nginx-setup.sh
bash /tmp/monitoring-setup.sh
