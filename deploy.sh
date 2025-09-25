#!/bin/bash

set -e

echo "Starting deployment..."

echo "Loading Node.js..."
export NVM_DIR=~/.nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source ~/.nvm/nvm.sh
    echo "Node.js $(node --version) loaded"
else
    echo "ERROR: NVM not found or not properly installed"
    exit 1
fi

echo "Navigating to project directory..."
if ! cd /var/www/store-backend; then
    echo "ERROR: /var/www/store-backend directory not found"
    exit 1
fi

if [ ! -d ".git" ]; then
    echo "ERROR: Not a git repository"
    exit 1
fi

echo "Fetching latest code..."
if ! git fetch origin; then
    echo "ERROR: Unable to fetch from remote repository"
    exit 1
fi

if ! git reset --hard origin/master; then
    echo "ERROR: Unable to reset to origin/master"
    exit 1
fi

echo "Updated to: $(git log -1 --oneline)"

if [ ! -f "package.json" ]; then
    echo "ERROR: package.json file not found"
    exit 1
fi

echo "Installing dependencies..."
if ! npm install; then
    echo "ERROR: Dependency installation failed"
    exit 1
fi

#echo "Building project..."
#if ! npm run build; then
#    echo "ERROR: Application build failed"
#    exit 1
#fi

echo "Restarting application..."
if pm2 restart store-backend 2>/dev/null; then
    echo "Application restarted successfully"
else
    echo "Starting new PM2 process..."
    if ! pm2 start npm --name store-backend -- run start  -- -p 3013; then
        echo "ERROR: Unable to start PM2 process"
        exit 1
    fi
    if ! pm2 save; then
        echo "WARNING: PM2 save failed - process may not survive server restart"
    fi
    echo "New PM2 process started successfully"
fi

if ! pm2 list | grep -q "store-backend.*online"; then
    echo "ERROR: Application is not running after deployment"
    exit 1
fi

echo "Deployment completed successfully"
