#!/bin/bash

# Setup script for using local PostgreSQL with Titan Wallet

echo "🔧 Setting up Titan Wallet with your local PostgreSQL..."
echo ""

# Check if blnk database exists
echo "1️⃣ Checking if 'blnk' database exists..."
if psql -U pushkar -lqt | cut -d \| -f 1 | grep -qw blnk; then
    echo "   ✅ Database 'blnk' already exists"
else
    echo "   📝 Creating database 'blnk'..."
    createdb -U pushkar blnk
    echo "   ✅ Database 'blnk' created"
fi

echo ""
echo "2️⃣ Verifying connection..."
if psql -U pushkar -d blnk -c "SELECT 1;" > /dev/null 2>&1; then
    echo "   ✅ Successfully connected to blnk database"
else
    echo "   ❌ Could not connect to database"
    echo "   Please check your PostgreSQL credentials"
    exit 1
fi

echo ""
echo "3️⃣ Checking Docker configuration..."
if [ -f "docker-compose.override.yml" ]; then
    echo "   ✅ docker-compose.override.yml exists"
else
    echo "   ❌ docker-compose.override.yml not found"
    exit 1
fi

if [ -f "config/blnk-local.json" ]; then
    echo "   ✅ config/blnk-local.json exists"
else
    echo "   ❌ config/blnk-local.json not found"
    exit 1
fi

echo ""
echo "✅ Setup complete! You can now run:"
echo "   docker-compose up"
echo ""
echo "This will:"
echo "  • Skip Docker PostgreSQL (use your local one)"
echo "  • Start Redis, Typesense, Blnk, and all Titan services"
echo "  • Connect everything to postgresql://pushkar@localhost:5432/blnk"
echo ""
