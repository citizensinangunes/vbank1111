# ⚠️ Netlify Deployment Warning

## SQLite Database Issue

**CRITICAL:** This application uses SQLite which **DOES NOT WORK** on Netlify because:

1. **Read-only filesystem** - Cannot write to database
2. **Stateless functions** - Database resets on every deployment
3. **No persistent storage** - Files are lost between builds

## Solutions for Netlify Deployment

### Option 1: Use Cloud Database
Replace SQLite with a cloud database:
- **Supabase** (PostgreSQL) - Free tier available
- **PlanetScale** (MySQL) - Serverless database
- **Vercel Postgres** - If using Vercel instead
- **Airtable** - Simple table storage

### Option 2: Use Alternative Platforms
Deploy on platforms that support SQLite:
- **Vercel** - Works with SQLite + serverless functions
- **Railway** - Full server deployment
- **Render** - Web services with persistent storage
- **Self-hosting** - Use Docker setup included in repo

### Option 3: Convert to Static Site
- Remove database dependency
- Use local storage or external APIs
- Generate static pages only

## Current Status

This repo includes:
- ✅ **Netlify config** (netlify.toml) - Ready but DB won't work
- ✅ **Docker config** - For self-hosting
- ✅ **Vercel ready** - Best option for this SQLite app

## Recommendation

**Use Vercel instead of Netlify** for this SQLite-based application, or migrate to a cloud database solution. 