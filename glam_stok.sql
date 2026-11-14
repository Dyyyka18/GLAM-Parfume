-- ============================================================
-- Basis data glam_stok — Sistem Pengelolaan Stok Bahan Produksi
-- Toko GLAM Parfume (SDD Kelompok 1, Bab 4 & 6)
-- MySQL 8.0 / MariaDB 10.4+ (InnoDB). Login awal: admin / glam123
-- ============================================================
DROP DATABASE IF EXISTS glam_stok;
CREATE DATABASE glam_stok CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE glam_stok;

-- Tabel 2: users
CREATE TABLE users (
  id_user        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama           VARCHAR(100) NOT NULL,
  username       VARCHAR(50)  NOT NULL,
  password       VARCHAR(255) NOT NULL,
  remember_token VARCHAR(100) NULL,
  created_at     TIMESTAMP NULL DEFAULT NULL,
  updated_at     TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id_user),
  UNIQUE KEY uk_users_username (username)
) ENGINE=InnoDB;

-- Tabel 3: kategori
CREATE TABLE kategori (
  id_kategori   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama_kategori VARCHAR(100) NOT NULL,
  created_at    TIMESTAMP NULL DEFAULT NULL,
  updated_at    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id_kategori),
  UNIQUE KEY uk_kategori_nama (nama_kategori)
) ENGINE=InnoDB;

-- Tabel 4: barang (stok_awal = S0, stok_minimum = M, stok_saat_ini = S)
CREATE TABLE barang (
  id_barang     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_kategori   INT UNSIGNED NOT NULL,
  nama_barang   VARCHAR(150) NOT NULL,
  satuan        VARCHAR(30)  NOT NULL,
  stok_awal     DECIMAL(12,2) NOT NULL,
  stok_minimum  DECIMAL(12,2) NOT NULL,
  stok_saat_ini DECIMAL(12,2) NOT NULL,
  keterangan    TEXT NULL,
  created_at    TIMESTAMP NULL DEFAULT NULL,
  updated_at    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id_barang),
  KEY idx_barang_kategori (id_kategori),
  KEY idx_barang_nama (nama_barang),
  CONSTRAINT fk_barang_kategori FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_barang_nonneg CHECK (stok_awal >= 0 AND stok_minimum >= 0 AND stok_saat_ini >= 0)
) ENGINE=InnoDB;

-- Tabel 5: stok_masuk
CREATE TABLE stok_masuk (
  id_stok_masuk INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_barang     INT UNSIGNED NOT NULL,
  id_user       INT UNSIGNED NOT NULL,
  tanggal       DATE NOT NULL,
  jumlah        DECIMAL(12,2) NOT NULL,
  supplier      VARCHAR(150) NULL,
  keterangan    TEXT NULL,
  created_at    TIMESTAMP NULL DEFAULT NULL,
  updated_at    TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id_stok_masuk),
  KEY idx_masuk_barang (id_barang),
  KEY idx_masuk_user (id_user),
  KEY idx_masuk_tanggal (tanggal),
  CONSTRAINT fk_masuk_barang FOREIGN KEY (id_barang) REFERENCES barang (id_barang) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_masuk_user   FOREIGN KEY (id_user)   REFERENCES users (id_user)    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_masuk_jumlah CHECK (jumlah > 0)
) ENGINE=InnoDB;

-- Tabel 6: stok_keluar
CREATE TABLE stok_keluar (
  id_stok_keluar INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_barang      INT UNSIGNED NOT NULL,
  id_user        INT UNSIGNED NOT NULL,
  tanggal        DATE NOT NULL,
  jumlah         DECIMAL(12,2) NOT NULL,
  keterangan     TEXT NULL,
  created_at     TIMESTAMP NULL DEFAULT NULL,
  updated_at     TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id_stok_keluar),
  KEY idx_keluar_barang (id_barang),
  KEY idx_keluar_user (id_user),
  KEY idx_keluar_tanggal (tanggal),
  CONSTRAINT fk_keluar_barang FOREIGN KEY (id_barang) REFERENCES barang (id_barang) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_keluar_user   FOREIGN KEY (id_user)   REFERENCES users (id_user)    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_keluar_jumlah CHECK (jumlah > 0)
) ENGINE=InnoDB;

-- ---------------- Data awal ----------------
INSERT INTO users (nama, username, password, created_at, updated_at)
VALUES ('Pemilik Toko', 'admin', '$2y$10$NZCPCVMWlRmkQWkRwPQoAOrAUCHqJ7V1iNci4MRINkJ1R6jYrCFxu', NOW(), NOW());   -- bcrypt (kompatibel Laravel), password: glam123

INSERT INTO kategori (nama_kategori, created_at, updated_at) VALUES
('Bahan Baku',NOW(),NOW()), ('Kemasan',NOW(),NOW()), ('Perlengkapan',NOW(),NOW());

INSERT INTO barang (id_kategori, nama_barang, satuan, stok_awal, stok_minimum, stok_saat_ini, keterangan, created_at, updated_at) VALUES
(1,'Fragrance Oil','ml',750,500,1250,NULL,NOW(),NOW()),
(1,'Fixative','ml',1050,300,800,NULL,NOW(),NOW()),
(2,'Spray Pump','pcs',85,100,85,NULL,NOW(),NOW()),
(2,'Box Packaging','pcs',240,80,240,NULL,NOW(),NOW()),
(1,'Distilled Water','ml',4200,1000,4200,NULL,NOW(),NOW()),
(3,'Gelas Beaker','pcs',12,5,12,NULL,NOW(),NOW()),
(3,'Botol Mixing','pcs',4,6,4,NULL,NOW(),NOW());

INSERT INTO stok_masuk (id_barang, id_user, tanggal, jumlah, supplier, keterangan, created_at, updated_at)
VALUES (1,1,CURDATE(),500,NULL,'Stok awal',NOW(),NOW());
INSERT INTO stok_keluar (id_barang, id_user, tanggal, jumlah, keterangan, created_at, updated_at)
VALUES (2,1,CURDATE(),250,'Produksi batch 01',NOW(),NOW());

-- ---------------- View: Rekap Stok (UI-09) & stok menipis (UI-02) ----------------
-- S = S0 + SUM(masuk) - SUM(keluar); status Menipis bila S <= M
CREATE VIEW v_rekap_stok AS
SELECT b.id_barang, CONCAT('BRG-', LPAD(b.id_barang,3,'0')) AS kode, b.nama_barang, k.nama_kategori, b.satuan,
       b.stok_awal,
       COALESCE((SELECT SUM(m.jumlah) FROM stok_masuk  m WHERE m.id_barang=b.id_barang),0) AS total_masuk,
       COALESCE((SELECT SUM(o.jumlah) FROM stok_keluar o WHERE o.id_barang=b.id_barang),0) AS total_keluar,
       b.stok_awal
         + COALESCE((SELECT SUM(m.jumlah) FROM stok_masuk  m WHERE m.id_barang=b.id_barang),0)
         - COALESCE((SELECT SUM(o.jumlah) FROM stok_keluar o WHERE o.id_barang=b.id_barang),0) AS stok_akhir,
       b.stok_minimum, b.stok_saat_ini,
       IF(b.stok_saat_ini <= b.stok_minimum,'Menipis','Aman') AS status
FROM barang b JOIN kategori k ON k.id_kategori=b.id_kategori;

CREATE VIEW v_stok_menipis AS SELECT * FROM v_rekap_stok WHERE status='Menipis';

-- ---------------- Service Stok (FR-06, BR-03): transaksi + validasi ----------------
DELIMITER //
CREATE PROCEDURE sp_stok_masuk(IN p_barang INT UNSIGNED, IN p_user INT UNSIGNED, IN p_tanggal DATE,
                               IN p_jumlah DECIMAL(12,2), IN p_supplier VARCHAR(150), IN p_ket TEXT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Jumlah harus lebih dari 0'; END IF;
  START TRANSACTION;
  IF NOT EXISTS (SELECT 1 FROM barang WHERE id_barang=p_barang FOR UPDATE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Barang tidak ditemukan';
  END IF;
  INSERT INTO stok_masuk (id_barang,id_user,tanggal,jumlah,supplier,keterangan,created_at,updated_at)
  VALUES (p_barang,p_user,p_tanggal,p_jumlah,p_supplier,p_ket,NOW(),NOW());
  UPDATE barang SET stok_saat_ini = stok_saat_ini + p_jumlah, updated_at=NOW() WHERE id_barang=p_barang;   -- S' = S + q
  COMMIT;
  SELECT stok_saat_ini, IF(stok_saat_ini<=stok_minimum,'Menipis','Aman') AS status FROM barang WHERE id_barang=p_barang;
END//

CREATE PROCEDURE sp_stok_keluar(IN p_barang INT UNSIGNED, IN p_user INT UNSIGNED, IN p_tanggal DATE,
                                IN p_jumlah DECIMAL(12,2), IN p_ket TEXT)
BEGIN
  DECLARE v_stok DECIMAL(12,2);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Jumlah harus lebih dari 0'; END IF;
  START TRANSACTION;
  SELECT stok_saat_ini INTO v_stok FROM barang WHERE id_barang=p_barang FOR UPDATE;
  IF v_stok IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Barang tidak ditemukan'; END IF;
  IF p_jumlah > v_stok THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Stok tidak mencukupi';   -- q > S ditolak
  END IF;
  INSERT INTO stok_keluar (id_barang,id_user,tanggal,jumlah,keterangan,created_at,updated_at)
  VALUES (p_barang,p_user,p_tanggal,p_jumlah,p_ket,NOW(),NOW());
  UPDATE barang SET stok_saat_ini = stok_saat_ini - p_jumlah, updated_at=NOW() WHERE id_barang=p_barang; -- S' = S - q
  COMMIT;
  SELECT stok_saat_ini, IF(stok_saat_ini<=stok_minimum,'Menipis','Aman') AS status FROM barang WHERE id_barang=p_barang;
END//
DELIMITER ;
