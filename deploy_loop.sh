#!/bin/bash
echo "[$(date)] Checking network connectivity for Vercel deployment..."
if curl -s -o /dev/null -w "%{http_code}" https://api.vercel.com | grep -q "2\|3"; then
    echo "[$(date)] ✅ Vercel API reachable - attempting deployment"
    vercel deploy --prod --yes
    if [ $? -eq 0 ]; then
        echo "[$(date)] 🎉 Deployment successful!"
        exit 0
    else
        echo "[$(date)] ❌ Deployment failed, will retry next cycle"
    fi
else
    echo "[$(date)] ❌ Vercel API not reachable - waiting for network"
fi
