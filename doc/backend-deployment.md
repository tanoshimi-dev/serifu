# Backend Deployment Guide

## Directory Structure

```
sys/backend/
├── app/                      # Application source code
│   └── Dockerfile
├── nginx/
│   ├── Dockerfile            # Nginx container config
│   └── nginx.conf            # Reverse proxy settings
├── docker-compose.dev.yml    # Development environment
├── docker-compose.prod.yml   # Production environment
└── .env.example              # Environment variables template
```

## Environment Comparison

| Feature | Development | Production |
|---------|-------------|------------|
| Adminer (DB Admin) | Yes (port 5050) | No |
| Nginx Reverse Proxy | No | Yes (port 80) |
| GIN_MODE | debug | release |
| Database Credentials | Hardcoded | From .env file |
| PostgreSQL Port Exposed | Yes (5432) | No (internal only) |
| Container Names | `serifu_*_dev` | `serifu_*` |

## Development Environment

### Start Services

```bash
cd sys/backend
docker-compose -f docker-compose.dev.yml up -d
```

### Access Points

- **Backend API**: http://localhost:8080
- **Adminer (DB Admin)**: http://localhost:5050
  - System: PostgreSQL
  - Server: postgres
  - Username: serifu
  - Password: serifu_password
  - Database: serifu_db

### Stop Services

```bash
docker-compose -f docker-compose.dev.yml down
```

## Production Environment (VPS)

### Prerequisites

1. Docker and Docker Compose installed on VPS
2. Domain configured (optional, for SSL)

### Setup Steps

1. **Clone repository to VPS**

```bash
git clone <repository-url>
cd serifu/sys/backend
```

2. **Create environment file**

```bash
cp .env.example .env
```

3. **Edit .env with secure values**

```bash
nano .env
```

```env
DB_USER=serifu
DB_PASSWORD=<strong-random-password>
DB_NAME=serifu_db
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=100
```

4. **Build and start containers**

```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

5. **Verify services**

```bash
docker-compose -f docker-compose.prod.yml ps
```

### Access Points

- **API via Nginx**: http://<vps-ip>/api/
- **Health Check**: http://<vps-ip>/health

### View Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f nginx
docker-compose -f docker-compose.prod.yml logs -f postgres
```

### Stop Services

```bash
docker-compose -f docker-compose.prod.yml down
```

### Update Deployment

```bash
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

## Nginx Configuration

The production environment includes Nginx reverse proxy with:

- **Rate Limiting**: 10 requests/second per IP (burst 20)
- **Gzip Compression**: Enabled for text, JSON, and other compressible types
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Health Check Endpoint**: `/health` (no access logging)

## Database Management

### Development

Use Adminer at http://localhost:5050

### Production

Connect via Docker exec:

```bash
docker exec -it serifu_postgres psql -U serifu -d serifu_db
```

### Backup Database

```bash
docker exec serifu_postgres pg_dump -U serifu serifu_db > backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
cat backup.sql | docker exec -i serifu_postgres psql -U serifu -d serifu_db
```

## Seed Data

Sample data is available for development and testing.

### Load Sample Data

```bash
# Development
docker exec -i serifu_postgres_dev psql -U serifu -d serifu_db < app/seeds/seed_data.sql

# Production (if needed for demo)
docker exec -i serifu_postgres psql -U ${DB_USER} -d ${DB_NAME} < app/seeds/seed_data.sql
```

### Sample Data Contents

| Table | Count | Description |
|-------|-------|-------------|
| Categories | 8 | Daily Life, Work, Love, Friends, Family, Humor, Philosophy, Motivation |
| Users | 8 | Sample users with avatars and bios |
| Quizzes | 14 | Various quiz prompts across categories |
| Answers | 21 | Witty responses to quizzes |
| Comments | 10 | Sample comments on answers |
| Likes | 17 | Sample likes |
| Follows | 10 | Sample follow relationships |

### Clear Sample Data

```bash
docker exec -i serifu_postgres_dev psql -U serifu -d serifu_db -c "
TRUNCATE follows, likes, comments, answers, quizzes, categories, users CASCADE;
"
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs <service-name>

# Rebuild without cache
docker-compose -f docker-compose.prod.yml build --no-cache
```

### Database connection issues

```bash
# Check if postgres is healthy
docker-compose -f docker-compose.prod.yml ps

# Test connection from backend container
docker exec serifu_backend wget -qO- http://localhost:8080/health
```

### Reset everything

```bash
docker-compose -f docker-compose.prod.yml down -v
docker-compose -f docker-compose.prod.yml up -d --build
```

Note: `-v` removes volumes including database data.
