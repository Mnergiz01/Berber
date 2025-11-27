# Berber Randevu Sistemi - Kurulum Kılavuzu

## Özellikler

- ✅ Berber seçimi
- ✅ Hizmet seçimi (saç kesimi, sakal, boya vb.)
- ✅ Dolu/boş randevu saatleri görüntüleme
- ✅ Gerçek zamanlı müsaitlik kontrolü
- ✅ Randevu oluşturma, iptal etme
- ✅ Responsive tasarım (mobil uyumlu)
- ✅ Modern UI/UX (Tailwind CSS)

## Kurulum Adımları

### 1. Bağımlılıkları Yükleyin

```bash
npm install
```

### 2. Supabase Veritabanını Ayarlayın

1. [Supabase Dashboard](https://app.supabase.com) üzerinden projenize gidin
2. Sol menüden **SQL Editor** seçeneğine tıklayın
3. **New Query** butonuna tıklayın
4. `database-schema.sql` dosyasının içeriğini kopyalayıp SQL editöre yapıştırın
5. **Run** butonuna tıklayarak SQL komutlarını çalıştırın

Bu işlem:
- Gerekli tabloları oluşturacak (barbers, services, customers, appointments)
- Örnek berberleri ve hizmetleri ekleyecek
- Güvenlik politikalarını (RLS) ayarlayacak
- Yardımcı fonksiyonları oluşturacak

### 3. Çevre Değişkenlerini Kontrol Edin

`.env` dosyasının aşağıdaki değişkenleri içerdiğinden emin olun:

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 4. Uygulamayı Çalıştırın

```bash
npm run dev
```

Uygulama `http://localhost:5173` adresinde çalışacaktır.

## Kullanım

### Randevu Almak

1. Ana sayfada **"Randevu Al"** butonuna tıklayın
2. Berber seçin
3. Hizmet türünü seçin
4. Tarih seçin
5. Müsait saatleri görün (dolu saatler gri ve çizgili gösterilir)
6. Müsait bir saat seçin
7. İletişim bilgilerinizi girin
8. **"Randevu Oluştur"** butonuna tıklayın

### Randevuları Görüntüleme

1. Ana sayfada **"Randevular"** sekmesine tıklayın
2. Tarihe ve berbere göre filtreleme yapın
3. Randevuları görüntüleyin
4. İsterseniz randevuyu iptal edin

## Veritabanı Şeması

### Tablolar

- **barbers**: Berberlerin bilgileri (isim, telefon, çalışma saatleri)
- **services**: Hizmetler (saç kesimi, sakal tıraşı, fiyat, süre)
- **customers**: Müşteri bilgileri (isim, telefon, email)
- **appointments**: Randevular (berber, müşteri, hizmet, tarih, saat, durum)

### Randevu Durumları

- `pending`: Beklemede (yeni oluşturulmuş)
- `confirmed`: Onaylandı
- `completed`: Tamamlandı
- `cancelled`: İptal edildi

## Özelleştirme

### Yeni Berber Eklemek

Supabase Dashboard > Table Editor > barbers tablosundan yeni kayıt ekleyin:

```sql
INSERT INTO barbers (name, phone, email, description, working_hours)
VALUES (
  'Berber Adı',
  '+90 5XX XXX XXXX',
  'email@example.com',
  'Açıklama',
  '{"monday": {"start": "09:00", "end": "19:00"}, ...}'::jsonb
);
```

### Yeni Hizmet Eklemek

```sql
INSERT INTO services (name, duration, price, description)
VALUES ('Hizmet Adı', 30, 150.00, 'Açıklama');
```

### Çalışma Saatlerini Değiştirmek

Randevu saatleri varsayılan olarak 09:00 - 19:00 arası 30'ar dakikalık dilimler halinde.

Bunu değiştirmek için `AppointmentForm.vue` dosyasında `fetchAvailableTimeSlots` fonksiyonunu düzenleyin:

```javascript
const startHour = 9  // Başlangıç saati
const endHour = 19   // Bitiş saati
```

## Teknolojiler

- **Frontend**: Vue 3 (Composition API)
- **Stil**: Tailwind CSS
- **Backend**: Supabase (PostgreSQL)
- **Build Tool**: Vite

## Production Build

```bash
npm run build
```

Build dosyaları `dist/` klasöründe oluşturulacaktır.

## Sorun Giderme

### Bağlantı Hatası

Eğer "Supabase bağlantısı başarısız" hatası alıyorsanız:

1. `.env` dosyasındaki URL ve Key'lerin doğru olduğundan emin olun
2. Supabase projenizin aktif olduğunu kontrol edin
3. `npm run dev` komutuyla sunucuyu yeniden başlatın

### Tablolar Yok Hatası

Eğer "relation does not exist" hatası alıyorsanız:

1. `database-schema.sql` dosyasını Supabase SQL Editor'de çalıştırdığınızdan emin olun
2. Supabase Dashboard > Table Editor'den tabloların oluşturulduğunu kontrol edin

### Randevu Oluşturulamıyor

1. Row Level Security (RLS) politikalarının doğru ayarlandığından emin olun
2. Supabase Dashboard > Authentication > Policies bölümünden politikaları kontrol edin

## Lisans

Bu proje eğitim amaçlı oluşturulmuştur.
