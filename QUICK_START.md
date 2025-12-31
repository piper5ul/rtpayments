# 🚀 Quick Start - Titan Wallet

**Get up and running in 3 minutes!**

---

## Step 1: Create Database (One-Time Setup)

```bash
createdb -U pushkar blnk
```

---

## Step 2: Start Services

```bash
cd titan-backend-services/
./scripts/start.sh
```

This will:
- ✅ Check for port conflicts
- ✅ Build all Docker images
- ✅ Start 5 services (PostgreSQL, Redis, Typesense, Blnk, HRS)
- ✅ Wait for health checks
- ✅ Show you the status

---

## Step 3: Test It!

```bash
# Resolve a handle (sample data pre-loaded)
curl "http://localhost:8001/handles/resolve?handle=alice"

# Expected response:
{
  "handle": "alice",
  "user_id": "...",
  "account_id": "bal_sample_alice_001",
  "is_active": true,
  "resolved_at": "2025-12-30T..."
}
```

**More test commands:**

```bash
# Try other handles
curl "http://localhost:8001/handles/resolve?handle=bob"
curl "http://localhost:8001/handles/resolve?handle=charlie"

# Create your own handle
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{
    "handle": "yourname",
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "account_id": "bal_yourname_001"
  }'

# Check health
curl http://localhost:8001/health
```

---

## Step 4: Explore

### View Logs
```bash
make logs-hrs     # HRS logs only
make logs         # All services
```

### Check Health
```bash
make health
```

### Access Database
```bash
make shell-postgres
# Then: SELECT * FROM handles;
```

### Restart Services
```bash
make restart-hrs
```

### Stop Everything
```bash
make down
```

---

## 📚 What to Read Next

1. **[WHAT_I_BUILT_2025-12-30.md](WHAT_I_BUILT_2025-12-30.md)** - Complete overview of what's built
2. **[titan-backend-services/README.md](titan-backend-services/README.md)** - Full service documentation
3. **[docs/ENCRYPTION_STRATEGY_2025-12-30.md](docs/ENCRYPTION_STRATEGY_2025-12-30.md)** - Security implementation
4. **[NEXT_STEPS.md](NEXT_STEPS.md)** - What to build next

---

## 🐛 Troubleshooting

### Port 5432 already in use?
Your local PostgreSQL is running (good!). The override file will use it.

### Services won't start?
```bash
make clean
make rebuild
```

### Can't connect to database?
```bash
# Verify database exists
psql -U pushkar -l | grep blnk

# Create if missing
createdb -U pushkar blnk
```

---

## ✅ You're All Set!

You now have a fully functional HRS microservice running in Docker! 🎉

**Services running:**
- HRS (Handle Resolution) → http://localhost:8001
- Blnk Ledger → http://localhost:5001
- Redis, PostgreSQL, Typesense

**Next:** Build more services or start on mobile apps!
