# FuelPrice API VPS Deployment Guide

This guide provides step-by-step instructions for deploying the FuelPrice API to a VPS server using Docker and SSL.

## Prerequisites

- VPS server with root/admin access
- Docker and Docker Compose installed
- Domain name (maxdemon.site) pointing to your VPS
- SSL certificate in `/extra/ssl_cert` directory

## Deployment Steps

### 1. Server Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Create fuelprice user for security
sudo useradd -m -s /bin/bash fuelprice
sudo usermod -aG docker fuelprice

# Create deployment directory
sudo mkdir -p /opt/fuelprice-api
sudo chown fuelprice:fuelprice /opt/fuelprice-api/
```

### 2. Transfer Application Files

```bash
# Switch to fuelprice user
sudo su - fuelprice

# Clone your repository (adjust path as needed)
git clone https://github.com/itsmaxyd/fillup.git /opt/fuelprice-api
cd /opt/fuelprice-api/fuelprice_api
```

### 3. Create SSL Directory and Copy Certificates

```bash
# Create SSL directory on server
sudo mkdir -p /opt/ssl

# Copy SSL certificate files to /opt/ssl/
# Assuming your certificates are in /extra/ssl_cert
sudo cp /extra/ssl_cert/maxdemon.site.crt /opt/ssl/
sudo cp /extra/ssl_cert/maxdemon.site.key /opt/ssl/

# Set proper permissions
sudo chown root:root /opt/ssl/*
sudo chmod 600 /opt/ssl/maxdemon.site.key
sudo chmod 644 /opt/ssl/maxdemon.site.crt
```

### 4. Create Nginx Configuration for Reverse Proxy

Install Nginx if not already installed:
```bash
sudo apt install nginx -y
```

Create SSL configuration:
```bash
sudo tee /etc/nginx/sites-available/fuelprice-api << 'EOF'
server {
    listen 80;
    server_name maxdemon.site;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name maxdemon.site;

    # SSL Configuration
    ssl_certificate /opt/ssl/maxdemon.site.crt;
    ssl_certificate_key /opt/ssl/maxdemon.site.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to fuelprice API
    location / {
        proxy_pass http://localhost:8443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300;
    }
}
EOF
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/fuelprice-api /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Configure Firewall

```bash
# Allow SSH, HTTP, HTTPS, and custom port 8443 (for direct access if needed)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8443/tcp
sudo ufw --force enable
```

### 6. Deploy the Application

```bash
# Switch to fuelprice user and navigate to application directory
sudo su - fuelprice
cd /opt/fuelprice-api/fuelprice_api

# Create data directory for persistent storage
mkdir -p ./data

# Build and start the application
docker-compose up -d --build
```

### 7. Test the Deployment

```bash
# Test internal API endpoint (should work)
curl http://localhost:8443/

# Test external endpoint via HTTPS (should work)
curl -k https://maxdemon.site/

# Test fuel price endpoint
curl -k "https://maxdemon.site/live_fuel_price/?fuel_type=petrol&location_type=city"

# Check container logs
docker-compose logs -f
```

## File Structure After Deployment

```
/opt/fuelprice-api/
├── fuelprice_api/
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   └── ... (other application files)
├── data/                           # Persistent database
│   └── fuel_prices.db             # SQLite database

/opt/ssl/
├── maxdemon.site.crt              # SSL certificate
└── maxdemon.site.key              # SSL private key

/etc/nginx/sites-enabled/
└── fuelprice-api                  # Nginx configuration
```

## API Endpoints

Once deployed, your API will be available at:
- **HTTPS (Recommended)**: https://maxdemon.site/
- **HTTP (Internal/Testing)**: http://localhost:8443/

### Key Endpoints:
- `GET /` - API information
- `GET /live_fuel_price/?fuel_type=petrol&location_type=city` - Live fuel prices
- `GET /historical_fuel_price/?fuel_type=petrol&location_type=city&location=Delhi&n=2` - Historical prices
- `GET /cities/` - List of cities
- `GET /states/` - List of states

## Maintenance Commands

```bash
# Check application status
docker-compose ps

# View logs
docker-compose logs -f

# Restart application
docker-compose restart

# Update application
cd /opt/fuelprice-api/fuelprice_api
git pull
docker-compose up -d --build

# Stop application
docker-compose down
```

## Troubleshooting

### Common Issues

1. **Port 8443 already in use**:
   ```bash
   sudo netstat -tlnp | grep 8443
   sudo fuser -k 8443/tcp
   ```

2. **SSL certificate issues**:
   - Check certificate paths in nginx config
   - Verify certificate validity with: `openssl x509 -in /opt/ssl/maxdemon.site.crt -text -noout`

3. **Database connection issues**:
   ```bash
   # Check data directory permissions
   ls -la /opt/fuelprice-api/data/

   # Manually execute database init
   docker-compose exec fuelprice-api python -c "from database import init_db; init_db()"
   ```

4. **Nginx configuration errors**:
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   sudo systemctl reload nginx
   ```

### Logs and Monitoring

```bash
# API application logs
docker-compose logs fuelprice-api

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u docker -f
```

## Security Notes

- API runs without authentication as requested
- SSL/TLS encryption is enforced via Nginx
- Container runs with non-root user internally
- Database is persistent but not automatically backed up
- Firewall allows only necessary ports
- File permissions are restricted

## Backup (Optional)

If you later decide to implement backups:

```bash
# Database backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
sqlite3 /opt/fuelprice-api/data/fuel_prices.db ".backup /opt/fuelprice-api/backups/fuel_prices_$DATE.db"

# Add to cron for daily backups
# crontab -e
# 0 2 * * * /path/to/backup-script.sh
```

This concludes the deployment guide. The API should now be accessible at `https://maxdemon.site/` and ready to serve fuel price data to your Flutter application.
