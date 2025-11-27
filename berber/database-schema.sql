-- Berber Randevu Sistemi Veritabanı Şeması (ÇOKLU ÇALIŞAN)
-- Supabase SQL Editor'de çalıştırın

-- 1. Çalışanlar Tablosu
CREATE TABLE IF NOT EXISTS employees (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  specialty VARCHAR(100), -- Uzmanlık alanı (Saç, Sakal, vb.)
  phone VARCHAR(20),
  email VARCHAR(255),
  work_start_time TIME DEFAULT '09:00',
  work_end_time TIME DEFAULT '19:00',
  bio TEXT, -- Kısa açıklama/tanıtım
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Hizmetler Tablosu
CREATE TABLE IF NOT EXISTS services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  duration INTEGER NOT NULL, -- dakika cinsinden
  price DECIMAL(10, 2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2.5. Çalışan-Hizmet İlişki Tablosu (Hangi berber hangi hizmetleri yapıyor)
CREATE TABLE IF NOT EXISTS employee_services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(employee_id, service_id)
);

-- 3. Randevular Tablosu (Müşteri bilgileri direkt buraya)
CREATE TABLE IF NOT EXISTS appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  customer_name VARCHAR(100) NOT NULL,
  customer_phone VARCHAR(20) NOT NULL,
  customer_email VARCHAR(100),
  status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, completed, cancelled
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Aynı çalışan, aynı tarih ve saatte birden fazla randevu alamaz
  UNIQUE(employee_id, appointment_date, appointment_time)
);

-- 4. İndeksler (Performans için)
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_employee ON appointments(employee_id);
CREATE INDEX IF NOT EXISTS idx_appointments_phone ON appointments(customer_phone);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

-- 5. Row Level Security (RLS) Politikaları
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "Herkes çalışanları görebilir" ON employees FOR SELECT USING (true);
CREATE POLICY "Herkes hizmetleri görebilir" ON services FOR SELECT USING (true);
CREATE POLICY "Herkes employee_services görebilir" ON employee_services FOR SELECT USING (true);
CREATE POLICY "Herkes randevuları görebilir" ON appointments FOR SELECT USING (true);

-- Herkes randevu oluşturabilir
CREATE POLICY "Herkes randevu oluşturabilir" ON appointments FOR INSERT WITH CHECK (true);

-- Herkes randevu güncelleyebilir
CREATE POLICY "Herkes randevu güncelleyebilir" ON appointments FOR UPDATE USING (true);

-- 6. Örnek Veriler

-- Örnek Çalışanlar
INSERT INTO employees (name, specialty) VALUES
('Ahmet Yılmaz', 'Saç Kesimi & Sakal'),
('Mehmet Demir', 'Saç Kesimi'),
('Ali Kaya', 'Sakal & Boya');

-- Örnek Hizmetler
INSERT INTO services (name, duration, price, description) VALUES
('Saç Kesimi', 30, 150.00, 'Klasik erkek saç kesimi'),
('Sakal Tıraşı', 20, 100.00, 'Ustura ile sakal tıraşı'),
('Saç + Sakal', 45, 200.00, 'Saç kesimi ve sakal tıraşı paketi'),
('Çocuk Saç Kesimi', 20, 100.00, '0-12 yaş çocuk saç kesimi'),
('Boya', 60, 300.00, 'Saç boyama işlemi');

-- 7. Trigger: updated_at otomatik güncellemesi
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. Admin Kullanıcılar Tablosu
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  role VARCHAR(50) DEFAULT 'admin', -- admin, super_admin, barber
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin users için RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Sadece authenticated kullanıcılar admin_users'ı görebilir
CREATE POLICY "Authenticated users can view admins" ON admin_users
  FOR SELECT USING (auth.role() = 'authenticated');

-- Sadece kendi kaydını güncelleyebilir
CREATE POLICY "Users can update own record" ON admin_users
  FOR UPDATE USING (auth.uid() = auth_id);

-- 9. Yardımcı Fonksiyonlar

-- Belirli bir çalışan ve tarihe ait müsait saatleri getiren fonksiyon
CREATE OR REPLACE FUNCTION get_available_time_slots(
  p_employee_id UUID,
  p_date DATE,
  p_service_duration INTEGER DEFAULT 30
)
RETURNS TABLE (
  time_slot TIME,
  is_available BOOLEAN
) AS $$
DECLARE
  v_start_time TIME := '09:00';
  v_end_time TIME := '19:00';
  v_current_time TIME;
  v_slot_interval INTERVAL := (p_service_duration || ' minutes')::INTERVAL;
BEGIN
  v_current_time := v_start_time;

  WHILE v_current_time < v_end_time LOOP
    RETURN QUERY
    SELECT
      v_current_time,
      NOT EXISTS (
        SELECT 1 FROM appointments
        WHERE employee_id = p_employee_id
        AND appointment_date = p_date
        AND appointment_time = v_current_time
        AND status != 'cancelled'
      ) as is_available;

    v_current_time := v_current_time + v_slot_interval;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
