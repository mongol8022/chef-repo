#exec ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "/root/.ssh/deploy_key" "$@"

#!/usr/bin/env bash
/usr/bin/env ssh -o StrictHostKeyChecking=no -i "/root/.ssh/id_rsa" $1 $2