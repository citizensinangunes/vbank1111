-- Supabase PostgreSQL Table Setup
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştırın

-- 1. vakif_records tablosu
CREATE TABLE IF NOT EXISTS vakif_records (
  id SERIAL PRIMARY KEY,
  date TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('gelir', 'gider', 'bağış', 'harcama')),
  amount DECIMAL(15,2) NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'Manual',
  fingerprint TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. pdf_documents tablosu
CREATE TABLE IF NOT EXISTS pdf_documents (
  id SERIAL PRIMARY KEY,
  filename TEXT NOT NULL,
  file_hash TEXT UNIQUE NOT NULL,
  upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  records_count INTEGER DEFAULT 0,
  file_size INTEGER DEFAULT 0
);

-- 3. İndeksler (performance için)
CREATE INDEX IF NOT EXISTS idx_vakif_date ON vakif_records(date);
CREATE INDEX IF NOT EXISTS idx_vakif_type ON vakif_records(type);
CREATE INDEX IF NOT EXISTS idx_vakif_category ON vakif_records(category);
CREATE INDEX IF NOT EXISTS idx_vakif_fingerprint ON vakif_records(fingerprint);
CREATE INDEX IF NOT EXISTS idx_pdf_hash ON pdf_documents(file_hash);
CREATE INDEX IF NOT EXISTS idx_vakif_created_at ON vakif_records(created_at);

-- 4. Updated_at trigger (otomatik güncelleme)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_vakif_records_updated_at 
  BEFORE UPDATE ON vakif_records 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. RLS (Row Level Security) - isteğe bağlı
-- ALTER TABLE vakif_records ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE pdf_documents ENABLE ROW LEVEL SECURITY;

-- 6. Public access policy (geliştirme için)
-- CREATE POLICY "Enable all operations for all users" ON vakif_records FOR ALL USING (true);
-- CREATE POLICY "Enable all operations for all users" ON pdf_documents FOR ALL USING (true);

-- 7. Duplicate temizleme fonksiyonu
CREATE OR REPLACE FUNCTION remove_duplicate_records()
RETURNS INTEGER AS $$
DECLARE
  removed_count INTEGER;
BEGIN
  WITH duplicates AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY fingerprint ORDER BY id) as rn
    FROM vakif_records
  )
  DELETE FROM vakif_records 
  WHERE id IN (SELECT id FROM duplicates WHERE rn > 1);
  
  GET DIAGNOSTICS removed_count = ROW_COUNT;
  RETURN removed_count;
END;
$$ LANGUAGE plpgsql;

-- 8. Database seeding (test verisi)
-- INSERT INTO vakif_records (date, type, amount, description, category, source, fingerprint)
-- VALUES 
--   ('2024-01-15', 'gelir', 5000.00, 'Test gelir', 'Test Kategorisi', 'Manual', 'test1234567890123456'),
--   ('2024-01-16', 'gider', 1500.00, 'Test gider', 'Test Kategorisi', 'Manual', 'test1234567890123457');

-- Tablo kontrolleri
SELECT 'vakif_records' as table_name, COUNT(*) as row_count FROM vakif_records
UNION ALL
SELECT 'pdf_documents' as table_name, COUNT(*) as row_count FROM pdf_documents; 