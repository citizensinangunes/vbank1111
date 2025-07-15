# Supabase URL'lerini Bulma Kılavuzu

## 🎯 İhtiyacınız Olan URLs

Netlify deployment için **2 environment variable** gerekiyor:

### 1. Project URL 
```bash
NEXT_PUBLIC_SUPABASE_URL=https://[PROJECT_ID].supabase.co
```

### 2. Anon Key
```bash
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiI...
```

## 📍 Supabase Dashboard'dan URLs Alma

### 1. Supabase Dashboard'a Git
```bash
https://supabase.com/dashboard/projects
```

### 2. Project Seç
- Proje listesinden "vakif-dashboard" projesini seç

### 3. Settings > API
```bash
Project Settings > API (sol menüde)

✅ Project URL: 
https://hsskkbkvtomlbtfkdeba.supabase.co

✅ anon public key:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhzc2traGJrdnRvbWxidGZrZGViYSIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjk5NTAyNDAwLCJleHAiOjIwMTUwNzg0MDB9...
```

## 🔧 Netlify Environment Variables Ayarlama

### 1. Netlify Dashboard
```bash
https://app.netlify.com/sites/[SITE_NAME]/settings/deploys#environment-variables
```

### 2. Variables Ekle
```bash
➕ Add variable:
Key: NEXT_PUBLIC_SUPABASE_URL
Value: https://hsskkbkvtomlbtfkdeba.supabase.co

➕ Add variable:
Key: NEXT_PUBLIC_SUPABASE_ANON_KEY  
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Deploy Trigger
- Variables kaydedildikten sonra otomatik redeploy başlar
- **Clear cache and deploy site** de yapabilirsin

## ⚠️ DİKKAT: URL Formatları

### ❌ Yanlış (Database Connection)
```bash
# Bu PostgreSQL connection - environment variable için değil!
db.hsskkbkvtomlbtfkdeba.supabase.co:5432
```

### ✅ Doğru (Public API URL)
```bash
# Bu web API için - environment variable bu olmalı!
https://hsskkbkvtomlbtfkdeba.supabase.co
```

## 🧪 Test Etme

### Local Test (.env.local)
```bash
# .env.local dosyası oluştur
echo "NEXT_PUBLIC_SUPABASE_URL=https://hsskkbkvtomlbtfkdeba.supabase.co" > .env.local
echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOi..." >> .env.local

npm run dev
# http://localhost:3000 test et
```

### Production Test
```bash
# Netlify'da deploy sonrası
# Console'da error var mı kontrol et
# Network tab'da API calls başarılı mı bak
```

## 🔍 Troubleshooting

### Environment Variables Kontrol
```javascript
// Browser console'da test et:
console.log(process.env.NEXT_PUBLIC_SUPABASE_URL);
console.log(process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);

// ✅ URLs gözükmeli
// ❌ undefined ise environment variables eksik
```

### Common Errors
```bash
❌ "Supabase URL ve Key environment variables gerekli!"
✅ Fix: Netlify environment variables ekle

❌ "Failed to fetch"  
✅ Fix: URL format'ını kontrol et (https:// ile başlamalı)

❌ "Invalid API key"
✅ Fix: anon key'i tekrar kopyala-yapıştır
``` 