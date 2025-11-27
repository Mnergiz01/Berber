-- İLK SÜPER ADMİN KULLANICISI OLUŞTURMA
-- Bu scripti Supabase SQL Editor'de çalıştırın

-- 1. ÖNCE Supabase Dashboard > Authentication > Users kısmından manuel olarak bir kullanıcı oluşturun:
--    Email: admin@admin.com
--    Password: admin123
--    Email Confirm: AÇIK (E-posta doğrulamasını atlayın)

-- 2. Ardından aşağıdaki sorguyu çalıştırın (YOUR_AUTH_ID'yi değiştirin):

-- Kullanıcının auth_id'sini bulma (oluşturduğunuz kullanıcının email'i ile):
-- SELECT id FROM auth.users WHERE email = 'admin@admin.com';

-- Admin kullanıcısını admin_users tablosuna ekleyin:
INSERT INTO admin_users (auth_id, full_name, email, role, is_active)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'admin@admin.com'),
  'Admin',
  'admin@admin.com',
  'super_admin',
  true
);

-- Kontrol: Admin kullanıcısının oluştuğunu doğrulayın
SELECT * FROM admin_users WHERE email = 'admin@admin.com';

-- ✅ TAMAMLANDI!
-- Artık şu bilgilerle giriş yapabilirsiniz:
-- Email: admin@admin.com
-- Password: admin123
