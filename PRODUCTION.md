# Production Deployment Guide

## Prerequisites

- Docker and Docker Compose installed on your production server
- Domain `api.fscompanion.com` pointed to your server
- SSL certificate (handled by your external nginx setup)

## Required Production Keys and Secrets

Yes, you need to set up the following production keys:

### 1. SECRET_KEY_BASE
Rails requires this to encrypt session data and verify signed cookies.

**Generate it:**
```bash
docker-compose -f docker-compose.production.yml run --rm web bundle exec rails secret
```

### 2. API_KEY
Your API uses this to authenticate iOS app requests.

**Generate it:**
```bash
docker-compose -f docker-compose.production.yml run --rm web bundle exec ruby -e "require 'securerandom'; puts SecureRandom.hex(32)"
```

### 3. DATABASE_PASSWORD
Secure password for PostgreSQL database.

**Generate it:**
```bash
openssl rand -base64 32
```

## Setup Instructions

### 1. Create Production Environment File

```bash
# Copy the example file
cp .env.production.example .env.production

# Edit with your actual values
nano .env.production
```

Fill in the generated values:
- `SECRET_KEY_BASE` - from step 1 above
- `API_KEY` - from step 2 above
- `DATABASE_PASSWORD` - from step 3 above

**IMPORTANT:** Add `.env.production` to `.gitignore` if not already there!

### 2. Update .gitignore

Ensure your `.gitignore` includes:
```
.env*
!.env.production.example
```

### 3. Build Production Image

```bash
docker-compose -f docker-compose.production.yml build
```

### 4. Start Production Services

```bash
# Start in detached mode
docker-compose -f docker-compose.production.yml up -d

# Check logs
docker-compose -f docker-compose.production.yml logs -f web
```

The application will:
- Automatically run database migrations
- Start the Puma web server on port 3000
- Be accessible at `http://localhost:3000`

### 5. Import Airport Data (First Time Only)

```bash
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:seed
# or if you have a custom import task:
docker-compose -f docker-compose.production.yml exec web bundle exec rake import:airports
```

## Production Management

### View Logs
```bash
# All logs
docker-compose -f docker-compose.production.yml logs -f

# Web server only
docker-compose -f docker-compose.production.yml logs -f web

# Database only
docker-compose -f docker-compose.production.yml logs -f db
```

### Restart Services
```bash
# Restart web server only
docker-compose -f docker-compose.production.yml restart web

# Restart all services
docker-compose -f docker-compose.production.yml restart
```

### Stop Services
```bash
docker-compose -f docker-compose.production.yml down

# Stop and remove volumes (CAUTION: This deletes the database!)
docker-compose -f docker-compose.production.yml down -v
```

### Run Migrations
```bash
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate
```

### Access Rails Console
```bash
docker-compose -f docker-compose.production.yml exec web bundle exec rails console
```

### Database Backup
```bash
# Create backup
docker-compose -f docker-compose.production.yml exec db pg_dump -U postgres fscompanion_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker-compose -f docker-compose.production.yml exec -T db psql -U postgres fscompanion_production < backup_20231214_120000.sql
```

## Nginx Configuration (External)

Since nginx is configured elsewhere, ensure it proxies to `localhost:3000`:

```nginx
upstream fscompanion_api {
  server localhost:3000;
}

server {
  listen 443 ssl http2;
  server_name api.fscompanion.com;

  # SSL configuration (handled externally)
  
  location / {
    proxy_pass http://fscompanion_api;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

## Security Checklist

- [x] SECRET_KEY_BASE set to secure random value
- [x] API_KEY set to secure random value
- [x] Database password is strong and unique
- [x] `.env.production` added to `.gitignore`
- [x] SSL enabled (force_ssl = true in production.rb)
- [x] Host header protection enabled for api.fscompanion.com
- [ ] Firewall configured to only allow ports 80, 443, and 22
- [ ] Regular database backups scheduled
- [ ] Monitoring and alerting set up

## Updating the Application

```bash
# Pull latest code
git pull origin main

# Rebuild image
docker-compose -f docker-compose.production.yml build

# Restart with new image
docker-compose -f docker-compose.production.yml up -d

# Run migrations if needed
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate
```

## Health Checks

The application includes built-in health checks:
- HTTP: `http://localhost:3000/api/v1/airports`
- Docker healthcheck runs every 30 seconds

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose -f docker-compose.production.yml logs web

# Common issues:
# - Missing SECRET_KEY_BASE in .env.production
# - Database not ready (wait 30s and try again)
# - Port 3000 already in use
```

### Database connection errors
```bash
# Verify database is running
docker-compose -f docker-compose.production.yml ps db

# Check database logs
docker-compose -f docker-compose.production.yml logs db
```

### Permission issues
```bash
# Fix log and tmp permissions
sudo chown -R 1000:1000 log tmp
```

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| SECRET_KEY_BASE | Yes | Rails secret for encryption (min 128 chars) |
| API_KEY | Yes | API authentication key |
| DATABASE_USER | Yes | PostgreSQL username |
| DATABASE_PASSWORD | Yes | PostgreSQL password |
| DATABASE_HOST | Yes | Database host (use 'db' for docker-compose) |
| RAILS_ENV | Yes | Set to 'production' |
| RAILS_LOG_LEVEL | No | Log level (default: info) |
| RAILS_MAX_THREADS | No | Max Puma threads (default: 5) |
| RAILS_MASTER_KEY | No | Only if using encrypted credentials |
