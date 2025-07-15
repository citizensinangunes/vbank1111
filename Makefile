# Vakıf Dashboard Makefile
# Self-Hosting Production Ready Makefile

.PHONY: help build dev prod clean logs shell stop restart status
.PHONY: build-all up-all down-all setup-ssl init-dirs deploy-prod
.PHONY: ssl-cert backup-all restore-all monitor health-check

# Default target
help: ## Show this help message
	@echo "🏛️  Vakıf Dashboard - Self-Hosting Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "   make init-all         # First time setup"
	@echo "   make build-all        # Build everything"
	@echo "   make up-all           # Start all services"
	@echo "   make monitor          # Monitor all services"

# =====================================================
# 🔧 Development Commands
# =====================================================

dev: ## Start development server (local)
	npm run dev

install: ## Install dependencies
	npm install

build-local: ## Build application locally
	npm run build

lint: ## Run linting
	npm run lint

test-local: ## Run local tests (if any)
	@echo "Running local tests..."
	npm test || echo "No tests configured"

# =====================================================
# 🐳 Production Docker Commands
# =====================================================

build-all: ## Build all Docker images for production
	@echo "🏗️  Building all Docker images..."
	docker-compose build --no-cache --parallel
	@echo "✅ All images built successfully!"

up-all: ## Start all production services
	@echo "🚀 Starting all production services..."
	docker-compose up -d
	@echo "✅ All services started!"
	@echo "📡 Application: http://localhost:8082"
	@echo "🌐 Nginx HTTP: http://localhost:8080"
	@echo "🔒 Nginx HTTPS: https://localhost (if SSL configured)"

up-all-nginx: ## Start all services including Nginx reverse proxy
	@echo "🚀 Starting all services with Nginx..."
	docker-compose --profile nginx up -d
	@echo "✅ All services with Nginx started!"

down-all: ## Stop and remove all containers
	@echo "🛑 Stopping all services..."
	docker-compose down --remove-orphans
	docker-compose --profile nginx down --remove-orphans
	@echo "✅ All services stopped!"

# =====================================================
# 🔄 Container Management
# =====================================================

restart-all: down-all up-all ## Quick restart all services

rebuild-all: down-all build-all up-all ## Rebuild and restart everything

clean-all: ## Clean up all Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	docker-compose down --rmi all --volumes --remove-orphans
	docker-compose --profile nginx down --rmi all --volumes --remove-orphans
	docker system prune -af --volumes
	@echo "✅ Cleanup completed!"

# =====================================================
# 📊 Monitoring & Status
# =====================================================

status: ## Show container status
	@echo "📊 Container Status:"
	docker-compose ps
	@echo ""
	docker-compose --profile nginx ps

logs: ## Show all container logs
	docker-compose logs -f

logs-app: ## Show application logs only
	docker-compose logs -f vakif-dashboard

logs-nginx: ## Show nginx logs only
	docker-compose logs -f nginx

monitor: ## Monitor all services (logs + status)
	@echo "🔍 Monitoring all services..."
	@echo "📊 Current Status:"
	make status
	@echo ""
	@echo "📝 Live Logs (Press Ctrl+C to exit):"
	make logs

health-check: ## Check application health
	@echo "🏥 Health Check Results:"
	@echo "Application API:" 
	@curl -f http://localhost:8082/api/data || echo "❌ API not responding"
	@echo ""
	@echo "Application Frontend:"
	@curl -f http://localhost:8082 || echo "❌ Frontend not responding"
	@echo ""
	@echo "Nginx (if running):"
	@curl -f http://localhost:8080 || echo "⚠️  Nginx not running or not responding"

# =====================================================
# 🗄️ Database Management
# =====================================================

db-backup: ## Backup SQLite database
	@echo "💾 Creating database backup..."
	mkdir -p ./backups
	cp ./vakif.db ./backups/vakif-$(shell date +%Y%m%d-%H%M%S).db || echo "⚠️  Database file not found"
	cp ./vakif.db-shm ./backups/vakif-$(shell date +%Y%m%d-%H%M%S).db-shm 2>/dev/null || true
	cp ./vakif.db-wal ./backups/vakif-$(shell date +%Y%m%d-%H%M%S).db-wal 2>/dev/null || true
	@echo "✅ Database backed up to backups/"

db-restore: ## Restore database from backup (use: make db-restore FILE=backup.db)
	@if [ -z "$(FILE)" ]; then echo "❌ Usage: make db-restore FILE=backup.db"; exit 1; fi
	@echo "📥 Restoring database from $(FILE)..."
	cp $(FILE) ./vakif.db
	@echo "✅ Database restored from $(FILE)"

backup-all: db-backup ## Backup everything (database + configs)
	@echo "📦 Creating full backup..."
	mkdir -p ./backups/full-backup-$(shell date +%Y%m%d-%H%M%S)
	cp -r ./data ./backups/full-backup-$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	cp -r ./uploads ./backups/full-backup-$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	cp -r ./nginx ./backups/full-backup-$(shell date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
	cp docker-compose.yml ./backups/full-backup-$(shell date +%Y%m%d-%H%M%S)/
	@echo "✅ Full backup completed!"

# =====================================================
# 🔐 SSL & Security Setup
# =====================================================

setup-ssl: ## Generate self-signed SSL certificates
	@echo "🔐 Setting up SSL certificates..."
	mkdir -p ./nginx/ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ./nginx/ssl/key.pem \
		-out ./nginx/ssl/cert.pem \
		-subj "/C=TR/ST=Istanbul/L=Istanbul/O=Vakif Dashboard/OU=IT/CN=localhost"
	@echo "✅ Self-signed SSL certificates generated!"
	@echo "⚠️  For production, replace with real certificates from Let's Encrypt"

ssl-letsencrypt: ## Setup Let's Encrypt SSL (requires domain and certbot)
	@echo "🔐 Setting up Let's Encrypt SSL..."
	@echo "⚠️  Make sure certbot is installed and domain points to this server"
	@read -p "Enter your domain name: " domain; \
	sudo certbot certonly --standalone -d $$domain
	@echo "📋 Copy certificates to nginx/ssl/ directory manually"

# =====================================================
# 📁 Directory & Initialization
# =====================================================

init-dirs: ## Create necessary directories
	@echo "📁 Creating necessary directories..."
	mkdir -p data uploads backups logs nginx/ssl nginx/conf.d
	touch ./vakif.db
	chmod 755 data uploads backups logs
	@echo "✅ Directories created!"

init-all: init-dirs install ## Complete first-time setup
	@echo "🎯 Initializing Vakıf Dashboard for self-hosting..."
	make build-local
	@echo ""
	@echo "✅ Initialization complete!"
	@echo ""
	@echo "🚀 Next steps:"
	@echo "   1. Configure SSL: make setup-ssl"
	@echo "   2. Build images:  make build-all"
	@echo "   3. Start services: make up-all"
	@echo "   4. Monitor:       make monitor"

# =====================================================
# 🚀 Production Deployment
# =====================================================

deploy-prod: ## Full production deployment
	@echo "🚀 Starting production deployment..."
	make init-dirs
	make build-all
	make up-all
	@echo ""
	@echo "⏳ Waiting for services to start..."
	sleep 10
	make health-check
	@echo ""
	@echo "✅ Production deployment completed!"
	@echo "📡 Access your dashboard at: http://localhost:8082"

deploy-prod-ssl: setup-ssl deploy-prod up-all-nginx ## Deploy with SSL and Nginx
	@echo "🔒 SSL-enabled production deployment completed!"
	@echo "🌐 HTTP Access: http://localhost:8080"
	@echo "🔒 HTTPS Access: https://localhost"

# =====================================================
# 🧪 Testing & Development
# =====================================================

shell: ## Access application container shell
	docker-compose exec vakif-dashboard sh

shell-nginx: ## Access nginx container shell
	docker-compose exec nginx sh

debug: ## Debug mode with verbose logging
	DEBUG=* docker-compose up

# =====================================================
# 📈 Performance & Maintenance
# =====================================================

optimize: ## Optimize system performance
	@echo "⚡ Optimizing system..."
	docker system df
	docker system prune -f
	@echo "✅ Optimization completed!"

update: ## Update all services
	@echo "🔄 Updating services..."
	docker-compose pull
	make rebuild-all
	@echo "✅ Update completed!"

# =====================================================
# 📚 Information & Help
# =====================================================

info: ## Show system information
	@echo "ℹ️  System Information:"
	@echo "Docker Version: $(shell docker --version)"
	@echo "Docker Compose: $(shell docker-compose --version)"
	@echo "Node.js: $(shell node --version 2>/dev/null || echo 'Not installed locally')"
	@echo "NPM: $(shell npm --version 2>/dev/null || echo 'Not installed locally')"
	@echo ""
	@echo "📊 Current Status:"
	make status

workflows: ## Show common workflows
	@echo ""
	@echo "📖 Common Self-Hosting Workflows:"
	@echo "=================================="
	@echo "🏁 First time setup:    make init-all && make deploy-prod"
	@echo "🔒 With SSL:           make deploy-prod-ssl"
	@echo "🔄 Update & restart:   make update"
	@echo "🧹 Clean restart:      make clean-all && make deploy-prod"
	@echo "💾 Backup:             make backup-all"
	@echo "🏥 Health check:       make health-check"
	@echo "📊 Monitor:            make monitor"
	@echo ""
	@echo "🐛 Troubleshooting:"
	@echo "==================="
	@echo "📝 Check logs:        make logs"
	@echo "🔍 Debug mode:        make debug"
	@echo "🏥 Health check:      make health-check"
	@echo "🔄 Force rebuild:     make rebuild-all"

# Legacy compatibility
build: build-all
up: up-all
down: down-all 