import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { createHash } from 'crypto';

export interface VakifRecord {
  id?: number;
  date: string;
  type: 'gelir' | 'gider' | 'bağış' | 'harcama';
  amount: number;
  description: string;
  category: string;
  source: string;
  fingerprint?: string;
  created_at?: string;
  updated_at?: string;
}

export interface PdfDocument {
  id?: number;
  filename: string;
  file_hash: string;
  upload_date?: string;
  records_count?: number;
  file_size?: number;
}

let supabase: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (!supabase) {
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    
    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Supabase URL ve Key environment variables gerekli!');
    }
    
    supabase = createClient(supabaseUrl, supabaseKey);
    console.log('✅ Supabase client initialized');
  }
  
  return supabase;
}

// Database initialization (tablolar Supabase dashboard'da oluşturulacak)
export async function initializeDatabase() {
  console.log('🗄️ Database initialization - tablolar Supabase dashboard\'da oluşturulmalı');
  return true;
}

// Benzersiz fingerprint oluştur
export function createRecordFingerprint(record: Omit<VakifRecord, 'id' | 'fingerprint'>): string {
  const dataString = `${record.date}|${record.type}|${record.amount.toFixed(8)}|${record.description.trim()}|${record.category}|${record.source}`;
  return createHash('sha256').update(dataString).digest('hex').substring(0, 16);
}

// PDF dosyası hash'i oluştur
export function createFileHash(buffer: Buffer): string {
  return createHash('sha256').update(buffer).digest('hex');
}

// Kayıt ekle (duplicate kontrolü ile)
export async function insertVakifRecord(record: Omit<VakifRecord, 'id'>): Promise<{ success: boolean; id?: number; duplicate?: boolean }> {
  const supabase = getSupabaseClient();
  
  try {
    const fingerprint = record.fingerprint || createRecordFingerprint(record);
    
    // Duplicate kontrolü
    const { data: existing, error: checkError } = await supabase
      .from('vakif_records')
      .select('id')
      .eq('fingerprint', fingerprint)
      .single();
    
    if (existing && !checkError) {
      console.log('Duplicate record found, skipping:', fingerprint);
      return { success: false, duplicate: true };
    }

    const { data, error } = await supabase
      .from('vakif_records')
      .insert([{
        date: record.date,
        type: record.type,
        amount: record.amount,
        description: record.description,
        category: record.category,
        source: record.source || 'Manual',
        fingerprint: fingerprint
      }])
      .select('id')
      .single();
    
    if (error) {
      if (error.code === '23505') { // unique constraint violation
        console.log('Duplicate record detected by constraint:', record);
        return { success: false, duplicate: true };
      }
      throw error;
    }
    
    console.log('Record inserted with ID:', data.id);
    return { success: true, id: data.id };
  } catch (error) {
    console.error('Insert error:', error);
    throw error;
  }
}

// Toplu kayıt ekleme (duplicate kontrolü ile)
export async function insertVakifRecords(records: Omit<VakifRecord, 'id'>[]): Promise<{ 
  inserted: number; 
  duplicates: number; 
  total: number;
  insertedIds: number[];
}> {
  const result = { inserted: 0, duplicates: 0, total: records.length, insertedIds: [] as number[] };
  
  // Supabase'de batch insert yaparken duplicate kontrolü için tek tek yapıyoruz
  for (const record of records) {
    try {
      const insertResult = await insertVakifRecord(record);
      if (insertResult.success && insertResult.id) {
        result.inserted++;
        result.insertedIds.push(insertResult.id);
      } else if (insertResult.duplicate) {
        result.duplicates++;
      }
    } catch (error) {
      console.error('Batch insert error for record:', record, error);
    }
  }
  
  console.log(`Bulk insert completed: ${result.inserted} inserted, ${result.duplicates} duplicates, ${result.total} total`);
  return result;
}

// PDF dosyası kaydet (duplicate kontrolü ile)
export async function insertPdfDocument(filename: string, fileHash: string, fileSize: number): Promise<{ 
  success: boolean; 
  id?: number; 
  duplicate?: boolean 
}> {
  const supabase = getSupabaseClient();
  
  try {
    // Duplicate kontrolü
    const { data: existing } = await supabase
      .from('pdf_documents')
      .select('id')
      .eq('file_hash', fileHash)
      .single();
    
    if (existing) {
      console.log('PDF already processed:', filename);
      return { success: false, duplicate: true };
    }

    const { data, error } = await supabase
      .from('pdf_documents')
      .insert([{
        filename,
        file_hash: fileHash,
        file_size: fileSize,
        records_count: 0
      }])
      .select('id')
      .single();
    
    if (error) {
      if (error.code === '23505') {
        return { success: false, duplicate: true };
      }
      throw error;
    }
    
    return { success: true, id: data.id };
  } catch (error) {
    console.error('PDF insert error:', error);
    throw error;
  }
}

// PDF kayıt sayısını güncelle
export async function updatePdfRecordCount(pdfId: number, recordCount: number): Promise<void> {
  const supabase = getSupabaseClient();
  
  const { error } = await supabase
    .from('pdf_documents')
    .update({ records_count: recordCount })
    .eq('id', pdfId);
  
  if (error) {
    throw error;
  }
}

// Tüm kayıtları getir
export async function getAllVakifRecords(): Promise<VakifRecord[]> {
  const supabase = getSupabaseClient();
  
  const { data, error } = await supabase
    .from('vakif_records')
    .select('*')
    .order('date', { ascending: false })
    .order('id', { ascending: false });
  
  if (error) {
    throw error;
  }
  
  return data || [];
}

// İstatistikleri getir
export async function getVakifStats() {
  const supabase = getSupabaseClient();
  
  const { data, error } = await supabase
    .from('vakif_records')
    .select('type, amount, date, category');
  
  if (error) {
    throw error;
  }
  
  const records = data || [];
  
  const stats = {
    totalRecords: records.length,
    totalIncome: records.filter(r => ['gelir', 'bağış'].includes(r.type)).reduce((sum, r) => sum + r.amount, 0),
    totalExpense: records.filter(r => ['gider', 'harcama'].includes(r.type)).reduce((sum, r) => sum + r.amount, 0),
    activeDays: new Set(records.map(r => r.date)).size,
    categories: new Set(records.map(r => r.category)).size
  };
  
  return {
    ...stats,
    netIncome: stats.totalIncome - stats.totalExpense
  };
}

// PDF'leri getir
export async function getAllPdfDocuments(): Promise<PdfDocument[]> {
  const supabase = getSupabaseClient();
  
  const { data, error } = await supabase
    .from('pdf_documents')
    .select('*')
    .order('upload_date', { ascending: false });
  
  if (error) {
    throw error;
  }
  
  return data || [];
}

// Veritabanını temizle (test için)
export async function clearDatabase(): Promise<void> {
  const supabase = getSupabaseClient();
  
  await supabase.from('vakif_records').delete().neq('id', 0);
  await supabase.from('pdf_documents').delete().neq('id', 0);
  
  console.log('Database cleared');
}

// Duplicate kayıtları temizle
export async function removeDuplicateRecords(): Promise<number> {
  const supabase = getSupabaseClient();
  
  // PostgreSQL'de duplicate temizleme
  const { data, error } = await supabase.rpc('remove_duplicate_records');
  
  if (error) {
    console.error('Remove duplicates error:', error);
    return 0;
  }
  
  const removedCount = data || 0;
  console.log(`Removed ${removedCount} duplicate records`);
  return removedCount;
}

// Veritabanı durumunu kontrol et
export async function getDatabaseInfo() {
  const supabase = getSupabaseClient();
  
  const [recordsResult, pdfsResult] = await Promise.all([
    supabase.from('vakif_records').select('fingerprint', { count: 'exact', head: true }),
    supabase.from('pdf_documents').select('id', { count: 'exact', head: true })
  ]);
  
  // Duplicate count için basit yaklaşım
  const { data: allRecords } = await supabase.from('vakif_records').select('fingerprint');
  const fingerprints = allRecords?.map(r => r.fingerprint) || [];
  const uniqueFingerprints = new Set(fingerprints);
  const duplicateCount = fingerprints.length - uniqueFingerprints.size;
  
  return {
    totalRecords: recordsResult.count || 0,
    totalPdfs: pdfsResult.count || 0,
    duplicateFingerprints: duplicateCount
  };
}

// Backward compatibility için
export function getDatabase() {
  console.warn('getDatabase() deprecated, use getSupabaseClient()');
  return getSupabaseClient();
} 