#!/bin/bash

# Titan Wallet - Port Conflict Checker
# Run this before starting docker-compose to check for port conflicts

echo "🔍 Checking for port conflicts..."
echo ""

PORTS=(
  "5432:PostgreSQL (Blnk database)"
  "6379:Redis (Cache & Queue)"
  "8108:Typesense (Search)"
  "5001:Blnk Ledger API"
  "8001:HRS (Handle Resolution)"
  "8002:Payment Router"
  "8003:ACH Service"
  "8004:Auth Service"
  "8005:Notification Service"
  "8006:User Management"
  "8007:Webhook Service"
  "8008:Reconciliation Service"
)

CONFLICTS=0

for PORT_INFO in "${PORTS[@]}"; do
  PORT="${PORT_INFO%%:*}"
  SERVICE="${PORT_INFO#*:}"

  # Check if port is in use
  if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    CONFLICTS=$((CONFLICTS + 1))
    echo "❌ Port $PORT is ALREADY IN USE (needed for $SERVICE)"

    # Show what's using the port
    echo "   Process using port $PORT:"
    lsof -Pi :$PORT -sTCP:LISTEN | tail -n +2 | awk '{printf "   → %s (PID: %s)\n", $1, $2}'
    echo ""
  else
    echo "✅ Port $PORT is available ($SERVICE)"
  fi
done

echo ""

if [ $CONFLICTS -gt 0 ]; then
  echo "⚠️  Found $CONFLICTS port conflict(s)!"
  echo ""
  echo "Options to resolve:"
  echo "1. Stop the conflicting services:"
  echo "   - Local PostgreSQL: brew services stop postgresql"
  echo "   - Local Redis: brew services stop redis"
  echo ""
  echo "2. Change Docker ports in docker-compose.yml:"
  echo "   Example: '5433:5432' instead of '5432:5432'"
  echo ""
  echo "3. Use existing local services (modify docker-compose.yml):"
  echo "   - Remove PostgreSQL/Redis containers"
  echo "   - Point services to localhost instead"
  echo ""
  exit 1
else
  echo "✅ All ports are available!"
  echo "You can safely run: docker-compose up"
  exit 0
fi
