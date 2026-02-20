# VHP: Kurulum Nasıl Olur, Kullanıcı Ne Yapar?

Bu belge, **kurulumun tam olarak nasıl yapıldığını** ve **kullanıcının ne yapacağını** adım adım anlatır.

---

## Bölüm 1: Kurulum (Tek Seferlik)

Kurulumu yapan kişi (siz veya müşteri) aşağıdaki adımları izler.

### 1.1 Gereksinimler

- Kubernetes cluster (erişim: `kubectl` çalışıyor olmalı)
- Helm 3
- (İsteğe bağlı) cert-manager, Kyverno — cluster’da yoksa ayrıca kurulur

### 1.2 Repoyu almak

```bash
git clone https://github.com/<org>/vhp.git
cd vhp
```

Bu repoda panel ve controller da var; ayrıca bir şey indirmeye gerek yok.

### 1.3 Kurulum script’ini çalıştırmak

```bash
./scripts/install.sh
```

Script sırayla şunları sorar:

| Sıra | Soru | Açıklama | Örnek |
|------|-----|----------|--------|
| 1 | Panel domain | Panele hangi adresten girilecek | `panel.sirket.com` |
| 2 | Admin e-posta | Sertifika ve bildirimler için mail | `admin@sirket.com` |
| 3 | Admin kullanıcı adı | Panele ilk girişte kullanılacak kullanıcı | `admin` |
| 4 | Admin şifre | İki kez sorulur; eşleşmezse tekrar | **** |
| 5 | Kendi panel ve controller’ını mı kullanacaksın, yoksa benimkini mi? | Benimkini = bu repodaki resmi image’lar (varsayılan) | Enter = benimkini; istersen kendi image URL’lerini yazarsın |
| 5 | Hangi servisleri kullanacaksın? (Opsiyonel) | Backup, Data, DNS, GitOps, Observability — her biri ayrı sorulur | Y/n |

- Şifre ekranda görünmez; iki kez yazılır, eşleşmezse tekrar istenir.
- Panel ve controller **her zaman bu repodaki resmi image'lardan** kullanılır; kurulumda image sorusu sorulmaz.

### 1.4 Kurulumun arka planda yaptıkları

1. Girilen bilgilerle bir values dosyası üretilir (geçici).
2. `helm upgrade --install vhp ./helm/vhp ...` çalışır.
3. Kubernetes’e şunlar deploy edilir:
   - **Sistem:** vhp-core (ingress, gateways), vhp-cert (Let’s Encrypt), vhp-policy (Kyverno)
   - **Yönetim:** vhp-control (controller), vhp-panel (panel)
   - **Seçilen zonlar:** backup (MinIO), data (PostgreSQL), dns, gitops, observability vb.
4. Panel ve controller **bu repodaki resmi image’lardan** cluster’a çekilir ve çalışır.
5. Admin kullanıcı adı ve şifre bir Secret’a yazılır; panel ilk açılışta bu hesapla giriş sağlar.

Kurulum bitince çıktıda panel adresi ve release bilgisi görünür.

### 1.5 Kurulum sonrası (teknik)

- Panel adresi: **https://&lt;kurulumda yazdığınız panel domain&gt;**
- DNS: Bu domain’in cluster’daki ingress’e yönelmesi gerekir (A/CNAME kaydı veya hosts dosyası).
- İlk giriş: Kurulumda verdiğiniz **admin kullanıcı adı** ve **admin şifre** ile.

---

## Bölüm 2: Kullanıcı Ne Yapar?

Burada “kullanıcı” iki anlama gelebilir: **(A)** Sistemi kuran / panele ilk giren **admin**, **(B)** Admin’in panelden eklediği **son kullanıcılar**.

### 2.1 Admin (sistemi kuran / panele ilk giren)

1. Tarayıcıda **https://&lt;panel domain&gt;** adresine gider.
2. **Admin kullanıcı adı** ve **şifre** ile giriş yapar (kurulumda yazdığı).
3. Panel açıldıktan sonra:
   - **Yeni kullanıcı ekler** (isim, e-posta vb.).
   - Her kullanıcı için sistem otomatik bir **namespace** açar (örn. `user-ahmet`).
4. İsterse panel üzerinden zonları (backup, DNS, GitOps vb.) açar/kapatır veya ayarlar.

### 2.2 Son kullanıcı (admin’in eklediği)

Admin kendisine “kullanıcı” ekledikten sonra, o kullanıcı:

1. Panele giriş yapar (admin’in verdiği hesap bilgileriyle veya davet linkiyle — panel uygulamasının nasıl tasarlandığına bağlı).
2. Kendi **namespace’inde** sadece kendi kaynaklarını görür.
3. Panel üzerinden (uygulama tamamlandığında):
   - **GitHub’dan site çekebilir** — repo verir, sistem o namespace’e deploy eder.
   - **Mail ayarlarını** açar/kapatır veya düzenler.
   - **DNS ayarlarını** açar/kapatır veya düzenler.
   - İsterse bu özellikleri **kapalı** tutar; hepsi panelden yönetilir.

Yani: Kullanıcı kendi panelinden her şeyi yönetir; kendi namespace’i, GitHub site, mail, DNS hep panel üzerinden.

---

## Bölüm 3: Özet Akış

```
KURULUM (bir kez)
├── git clone vhp && cd vhp
├── ./scripts/install.sh
│   ├── Panel domain, mail, admin kullanıcı, şifre (x2)
│   └── Hangi servisleri kullanacaksın? (opsiyonel)
├── Helm ile her şey deploy edilir
└── Panel https://<panel-domain> üzerinden erişilir

ADMİN
├── Panele giriş (admin / şifre)
├── Yeni kullanıcılar ekler
└── Zonları/ayarları yönetir

KULLANICI (admin’in eklediği)
├── Panele giriş
├── Kendi namespace’inde çalışır
├── İsterse GitHub’dan site çeker
├── Mail/DNS ayarlarını açar/kapatır
└── Hepsi panel üzerinden
```

---

## Bölüm 4: Sık Sorulanlar

**Image’lar hazır mı?**  
Varsayılan image’lar (`ghcr.io/vhp-platform/vhp-panel:latest` vb.) sizin veya CI’ınızın bu repodan build edip registry’e push etmesi gerekir. İlk seferde `scripts/build-images.sh` veya CI/CD ile build edip push edin; sonra herkes kurulumda Enter’a basarak bu image’ları kullanır.

**Kullanıcı kendi panelini yazabilir mi?**  
Kurulumda image sorusunda farklı bir image yazarsa kendi panelini/controller’ını kullanabilir. Varsayılan ise bu repodaki resmi panel ve controller’dır; çoğu kullanıcı sadece varsayılanı kullanır.

**DNS / sertifika ne zaman hazır olur?**  
Panel domain’i için DNS’i sizin yönlendirmeniz gerekir. cert-manager cluster’da yüklüyse, ingress açıldıktan sonra Let’s Encrypt sertifikası otomatik alınır.

**Controller ve panel tam ne yapacak?**  
Chart ve installer altyapıyı (namespace, RBAC, zonlar, Secret’lar) hazırlar. “Kullanıcı ekleme”, “GitHub’dan site çekme”, “mail/DNS aç/kapa” gibi davranışlar **panel ve controller uygulama kodunda** (bu repodaki `panel/` ve `controller/` içinde) geliştirilir; Helm sadece bu uygulamaları çalıştırır ve gerekli ayarları verir.
