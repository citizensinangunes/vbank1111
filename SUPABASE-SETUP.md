# Supabase + Netlify Deployment Guide

Bu kılavuz Vakıf Dashboard'ı Supabase (PostgreSQL) + Netlify ile deploy etmenizi sağlar.

## 🎯 Avantajlar

✅ **Platform Bağımsız**: SQLite yerine PostgreSQL  
✅ **Gerçek Cloud Database**: Persistent storage  
✅ **Ücretsiz Plan**: Supabase + Netlify free tier  
✅ **Otomatik Backup**: Supabase automatic backups  
✅ **Kolay Scaling**: Database ve app ayrı scale  

## 📋 Ön Gereksinimler

- Supabase hesabı ([supabase.com](https://supabase.com))
- Netlify hesabı ([netlify.com](https://netlify.com))
- GitHub/Git repository

## 🗄️ 1. Supabase Database Setup

### 1.1 Yeni Proje Oluştur
```bash
1. https://supabase.com/dashboard → "New Project"
2. Organization seç/oluştur
3. Project Name: "vakif-dashboard" 
4. Database Password: güçlü şifre
5. Region: "Central Europe" (en yakın)
6. "Create new project"
```

### 1.2 Database Tablolarını Oluştur
```sql
-- Supabase Dashboard > SQL Editor > "New query"
-- supabase-setup.sql dosyasındaki tüm kodu kopyala-yapıştır
-- "Run" butonuna bas

-- Tablolar oluşturulacak:
-- ✅ vakif_records (ana veriler)
-- ✅ pdf_documents (PDF dosya takibi)
-- ✅ İndeksler (performance)
-- ✅ Trigger'lar (updated_at otomatik)
-- ✅ Duplicate temizleme fonksiyonu
```

### 1.3 API Keys Al
```bash
Supabase Dashboard > Settings > API

📋 Gerekli Bilgiler:
- Project URL: https://xxx.supabase.co
- anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🌐 2. Netlify Deployment

### 2.1 Repository Hazırla
```bash
git add .
git commit -m "Add Supabase PostgreSQL support"
git push origin main
```

### 2.2 Netlify Site Oluştur
```bash
1. netlify.com/dashboard → "Add new site"
2. "Import from Git" → GitHub
3. Repository seç: vakif-dashboard
4. Build settings:
   - Build command: npm run build
   - Publish directory: .next
5. "Deploy site"
```

### 2.3 Environment Variables
```bash
Netlify Dashboard > Site settings > Environment variables

➕ Ekle:
Key: NEXT_PUBLIC_SUPABASE_URL
Value: https://xxx.supabase.co

➕ Ekle: 
Key: NEXT_PUBLIC_SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

💾 Save → Site redeploy otomatik başlar
```

## 🔧 3. Yerel Geliştirme

### 3.1 Dependencies Install
```bash
npm install
# Yeni dependencies:
# ✅ @supabase/supabase-js
# ✅ pdf-parse (platform independent)
# ❌ better-sqlite3 (kaldırıldı)
```

### 3.2 Environment Variables
```bash
# .env.local dosyası oluştur (gitignore'da)
echo "NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co" > .env.local
echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." >> .env.local
```

### 3.3 Test Et
```bash
npm run dev
# http://localhost:3000
# ✅ PDF upload test
# ✅ Database bağlantı test
# ✅ Dashboard görüntüleme test
```

## 📊 4. Veritabanı Yönetimi

### 4.1 Supabase Dashboard
```bash
Supabase Dashboard > Table Editor
- vakif_records: Tüm finansal kayıtlar
- pdf_documents: Upload edilen PDF'ler

SQL Editor: Custom queries
- Backup SQL'leri
- Data migration
- Performance optimization
```

### 4.2 Data Export/Import
```sql
-- Backup (SQL Editor)
SELECT * FROM vakif_records ORDER BY date DESC;

-- CSV Export
Supabase Dashboard > Table Editor > vakif_records > Export as CSV

-- Bulk Import
Table Editor > Insert > CSV Upload
```

## 🚀 5. Production Deployment

### 5.1 Custom Domain (Opsiyonel)
```bash
Netlify Dashboard > Domain settings
- vakif-dashboard.yourdomain.com
- SSL otomatik (Let's Encrypt)
```

### 5.2 Performance Optimization
```sql
-- Supabase'de query optimization
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM vakif_records 
WHERE date >= '2024-01-01' 
ORDER BY date DESC LIMIT 50;

-- İndeks ekle (gerekirse)
CREATE INDEX idx_vakif_date_type ON vakif_records(date, type);
```

## 🔍 6. Troubleshooting

### 6.1 Common Issues
```bash
❌ "Supabase URL ve Key environment variables gerekli!"
✅ Fix: .env.local ve Netlify env vars kontrol et

❌ "relation vakif_records does not exist"  
✅ Fix: supabase-setup.sql script'ini çalıştır

❌ "PDF parsing error"
✅ Fix: pdf-parse dependency install (npm install)

❌ Build error on Netlify
✅ Fix: Environment variables Netlify'da ayarlı mı?
```

### 6.2 Database Reset
```sql
-- Tüm veriyi sil (DEV ONLY!)
DELETE FROM vakif_records;
DELETE FROM pdf_documents;

-- Tabloları sıfırla
DROP TABLE IF EXISTS vakif_records CASCADE;
DROP TABLE IF EXISTS pdf_documents CASCADE;
-- Sonra supabase-setup.sql'i tekrar çalıştır
```

## 💰 7. Maliyet Bilgisi

### Supabase Free Tier
- Database: 500MB storage
- API requests: 50,000/month  
- Bandwidth: 2GB egress/month
- **Unlimited projects**

### Netlify Free Tier  
- Build minutes: 300/month
- Sites: Unlimited
- Bandwidth: 100GB/month
- **Form submissions: 100/month**

### Scaling (Ücretli Planlar)
- Supabase Pro: $25/month (8GB storage, 500K API)
- Netlify Pro: $19/month (unlimited build minutes)

## 🔗 8. Faydalı Linkler

- [Supabase Documentation](https://supabase.com/docs)
- [Netlify Next.js Guide](https://docs.netlify.com/frameworks/next-js/)
- [Supabase + Next.js Tutorial](https://supabase.com/docs/guides/getting-started/tutorials/with-nextjs)

## ✅ 9. Checklist

- [ ] Supabase project oluşturuldu
- [ ] SQL migration çalıştırıldı  
- [ ] API keys alındı
- [ ] Netlify site deploy edildi
- [ ] Environment variables ayarlandı
- [ ] Local development test edildi
- [ ] PDF upload test edildi
- [ ] Production URL test edildi

## 🎉 Başarılı!

Vakıf Dashboard artık Supabase PostgreSQL + Netlify ile production'da! 

Site URL: `https://your-site-name.netlify.app` 