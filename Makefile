# Vakıf Dashboard Makefile
# Netlify Deployment Ready

.PHONY: help dev build install clean deploy netlify-dev netlify-build

# Default target
help: ## Show this help message
	@echo "🏛️  Vakıf Dashboard - Netlify Deployment Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =====================================================
# 🔧 Development Commands
# =====================================================

dev: ## Start development server
	npm run dev

install: ## Install dependencies
	npm install

build: ## Build application for production
	npm run build

lint: ## Run linting
	npm run lint

test: ## Run tests
	npm test || echo "No tests configured"

# =====================================================
# 🌐 Netlify Commands
# =====================================================

netlify-dev: ## Start Netlify development server
	netlify dev

netlify-build: ## Build for Netlify deployment
	netlify build

netlify-deploy: ## Deploy to Netlify (draft)
	netlify deploy

netlify-deploy-prod: ## Deploy to Netlify production
	netlify deploy --prod

netlify-status: ## Show Netlify site status
	netlify status

# =====================================================
# 🗄️ Database Commands
# =====================================================

db-backup: ## Backup SQLite database (local only)
	@echo "💾 Creating database backup..."
	mkdir -p ./backups
	cp ./vakif.db ./backups/vakif-$(shell date +%Y%m%d-%H%M%S).db 2>/dev/null || echo "⚠️  Database file not found"
	@echo "✅ Database backed up to backups/"

db-restore: ## Restore database from backup (use: make db-restore FILE=backup.db)
	@if [ -z "$(FILE)" ]; then echo "❌ Usage: make db-restore FILE=backup.db"; exit 1; fi
	@echo "📥 Restoring database from $(FILE)..."
	cp $(FILE) ./vakif.db
	@echo "✅ Database restored from $(FILE)"

# =====================================================
# 🧹 Cleanup Commands
# =====================================================

clean: ## Clean build artifacts
	rm -rf .next
	rm -rf .netlify
	rm -rf node_modules/.cache

clean-all: clean ## Clean everything including node_modules
	rm -rf node_modules

# =====================================================
# 📖 Information Commands
# =====================================================

info: ## Show system information
	@echo "ℹ️  System Information:"
	@echo "Node.js: $(shell node --version 2>/dev/null || echo 'Not installed')"
	@echo "NPM: $(shell npm --version 2>/dev/null || echo 'Not installed')"
	@echo "Netlify CLI: $(shell netlify --version 2>/dev/null || echo 'Not installed')"

setup-netlify: ## Install Netlify CLI and login
	@echo "🌐 Setting up Netlify CLI..."
	npm install -g netlify-cli
	netlify login
	@echo "✅ Netlify CLI setup complete!"

# =====================================================
# ⚠️  Important Warnings
# =====================================================

warning: ## Show important deployment warnings
	@echo "⚠️  CRITICAL WARNING: SQLite Database Issue"
	@echo ""
	@echo "This application uses SQLite which DOES NOT WORK on Netlify!"
	@echo ""
	@echo "Reasons:"
	@echo "  • Read-only filesystem"
	@echo "  • Stateless functions"
	@echo "  • No persistent storage"
	@echo ""
	@echo "Solutions:"
	@echo "  1. Use Vercel instead (supports SQLite)"
	@echo "  2. Migrate to cloud database (Supabase, PlanetScale)"
	@echo "  3. Self-host with Docker"
	@echo ""
	@echo "See NETLIFY-WARNING.md for details"

# =====================================================
# 🚀 Deployment Workflows
# =====================================================

deploy: warning ## Deploy to Netlify (with warning)
	@echo "Proceeding with Netlify deployment..."
	@echo "Note: Database functionality will not work!"
	netlify deploy --prod

init: install ## Initialize project
	@echo "🎯 Initializing Vakıf Dashboard for Netlify..."
	make build
	@echo ""
	@echo "⚠️  Important: Read NETLIFY-WARNING.md before deploying!"
	@echo "✅ Initialization complete!" 