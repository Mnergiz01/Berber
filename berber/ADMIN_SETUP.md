# 🔐 Admin Hesabı Kurulum Kılavuzu

Bu sistem **tek bir süper admin** kullanıcısı ile çalışır. Berberler ve çalışanlar admin panelinden yönetilir.

## 🚀 İlk Admin Hesabını Oluşturma

### Adım 1: Supabase Dashboard'da Kullanıcı Oluşturun

1. [Supabase Dashboard](https://app.supabase.com) > **Authentication** > **Users** bölümüne gidin

2. **"Add user"** butonuna tıklayın

3. Kullanıcı bilgilerini girin:
   ```
   Email: admin@admin.com
   Password: admin123
   Auto Confirm User: ✅ AÇIK (E-posta doğrulamasını atla)
   ```

4. **"Create user"** butonuna tıklayın

### Adım 2: SQL Script Çalıştırın

1. Supabase Dashboard > **SQL Editor** bölümüne gidin

2. Aşağıdaki SQL kodunu yapıştırın ve **"Run"** butonuna tıklayın:

```sql
-- Admin kullanıcısını admin_users tablosuna ekle
INSERT INTO admin_users (auth_id, full_name, email, role, is_active)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'admin@admin.com'),
  'Admin',
  'admin@admin.com',
  'super_admin',
  true
);

-- Kontrol: Admin kullanıcısının oluştuğunu doğrula
SELECT * FROM admin_users WHERE email = 'admin@admin.com';
```

3. İkinci sorgu sonucunda admin kullanıcısını görmelisiniz

### Adım 3: Giriş Yapın

Artık şu bilgilerle giriş yapabilirsiniz:
```
E-posta: admin@admin.com
Şifre: admin123
```

## 🔐 Şifre Yönetimi

### Şifre Değiştirme

1. Giriş ekranında **"Şifre Değiştir"** linkine tıklayın
2. Mevcut şifrenizi ve yeni şifrenizi girin
3. Şifrenizi güncelleyin

### Şifre Sıfırlama (E-posta ile)

1. Giriş ekranında **"Şifremi Unuttum"** linkine tıklayın
2. E-posta adresinizi girin
3. E-postanıza gelen bağlantıya tıklayın
4. Yeni şifrenizi belirleyin

## 👥 Berber ve Çalışan Yönetimi

Tüm berber ve çalışan işlemleri **Admin Paneli** üzerinden yapılır:

### Yeni Berber Ekleme

1. Admin paneline giriş yapın
2. **"Çalışanlar"** sekmesine tıklayın
3. **"Yeni Çalışan"** butonuna tıklayın
4. Berber bilgilerini girin:
   - Ad Soyad
   - Uzmanlık Alanı
   - Telefon
   - E-posta
   - Çalışma Saatleri
   - Hakkında
   - Yapabileceği Hizmetler
5. **"Kaydet"** butonuna tıklayın

### Berber Düzenleme

1. **"Çalışanlar"** sekmesinde berberi bulun
2. **Düzenle** (✏️) ikonuna tıklayın
3. Bilgileri güncelleyin
4. **"Kaydet"** butonuna tıklayın

### Berberi Pasif Hale Getirme

1. **"Çalışanlar"** sekmesinde berberi bulun
2. **Pasif Yap** (🚫) ikonuna tıklayın
3. Onaylayın

## ✂️ Hizmet Yönetimi

Hizmetler de admin panelinden yönetilir:

### Yeni Hizmet Ekleme

1. Admin paneline giriş yapın
2. **"Hizmetler"** sekmesine tıklayın
3. **"Yeni Hizmet"** butonuna tıklayın
4. Hizmet bilgilerini girin:
   - Hizmet Adı
   - Süre (dakika)
   - Fiyat (TL)
   - Açıklama
5. **"Kaydet"** butonuna tıklayın

## 📊 Admin Paneli Özellikleri

### Randevular
- Tüm randevuları görüntüleme
- Tarih filtreleme
- Randevu iptal etme

### Hizmetler (Sadece Super Admin)
- Hizmet ekleme
- Hizmet düzenleme
- Hizmet silme
- Fiyat ve süre belirleme

### Çalışanlar (Sadece Super Admin)
- Çalışan ekleme
- Çalışan düzenleme
- Çalışma saatleri ayarlama
- Hizmet atama
- Çalışanı pasif hale getirme

## 🔧 Sorun Giderme

### "Bu hesap yönetici yetkisine sahip değil" hatası

**Neden:** Kullanıcı Supabase Auth'da var ama `admin_users` tablosunda kayıtlı değil.

**Çözüm:**
```sql
-- Kullanıcının auth_id'sini bulun
SELECT id, email FROM auth.users WHERE email = 'admin@admin.com';

-- Admin users tablosuna ekleyin
INSERT INTO admin_users (auth_id, full_name, email, role, is_active)
VALUES (
  'BURADA_AUTH_ID_YAZ',
  'Admin',
  'admin@admin.com',
  'super_admin',
  true
);
```

### Şifre değişmiyor

**Çözüm:**
1. Çıkış yapın
2. Tekrar giriş yapın
3. Şifre değiştir seçeneğini kullanın

### Giriş yapamıyorum

**Çözüm:**
1. E-posta adresinin doğru olduğundan emin olun: `admin@admin.com`
2. Şifre: `admin123` (ilk giriş için)
3. Supabase Dashboard > Authentication > Users bölümünden kullanıcının aktif olduğunu kontrol edin

## 🎯 Önemli Notlar

1. **Tek Admin Sistemi**: Sistemde sadece bir süper admin vardır
2. **Berber Kayıt Yok**: Berberler kullanıcı kaydı yapamazlar, sadece admin tarafından eklenir
3. **Admin Paneli Yetkisi**: Sadece super_admin rolüne sahip kullanıcı tüm özelliklere erişebilir
4. **Şifre Güvenliği**: İlk girişten sonra mutlaka şifrenizi değiştirin
5. **Yedekleme**: Admin hesap bilgilerinizi güvenli bir yerde saklayın

---

**İlk Giriş Bilgileri:**
- **E-posta:** admin@admin.com
- **Şifre:** admin123

⚠️ **ÇOK ÖNEMLİ:** İlk girişten sonra mutlaka şifrenizi değiştirin!
