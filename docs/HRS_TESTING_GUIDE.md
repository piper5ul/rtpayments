# Handle Resolution Service (HRS) Testing Guide

## Service Overview
- **Service Name:** Handle Resolution Service (HRS)
- **Port:** 8001
- **Purpose:** Sub-10ms SLA for @handle resolution (e.g., @alice → user_id + account_id)
- **Technology:** Go, PostgreSQL, Redis (cache)
- **Architecture:** Cache-first with database fallback

## Available Endpoints

### 1. Health Check
```bash
curl http://localhost:8001/health
```

**Expected Response:**
```json
{
  "service": "handle-resolution-service",
  "status": "healthy"
}
```

---

### 2. Create Handle
**Endpoint:** `POST /handles`

**Request:**
```bash
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{
    "handle": "alice",
    "user_id": "user_123",
    "account_id": "acct_456"
  }'
```

**Expected Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "handle": "alice",
  "user_id": "user_123",
  "account_id": "acct_456",
  "is_active": true,
  "created_at": "2025-12-30T12:00:00Z",
  "updated_at": "2025-12-30T12:00:00Z"
}
```

**Error Cases:**
```bash
# Missing fields
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{}'

# Expected: 400 Bad Request
```

---

### 3. Resolve Handle
**Endpoint:** `GET /handles/resolve?handle={handle}`

**Request:**
```bash
curl "http://localhost:8001/handles/resolve?handle=alice"
```

**Expected Response (200 OK):**
```json
{
  "handle": "alice",
  "user_id": "user_123",
  "account_id": "acct_456",
  "is_active": true,
  "resolved_at": "2025-12-30T12:00:01Z"
}
```

**Response Headers:**
- `X-Response-Time` - Shows actual resolution time (should be <10ms for cached handles)
- `Content-Type: application/json`

**Error Cases:**
```bash
# Missing handle parameter
curl "http://localhost:8001/handles/resolve"
# Expected: 400 Bad Request

# Non-existent handle
curl "http://localhost:8001/handles/resolve?handle=nonexistent"
# Expected: 404 Not Found
```

---

## Complete Testing Flow

### Step 1: Verify Service is Running
```bash
# Check health
curl http://localhost:8001/health

# Check Docker container status
docker ps | grep titan-hrs

# View service logs
docker logs titan-hrs --tail 50 -f
```

### Step 2: Create Test Handles
```bash
# Create handle for Alice
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{
    "handle": "alice",
    "user_id": "user_alice_001",
    "account_id": "acct_alice_main"
  }'

# Create handle for Bob
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{
    "handle": "bob",
    "user_id": "user_bob_002",
    "account_id": "acct_bob_main"
  }'

# Create handle for Charlie
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{
    "handle": "charlie",
    "user_id": "user_charlie_003",
    "account_id": "acct_charlie_main"
  }'
```

### Step 3: Test Handle Resolution
```bash
# Resolve Alice's handle (first time - will hit database)
curl -v "http://localhost:8001/handles/resolve?handle=alice" 2>&1 | grep "X-Response-Time"

# Resolve Alice's handle again (cached - should be faster)
curl -v "http://localhost:8001/handles/resolve?handle=alice" 2>&1 | grep "X-Response-Time"

# Resolve Bob's handle
curl "http://localhost:8001/handles/resolve?handle=bob"

# Resolve Charlie's handle
curl "http://localhost:8001/handles/resolve?handle=charlie"
```

### Step 4: Test Cache Performance
```bash
# Measure cache hit performance
for i in {1..10}; do
  curl -s -w "\nResponse Time: %{time_total}s\n" \
    "http://localhost:8001/handles/resolve?handle=alice"
done
```

Expected result: Response times should be consistently under 10ms for cached handles.

### Step 5: Test Error Handling
```bash
# Test missing parameter
curl -v "http://localhost:8001/handles/resolve" 2>&1 | grep "< HTTP"

# Test non-existent handle
curl -v "http://localhost:8001/handles/resolve?handle=doesnotexist" 2>&1 | grep "< HTTP"

# Test invalid JSON for create
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d 'invalid json'
```

---

## Performance Testing

### Sub-10ms SLA Verification
```bash
# Use curl's timing to verify sub-10ms performance
curl -w "@-" -o /dev/null -s "http://localhost:8001/handles/resolve?handle=alice" <<'EOF'
    time_namelookup:  %{time_namelookup}s\n
       time_connect:  %{time_connect}s\n
    time_appconnect:  %{time_appconnect}s\n
   time_pretransfer:  %{time_pretransfer}s\n
      time_redirect:  %{time_redirect}s\n
 time_starttransfer:  %{time_starttransfer}s\n
                    ----------\n
         time_total:  %{time_total}s\n
EOF
```

### Load Testing with Apache Bench
```bash
# Install Apache Bench (if not installed)
# macOS: brew install httpd
# Linux: apt-get install apache2-utils

# Run load test - 1000 requests, 10 concurrent
ab -n 1000 -c 10 "http://localhost:8001/handles/resolve?handle=alice"
```

Expected results:
- Mean response time: <10ms
- 99th percentile: <20ms
- No failed requests

---

## Database Verification

### Check PostgreSQL Data
```bash
# Connect to PostgreSQL
docker exec -it titan-postgres psql -U blnk -d blnk

# Inside PostgreSQL prompt:
# View handles table
SELECT * FROM handles;

# Check specific handle
SELECT * FROM handles WHERE handle = 'alice';

# Count total handles
SELECT COUNT(*) FROM handles;

# Exit PostgreSQL
\q
```

---

## Redis Cache Verification

### Check Redis Cache
```bash
# Connect to Redis
docker exec -it titan-redis redis-cli

# Inside Redis prompt:
# List all keys
KEYS *

# Get cached handle (key format: handle:alice)
GET handle:alice

# Check TTL on cached handle
TTL handle:alice

# Clear cache for testing
FLUSHDB

# Exit Redis
exit
```

---

## Integration Testing

### Test HRS with Payment Router
The Payment Router (port 8002) depends on HRS for handle resolution during payment processing.

```bash
# Check Payment Router's connection to HRS
docker logs titan-payment-router | grep -i "hrs"

# Test payment router health (which checks HRS)
curl http://localhost:8002/health
```

---

## Troubleshooting

### Service Not Responding
```bash
# Check if service is running
docker ps | grep titan-hrs

# View service logs
docker logs titan-hrs

# Restart service
docker-compose restart hrs

# Rebuild if needed
docker-compose build hrs
docker-compose up -d hrs
```

### Database Connection Issues
```bash
# Check PostgreSQL is running
docker ps | grep titan-postgres

# Check PostgreSQL logs
docker logs titan-postgres

# Test PostgreSQL connection from HRS container
docker exec titan-hrs sh -c "wget --spider http://postgres:5432" 2>&1
```

### Cache Not Working
```bash
# Check Redis is running
docker ps | grep titan-redis

# Check Redis logs
docker logs titan-redis

# Verify Redis connection
docker exec titan-redis redis-cli ping
# Expected: PONG
```

### Performance Issues
```bash
# Check service resource usage
docker stats titan-hrs

# View detailed logs with timing
docker logs titan-hrs -f | grep -E "Cache|Resolved"

# Check database query performance
docker exec -it titan-postgres psql -U blnk -d blnk -c "EXPLAIN ANALYZE SELECT * FROM handles WHERE handle = 'alice';"
```

---

## Automated Test Script

Save this as `test-hrs.sh`:
```bash
#!/bin/bash

echo "=== HRS Service Test ==="
echo ""

# Test 1: Health Check
echo "1. Testing health endpoint..."
HEALTH=$(curl -s http://localhost:8001/health | jq -r '.status')
if [ "$HEALTH" = "healthy" ]; then
  echo "✅ Health check passed"
else
  echo "❌ Health check failed"
  exit 1
fi
echo ""

# Test 2: Create Handle
echo "2. Creating test handle..."
CREATE_RESULT=$(curl -s -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{"handle":"testuser","user_id":"test_001","account_id":"acct_test_001"}')
HANDLE_ID=$(echo $CREATE_RESULT | jq -r '.id')
if [ ! -z "$HANDLE_ID" ] && [ "$HANDLE_ID" != "null" ]; then
  echo "✅ Handle created: $HANDLE_ID"
else
  echo "❌ Failed to create handle"
  exit 1
fi
echo ""

# Test 3: Resolve Handle
echo "3. Resolving handle..."
RESOLVE_RESULT=$(curl -s "http://localhost:8001/handles/resolve?handle=testuser")
USER_ID=$(echo $RESOLVE_RESULT | jq -r '.user_id')
if [ "$USER_ID" = "test_001" ]; then
  echo "✅ Handle resolved correctly"
else
  echo "❌ Handle resolution failed"
  exit 1
fi
echo ""

# Test 4: Performance Test (cache hit)
echo "4. Testing cache performance (10 requests)..."
TOTAL_TIME=0
for i in {1..10}; do
  TIME=$(curl -s -w "%{time_total}" -o /dev/null "http://localhost:8001/handles/resolve?handle=testuser")
  echo "  Request $i: ${TIME}s"
  TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME" | bc)
done
AVG_TIME=$(echo "scale=6; $TOTAL_TIME / 10" | bc)
echo "Average response time: ${AVG_TIME}s"
if (( $(echo "$AVG_TIME < 0.010" | bc -l) )); then
  echo "✅ Performance target met (<10ms)"
else
  echo "⚠️  Performance target not met (avg: ${AVG_TIME}s)"
fi
echo ""

# Test 5: Error Handling
echo "5. Testing error handling..."
ERROR_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8001/handles/resolve?handle=nonexistent")
if [ "$ERROR_CODE" = "404" ]; then
  echo "✅ 404 error handling works"
else
  echo "❌ Error handling failed (got $ERROR_CODE instead of 404)"
fi
echo ""

echo "=== All Tests Complete ==="
```

Run with:
```bash
chmod +x test-hrs.sh
./test-hrs.sh
```

---

## Expected Performance Benchmarks

| Metric | Target | Acceptable |
|--------|--------|------------|
| Cache Hit Response Time | <5ms | <10ms |
| Cache Miss Response Time | <50ms | <100ms |
| Throughput (cached) | >1000 req/s | >500 req/s |
| Availability | 99.9% | 99% |
| Cache Hit Ratio | >90% | >80% |

---

## Next Steps

After testing HRS, you can:
1. Test the Payment Router service (port 8002) which depends on HRS
2. Test end-to-end payment flows using @handles
3. Set up monitoring and alerting for sub-10ms SLA compliance
4. Load test with realistic traffic patterns
