-- Employees tablosuna photo_url sütunu ekle
ALTER TABLE employees ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Örnek fotoğraf URL'leri ekleyelim (placeholder avatarlar)
-- Gerçek kullanımda bu URL'ler gerçek fotoğraf linklerine güncellenecek
UPDATE employees SET photo_url = 'https://ui-avatars.com/api/?name=' || REPLACE(name, ' ', '+') || '&background=6366f1&color=fff&size=200' WHERE photo_url IS NULL;
