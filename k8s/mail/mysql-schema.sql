-- Mail system: virtual domains, users, aliases (Postfix/Dovecot)
CREATE DATABASE IF NOT EXISTS mail;
USE mail;

CREATE TABLE IF NOT EXISTS virtual_domains (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  customer_id VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_customer (customer_id),
  INDEX idx_name (name)
);

CREATE TABLE IF NOT EXISTS virtual_users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  domain_id INT NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  maildir VARCHAR(512) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE,
  INDEX idx_domain (domain_id),
  INDEX idx_email (email)
);

CREATE TABLE IF NOT EXISTS virtual_aliases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  domain_id INT NOT NULL,
  source VARCHAR(255) NOT NULL,
  destination TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE,
  INDEX idx_domain (domain_id),
  INDEX idx_source (source)
);

-- Optional: per-domain DKIM selector tracking (key material in K8s Secret)
CREATE TABLE IF NOT EXISTS dkim_selectors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  domain_id INT NOT NULL,
  selector VARCHAR(64) NOT NULL,
  secret_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY (domain_id, selector),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
);
