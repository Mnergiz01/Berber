-- Çalışma günleri tablosu (Çalışanların hangi günlerde çalıştığını belirler)
CREATE TABLE IF NOT EXISTS employee_working_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Pazar, 1=Pazartesi, ..., 6=Cumartesi
  start_time TIME NOT NULL DEFAULT '09:00',
  end_time TIME NOT NULL DEFAULT '19:00',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(employee_id, day_of_week)
);

-- İzin/tatil günleri tablosu (Çalışanların özel izinli olduğu günler)
CREATE TABLE IF NOT EXISTS employee_time_off (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT,
  is_approved BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CHECK (end_date >= start_date)
);

-- Index'ler (performans için)
CREATE INDEX IF NOT EXISTS idx_working_days_employee ON employee_working_days(employee_id);
CREATE INDEX IF NOT EXISTS idx_working_days_active ON employee_working_days(is_active);
CREATE INDEX IF NOT EXISTS idx_time_off_employee ON employee_time_off(employee_id);
CREATE INDEX IF NOT EXISTS idx_time_off_dates ON employee_time_off(start_date, end_date);

-- Varsayılan çalışma günleri ekle (tüm çalışanlar için Pazartesi-Cumartesi)
-- Mevcut çalışanlar için varsayılan çalışma günleri oluştur
INSERT INTO employee_working_days (employee_id, day_of_week, start_time, end_time, is_active)
SELECT
  e.id,
  d.day_of_week,
  COALESCE(e.work_start_time, '09:00'::TIME),
  COALESCE(e.work_end_time, '19:00'::TIME),
  true
FROM employees e
CROSS JOIN (
  SELECT 1 AS day_of_week  -- Pazartesi
  UNION ALL SELECT 2       -- Salı
  UNION ALL SELECT 3       -- Çarşamba
  UNION ALL SELECT 4       -- Perşembe
  UNION ALL SELECT 5       -- Cuma
  UNION ALL SELECT 6       -- Cumartesi
) d
WHERE e.is_active = true
ON CONFLICT (employee_id, day_of_week) DO NOTHING;

-- RLS (Row Level Security) politikaları
ALTER TABLE employee_working_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_time_off ENABLE ROW LEVEL SECURITY;

-- Herkes okuyabilir
CREATE POLICY "Herkes çalışma günlerini okuyabilir" ON employee_working_days
  FOR SELECT USING (true);

CREATE POLICY "Herkes izin günlerini okuyabilir" ON employee_time_off
  FOR SELECT USING (true);

-- Sadece admin yazabilir (şimdilik herkese izin ver, sonra düzenlenebilir)
CREATE POLICY "Herkes çalışma günleri ekleyebilir" ON employee_working_days
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Herkes çalışma günlerini güncelleyebilir" ON employee_working_days
  FOR UPDATE USING (true);

CREATE POLICY "Herkes çalışma günlerini silebilir" ON employee_working_days
  FOR DELETE USING (true);

CREATE POLICY "Herkes izin günleri ekleyebilir" ON employee_time_off
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Herkes izin günlerini güncelleyebilir" ON employee_time_off
  FOR UPDATE USING (true);

CREATE POLICY "Herkes izin günlerini silebilir" ON employee_time_off
  FOR DELETE USING (true);
