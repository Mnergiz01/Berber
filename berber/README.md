# 💈 Berber Randevu Sistemi

Modern ve kullanıcı dostu berber randevu yönetim sistemi. Vue 3, Tailwind CSS ve Supabase ile geliştirilmiştir.

![Vue.js](https://img.shields.io/badge/Vue.js-3.5-4FC08D?style=flat&logo=vue.js)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-38B2AC?style=flat&logo=tailwind-css)
![Supabase](https://img.shields.io/badge/Supabase-Latest-3ECF8E?style=flat&logo=supabase)

## ✨ Özellikler

### Müşteri Özellikleri
- 📅 **Randevu Yönetimi**: Kolay randevu alma ve görüntüleme
- 🔴 **Dolu Saat Gösterimi**: Müsait olmayan saatler otomatik olarak işaretlenir
- 👤 **Berber Seçimi**: Birden fazla berber arasından seçim
- 👨‍💼 **Berber Profilleri**: Berberlerin detaylı bilgileri, hizmetleri ve randevuları
- ✂️ **Hizmet Seçimi**: Farklı hizmet türleri (saç kesimi, sakal, boya vb.)
- 📱 **Responsive Tasarım**: Tüm cihazlarda mükemmel görünüm

### Admin Paneli Özellikleri
- 🔐 **Rol Tabanlı Yetkilendirme**: Süper Admin, Admin ve Berber rolleri
- 📊 **Randevu Yönetimi**: Tüm randevuları görüntüleme ve yönetme
- ✂️ **Hizmet Yönetimi**: Hizmet ekleme, düzenleme ve silme (Admin ve Süper Admin)
- 👥 **Çalışan Yönetimi**: Çalışan ekleme, düzenleme ve pasif hale getirme (Admin ve Süper Admin)
- ⏰ **Çalışma Saatleri**: Her çalışan için özel çalışma saatleri belirleme
- 🔗 **Hizmet-Çalışan İlişkilendirme**: Hangi çalışanın hangi hizmeti yapabileceğini belirleme
- 🔒 **Güvenli Giriş**: Supabase Authentication ile güvenli giriş sistemi
- ⚡ **Gerçek Zamanlı**: Anlık müsaitlik kontrolü
- 🎨 **Modern UI/UX**: Tailwind CSS ile şık arayüz

## 🚀 Hızlı Başlangıç

### Gereksinimler

- Node.js 18+
- npm veya yarn
- Supabase hesabı

### Kurulum

1. **Bağımlılıkları yükleyin:**
   ```bash
   npm install
   ```

2. **Supabase veritabanını kurun:**
   - [Supabase Dashboard](https://app.supabase.com) > SQL Editor'a gidin
   - `database-schema.sql` dosyasının içeriğini yapıştırıp çalıştırın

3. **Çevre değişkenlerini ayarlayın:**
   - `.env` dosyası zaten oluşturulmuş durumda
   - Gerekirse Supabase URL ve Key'i güncelleyin

4. **Uygulamayı başlatın:**
   ```bash
   npm run dev
   ```

5. **Tarayıcıda açın:**
   - http://localhost:5173

6. **İlk admin hesabını oluşturun:**
   - [ADMIN_SETUP.md](./ADMIN_SETUP.md) dosyasındaki talimatları izleyin
   - İlk süper admin hesabınızı oluşturun

Detaylı kurulum için [KURULUM.md](./KURULUM.md) dosyasına bakın.

## 📸 Ekran Görüntüleri

### Ana Sayfa
- Modern ve şık arayüz
- Kolay navigasyon
- Randevular ve Randevu Al sekmeleri

### Randevu Alma Formu
- Berber seçimi
- Hizmet seçimi (görsel kartlar)
- Tarih seçimi
- Müsait/dolu saatlerin görüntülenmesi
- İletişim bilgileri
- Randevu özeti

### Randevu Listesi
- Tarih ve berber filtreleme
- Renk kodlu durum gösterimi
- Randevu iptal etme
- Detaylı bilgi görüntüleme

## 🏗️ Proje Yapısı

```
berber/
├── src/
│   ├── components/
│   │   ├── AdminLogin.vue         # Yönetici giriş ve kayıt
│   │   ├── AppointmentForm.vue    # Randevu alma formu
│   │   ├── AppointmentList.vue    # Randevu listesi (Admin Panel)
│   │   ├── BarbersList.vue        # Berberlerin listesi ve detayları
│   │   ├── ServicesManagement.vue # Hizmet yönetimi (Admin)
│   │   └── EmployeesManagement.vue # Çalışan yönetimi (Admin)
│   ├── App.vue                    # Ana component
│   ├── main.js                    # Giriş noktası
│   ├── supabase.js                # Supabase konfigürasyonu
│   └── style.css                  # Global stiller
├── database-schema.sql            # Veritabanı şeması
├── .env                          # Çevre değişkenleri
├── KURULUM.md                    # Detaylı kurulum kılavuzu
└── ADMIN_SETUP.md                # Admin paneli kurulum kılavuzu
```

## 🗄️ Veritabanı Tabloları

- **employees**: Çalışan/Berber bilgileri (isim, uzmanlık, çalışma saatleri, iletişim)
- **services**: Hizmet tipleri, süreleri ve fiyatları
- **employee_services**: Çalışan-Hizmet ilişkisi (hangi berber hangi hizmeti yapıyor)
- **appointments**: Randevu kayıtları (müşteri bilgileri dahil)
- **admin_users**: Yönetici kullanıcı bilgileri ve rolleri

## 🎯 Kullanım

### Müşteri Tarafı

#### Randevu Almak
1. "Randevu Al" butonuna tıklayın
2. Berber ve hizmet seçin
3. Tarih belirleyin
4. Müsait bir saat seçin (dolu saatler gri gösterilir)
5. İletişim bilgilerinizi girin
6. "Randevu Oluştur" butonuna tıklayın

#### Berberleri İnceleme
1. Ana sayfadaki "Berberlerimiz" bölümünden berberleri görün
2. Bir berbere tıklayarak detaylı bilgilerini, hizmetlerini ve randevularını görün

### Admin Paneli

#### Giriş Yapmak
1. Sağ üst köşedeki "Yönetici" butonuna tıklayın
2. E-posta ve şifrenizi girin
3. Giriş yapın

#### Randevuları Yönetmek
1. "Randevular" sekmesinde tüm randevuları görün
2. Tarih filtresi ile belirli günleri seçin
3. Gerekirse randevuları iptal edin

#### Hizmetleri Yönetmek (Admin/Süper Admin)
1. "Hizmetler" sekmesine tıklayın
2. "Yeni Hizmet" ile yeni hizmet ekleyin
3. Mevcut hizmetleri düzenleyin veya silin
4. Fiyat ve süreleri ayarlayın

#### Çalışanları Yönetmek (Admin/Süper Admin)
1. "Çalışanlar" sekmesine tıklayın
2. "Yeni Çalışan" ile yeni çalışan ekleyin
3. Çalışma saatlerini belirleyin
4. Yapabilecekleri hizmetleri seçin
5. Gerekirse çalışanı pasif hale getirin

## 🛠️ Teknolojiler

- **Frontend Framework**: Vue 3 (Composition API)
- **CSS Framework**: Tailwind CSS
- **Backend/Database**: Supabase (PostgreSQL)
- **Build Tool**: Vite
- **JavaScript Client**: @supabase/supabase-js

## 📦 Production Build

```bash
npm run build
```

Build dosyaları `dist/` klasöründe oluşturulur.

## 🔧 Yapılandırma

### Çalışma Saatlerini Değiştirme

`AppointmentForm.vue` dosyasında:

```javascript
const startHour = 9  // Başlangıç saati
const endHour = 19   // Bitiş saati
```

### Yeni Berber Ekleme

Supabase Dashboard > Table Editor > barbers tablosundan ekleyin.

### Yeni Hizmet Ekleme

Supabase Dashboard > Table Editor > services tablosundan ekleyin.

## 🐛 Sorun Giderme

Sorunlarla karşılaşırsanız [KURULUM.md](./KURULUM.md) dosyasındaki "Sorun Giderme" bölümüne bakın.

## 📝 Lisans

Bu proje eğitim amaçlı oluşturulmuştur.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Pull request göndermekten çekinmeyin.

---

**Not**: Uygulamayı çalıştırmadan önce Supabase veritabanını kurduğunuzdan ve `.env` dosyasını yapılandırdığınızdan emin olun.
