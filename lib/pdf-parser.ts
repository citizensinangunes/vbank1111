import { VakifRecord, createRecordFingerprint } from './database';
import { writeFileSync, unlinkSync, readFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { execSync } from 'child_process';

export async function parsePdfBuffer(buffer: Buffer): Promise<Omit<VakifRecord, 'id'>[]> {
  try {
    console.log('🔍 PDF Parser v16 - CSV Style Logic');
    console.log('📊 PDF parsing başladı, buffer size:', buffer.length);
    
    // Geçici dosya oluştur
    const tempFilePath = join(tmpdir(), `temp-pdf-${Date.now()}.pdf`);
    const textFilePath = join(tmpdir(), `temp-text-${Date.now()}.txt`);
    
    writeFileSync(tempFilePath, buffer);
    console.log('📁 Temp PDF file created:', tempFilePath);
    
    // pdftotext kullanarak PDF'i text'e çevir
    try {
      execSync(`/opt/homebrew/bin/pdftotext "${tempFilePath}" "${textFilePath}"`, { 
        encoding: 'utf8',
        timeout: 30000 
      });
      console.log('✅ PDF converted to text using pdftotext');
    } catch (error) {
      console.error('❌ pdftotext error:', error);
      throw new Error('PDF text extraction failed');
    }
    
    // Text dosyasını oku
    let text = '';
    if (readFileSync) {
      text = readFileSync(textFilePath, 'utf8');
    }
    
    // Geçici dosyaları sil
    try {
      unlinkSync(tempFilePath);
      unlinkSync(textFilePath);
    } catch (cleanupError) {
      console.warn('⚠️ Cleanup error:', cleanupError);
    }
    
    console.log('📝 PDF text extracted, length:', text.length);
    
    return await extractFinancialDataCSVStyle(text);
  } catch (error) {
    console.error('❌ PDF parsing error:', error);
    throw new Error('PDF dosyası işlenirken hata oluştu: ' + (error instanceof Error ? error.message : 'Bilinmeyen hata'));
  }
}

async function extractFinancialDataCSVStyle(text: string): Promise<Omit<VakifRecord, 'id'>[]> {
  const records: Omit<VakifRecord, 'id'>[] = [];
  const lines = text.split('\n').map(line => line.trim()).filter(line => line.length > 0);
  
  console.log('🎯 CSV Style Parser - Context Based Pattern Matching');
  console.log('📊 Toplam satır sayısı:', lines.length);
  
  let processedCount = 0;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Ana pattern: "2025.07.01 valörlü GZ:" 
    if (line.includes('valörlü GZ:')) {
      console.log(`\n🎯 GZ satırı bulundu (${i + 1}): "${line}"`);
      
      // Sonraki satırları topla (max 10 satır)
      let context = [line];
      for (let j = 1; j <= 10 && i + j < lines.length; j++) {
        const nextLine = lines[i + j];
        context.push(nextLine);
        
        // İşlem tamamlandıysa dur
        if (nextLine.includes('ALIS') || nextLine.includes('SATIS')) {
          break;
        }
      }
      
      console.log('📋 Context:', context);
      
      // Transaction parse et
      const record = await parseTransactionFromContext(context);
      if (record) {
        const fingerprint = createRecordFingerprint(record);
        records.push({
          ...record,
          fingerprint
        });
        processedCount++;
        console.log(`✅ Transaction parsed: ${record.type} - ${record.amount} TL - ${record.description}`);
      }
    }
  }
  
  console.log(`\n🎯 CSV Style Parser Sonuç:`);
  console.log(`  ✅ Bulunan işlem: ${processedCount}`);
  console.log(`  📝 Kayıt sayısı: ${records.length}`);
  
  return records;
}

async function parseTransactionFromContext(context: string[]): Promise<Omit<VakifRecord, 'id'> | null> {
  try {
    // Tarih çıkar
    const dateMatch = context[0].match(/(\d{4})\.(\d{2})\.(\d{2})/);
    if (!dateMatch) return null;
    
    const date = `${dateMatch[1]}-${dateMatch[2]}-${dateMatch[3]}`;
    
    // Tutar bul (GZ: sonrası)
    let amount = null;
    let isNegative = false;
    
    for (let line of context) {
      const amountMatch = line.match(/GZ:\s*$/) ? 
        context[context.indexOf(line) + 1]?.match(/(-?[\d,.]+)\s*TL/) :
        line.match(/GZ:\s*(-?[\d,.]+)\s*TL/);
      
      if (amountMatch) {
        amount = Math.abs(parseFloat(amountMatch[1].replace(/\./g, '').replace(',', '.')));
        isNegative = amountMatch[1].includes('-');
        break;
      }
    }
    
    if (!amount) return null;
    
    // Hisse bilgileri bul
    let stockCode = null;
    let shareCount = null;
    let unitPrice = null;
    let transactionType = null;
    let time = null;
    
    for (let line of context) {
      // Saat + Hisse + Adet pattern'i
      const stockMatch = line.match(/(\d{2}:\d{2}:\d{2})\s+([A-Z]{4,6})\s+([\d,.]+)\s+ADET/);
      if (stockMatch) {
        time = stockMatch[1];
        stockCode = stockMatch[2];
        shareCount = parseFloat(stockMatch[3].replace(/\./g, '').replace(',', '.'));
      }
      
      // Birim fiyat + işlem tipi
      const priceMatch = line.match(/x([\d,.]+)\s+TL\s+(ALIS|SATIS)/);
      if (priceMatch) {
        unitPrice = parseFloat(priceMatch[1].replace(',', '.'));
        transactionType = priceMatch[2];
      }
    }
    
    if (!stockCode || !shareCount || !unitPrice || !transactionType) {
      console.log('❌ Incomplete data:', { stockCode, shareCount, unitPrice, transactionType });
      return null;
    }
    
    // İşlem tipi belirleme
    const type: VakifRecord['type'] = (transactionType === 'ALIS' || isNegative) ? 'gider' : 'gelir';
    
    // Hesaplamalar
    const shareValue = shareCount * unitPrice; // Hisse tutarı
    const commissionRate = 0.0005; // %0.5 komisyon
    const bsmvRate = 0.000015; // %0.015 BSMV
    
    const commission = shareValue * commissionRate; // Komisyon tutarı
    const bsmv = shareValue * bsmvRate; // BSMV tutarı
    const totalCost = shareValue + commission + bsmv; // Toplam maliyet
    
    console.log(`💰 Komisyon & BSMV Hesaplamaları:`);
    console.log(`   📊 Hisse Tutarı: ${shareValue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL`);
    console.log(`   💳 Komisyon (%0.5): ${commission.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL`);
    console.log(`   🏛️ BSMV (%0.015): ${bsmv.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL`);
    console.log(`   💎 Toplam Maliyet: ${totalCost.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL`);
    console.log(`   📋 PDF'den Gelen: ${amount.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL`);
    
    const description = `${stockCode} Hisse ${transactionType === 'ALIS' ? 'Alım' : 'Satış'} (${shareCount.toLocaleString('tr-TR')} adet x ${unitPrice.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL = ${shareValue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL + Komisyon: ${commission.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL + BSMV: ${bsmv.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL) [${time}]`;
    
    console.log(`📊 Parse edildi: ${date} | ${stockCode} | ${shareCount} adet | ${unitPrice} TL | ${transactionType} | Toplam: ${totalCost.toLocaleString('tr-TR', { minimumFractionDigits: 2 })} TL`);
    
    return {
      date,
      type,
      amount: totalCost, // Hesaplanan toplam maliyeti kullan
      description,
      category: 'Hisse Senetleri',
      source: 'PDF Import Vakıf CSV Style v2'
    };
    
  } catch (error) {
    console.error('❌ Parse error:', error);
    return null;
  }
}

// Test function
export async function testParsing(sampleText: string): Promise<Omit<VakifRecord, 'id'>[]> {
  return await extractFinancialDataCSVStyle(sampleText);
} 