# 🚀 Vakıf Dashboard - Self-Hosting Deployment Guide

Complete production deployment guide for self-hosting Vakıf Dashboard on your own server.

## 📋 Prerequisites

### System Requirements
- **Docker**: Version 20.10+ 
- **Docker Compose**: Version 2.0+
- **RAM**: Minimum 2GB, Recommended 4GB+
- **Storage**: Minimum 10GB free space
- **CPU**: 2+ cores recommended
- **OS**: Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+)

### Port Requirements
- **8082**: Main application (HTTP)
- **80**: Nginx HTTP (optional)
- **443**: Nginx HTTPS (optional)

## 🏁 Quick Start (5 Minutes)

```bash
# 1. Clone or upload the project
cd vakif-dashboard

# 2. Initialize everything
make init-all

# 3. Deploy to production
make deploy-prod

# 4. Access your dashboard
open http://localhost:8082
```

## 📖 Detailed Deployment Steps

### Step 1: Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Application Setup

```bash
# Create application directory
mkdir -p /opt/vakif-dashboard
cd /opt/vakif-dashboard

# Upload your application files or clone from git
# Copy all files from vakif-dashboard/ directory

# Set proper permissions
sudo chown -R $USER:$USER /opt/vakif-dashboard
chmod +x scripts/*.js
```

### Step 3: Environment Configuration

```bash
# Copy and edit production environment
cp production.env production.local.env

# Edit configuration for your setup
nano production.local.env
```

**Important Environment Variables to Change:**
```env
# Change to your domain/IP
NEXT_PUBLIC_APP_URL=https://yourdomain.com

# Generate a random secret
SESSION_SECRET=your-unique-secret-key-here

# Set your timezone
TZ=Europe/Istanbul
```

### Step 4: SSL Setup (Recommended)

#### Option A: Self-Signed Certificates (Quick Setup)
```bash
make setup-ssl
```

#### Option B: Let's Encrypt (Production)
```bash
# Install certbot
sudo apt install certbot -y

# Generate certificates
sudo certbot certonly --standalone -d yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./nginx/ssl/key.pem
sudo chown $USER:$USER ./nginx/ssl/*
```

### Step 5: Production Deployment

```bash
# Full deployment with SSL
make deploy-prod-ssl

# OR basic deployment without SSL
make deploy-prod
```

### Step 6: Verification

```bash
# Check service status
make status

# Health check
make health-check

# View logs
make logs

# Monitor services
make monitor
```

## 🔧 Advanced Configuration

### Custom Domain Setup

1. **DNS Configuration**:
   ```
   A Record: yourdomain.com → YOUR_SERVER_IP
   ```

2. **Update Environment**:
   ```env
   NEXT_PUBLIC_APP_URL=https://yourdomain.com
   ```

3. **Nginx Configuration** (edit `nginx/nginx.conf`):
   ```nginx
   server_name yourdomain.com;
   ```

### Firewall Configuration

```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable

# Or specific port only
sudo ufw allow 8082/tcp  # Direct app access
```

### Backup Configuration

```bash
# Create daily backup cron job
crontab -e

# Add this line for daily backups at 2 AM
0 2 * * * cd /opt/vakif-dashboard && make backup-all

# Manual backup
make backup-all
```

## 📊 Monitoring & Maintenance

### Log Management

```bash
# View application logs
make logs-app

# View nginx logs
make logs-nginx

# Follow live logs
make monitor
```

### Performance Monitoring

```bash
# System resource usage
docker stats

# Application health
make health-check

# Container status
make status
```

### Updates & Maintenance

```bash
# Update and restart services
make update

# Clean restart with latest code
make clean-all && make deploy-prod

# Optimize system
make optimize
```

## 🔐 Security Best Practices

### 1. Change Default Secrets
```bash
# Generate random secrets
openssl rand -base64 32  # For SESSION_SECRET
```

### 2. Regular Updates
```bash
# Weekly update routine
make update
```

### 3. Backup Strategy
```bash
# Automated backups
make backup-all

# Test restore procedure
make db-restore FILE=backups/vakif-20241201-140000.db
```

### 4. Access Control
- Use reverse proxy (nginx) for SSL termination
- Configure fail2ban for brute force protection
- Use strong passwords for server access
- Enable automatic security updates

## 🐛 Troubleshooting

### Common Issues

#### 1. Container Won't Start
```bash
# Check logs
make logs

# Check system resources
docker system df
free -h

# Restart services
make restart-all
```

#### 2. Database Issues
```bash
# Check database file permissions
ls -la vakif.db*

# Restore from backup
make db-restore FILE=backups/your-backup.db
```

#### 3. PDF Processing Fails
```bash
# Check if poppler-utils is installed in container
make shell
which pdftotext

# Restart with debug logs
make debug
```

#### 4. SSL Certificate Issues
```bash
# Regenerate self-signed certificates
rm -rf nginx/ssl/*
make setup-ssl

# Check certificate validity
openssl x509 -in nginx/ssl/cert.pem -text -noout
```

### Performance Issues

#### 1. High Memory Usage
```bash
# Monitor container memory
docker stats

# Restart services
make restart-all
```

#### 2. Slow Response Times
```bash
# Check nginx logs
make logs-nginx

# Optimize Docker
make optimize
```

## 📈 Scaling & Performance

### Horizontal Scaling
For high-traffic environments:

1. **Load Balancer Setup**:
   ```yaml
   # In docker-compose.yml
   deploy:
     replicas: 3
   ```

2. **Database Optimization**:
   - Consider PostgreSQL for high concurrent access
   - Implement connection pooling

3. **CDN Integration**:
   - Use CloudFlare or similar for static assets
   - Enable caching for public resources

### Monitoring Integration

#### Prometheus + Grafana Setup
```bash
# Add monitoring stack (optional)
git clone https://github.com/prometheus/prometheus
# Configure monitoring for your application
```

## 📞 Support & Maintenance

### Health Checks
- Application: `http://yourserver:8082/api/data`
- Nginx: `http://yourserver/health`

### Log Locations
- Application: `./logs/app.log`
- Nginx: `./logs/nginx/`
- Docker: `docker compose logs`

### Backup Locations
- Database: `./backups/`
- Full backups: `./backups/full-backup-*/`

## 🎯 Production Checklist

- [ ] ✅ Environment variables configured
- [ ] 🔐 SSL certificates installed
- [ ] 🔥 Firewall configured
- [ ] 💾 Backup strategy implemented
- [ ] 📊 Monitoring setup
- [ ] 🔄 Auto-restart configured
- [ ] 🧪 Health checks working
- [ ] 📝 Logs rotating properly
- [ ] 🔐 Security headers enabled
- [ ] 🌐 Domain/DNS configured

---

## 🚀 Quick Commands Reference

```bash
# Deployment
make init-all           # First time setup
make deploy-prod        # Production deployment
make deploy-prod-ssl    # With SSL

# Management
make up-all            # Start all services
make down-all          # Stop all services
make restart-all       # Restart everything
make rebuild-all       # Rebuild and restart

# Monitoring
make status            # Service status
make health-check      # Health verification
make monitor           # Live monitoring
make logs             # View logs

# Maintenance
make backup-all        # Create backup
make clean-all         # Clean everything
make update           # Update services
make optimize         # System optimization
```

**🎉 Your Vakıf Dashboard is now ready for production use!** 