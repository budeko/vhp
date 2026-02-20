# VHP Kurulum ve Kullanım Akışı

Bu belge, “panel indirilip kurulduktan sonra” ne olduğunu ve panel üzerinden nelerin yapılabileceğini özetler.

**Kurulumun adım adım nasıl yapılacağı ve kullanıcının (admin / son kullanıcı) ne yapacağı:** **[KURULUM-VE-KULLANIM.md](./KURULUM-VE-KULLANIM.md)** — tek sayfada toplu rehber.

---

## 1. Kurulum (tek seferlik)

Birisi projeyi indirir ve kurulumu başlatır:

```bash
./scripts/install.sh
```

**Installer sırayla sorar:**

1. **Panel domain** — Panelin erişileceği adres (örn. `panel.sirket.com`).
2. **Admin e-posta** — Sertifika bildirimleri ve iletişim için mail.
3. **Admin kullanıcı adı** — Panele ilk girişte kullanılacak kullanıcı adı.
4. **Admin şifre** — İki kez sorulur; eşleşmezse tekrar istenir.
5. **Kendi panel ve controller’ını mı kullanacaksın, yoksa benimkini mi?** — Benimkini = bu repodaki resmi image’lar (varsayılan).
5. **Hangi servisleri kullanacaksın? (Opsiyonel)** — Backup, Data, DNS, GitOps, Observability; her biri ayrı sorulur.

**Ardından:**

- Helm ile tüm bileşenler (core, cert, control, panel, policy + seçilen zonlar) deploy edilir.
- Panel ve controller **bu reponun içindedir** (`panel/` ve `controller/`). Herkes kendi panelini yazmaz; varsayılan olarak **bu repodaki resmi image’lar** kullanılır (`ghcr.io/vhp-platform/vhp-panel:latest` ve `vhp-controller:latest`). Image’ların nasıl build edilip yayınlanacağı için **`docs/IMAGE-BUILD.md`** ve **`scripts/build-images.sh`** kullanılabilir.
- Admin bilgileri bir Secret’ta saklanır; panel ilk açılışta bu hesapla admin kullanıcısını oluşturur (uygulama mantığı).

Kurulum bitince panel adresi: **https://&lt;panel-domain&gt;**

---

## 2. Panele giriş ve ilk kullanım

- **URL:** `https://<kurulumda verdiğiniz panel domain>`
- **Giriş:** Kurulumda verilen **admin kullanıcı adı** ve **admin şifre** ile yapılır.

Panel açıldıktan sonra (uygulama tarafında yapılacaklar):

- İlk girişte Secret’taki `VHP_ADMIN_USERNAME` / `VHP_ADMIN_PASSWORD` ile tek seferlik admin hesabı oluşturulur (veya mevcut admin ile giriş yapılır).
- Admin, panel üzerinden **yeni kullanıcılar** ekleyebilir.

---

## 3. Kullanıcı oluşturma ve namespace

- Admin, panelden **“Yeni kullanıcı”** (veya benzeri) ile kullanıcı ekler.
- Her kullanıcı için controller, otomatik olarak bir **namespace** açar (örn. `user-<kullanıcı_adı>`).
- Kullanıcı, kendi namespace’inde çalışır; quota ve politikalar (Kyverno, NetworkPolicy) bu namespace’e uygulanır.

---

## 4. Kullanıcı ayarları (panel üzerinden)

Her kullanıcı kendi alanında aşağıdakileri **panel üzerinden** yapabilir (hepsi isteğe bağlı):

| Özellik | Açıklama |
|--------|----------|
| **GitHub’dan site** | İsterse GitHub’daki bir repoyu kendi namespace’ine çekip site olarak deploy edebilir (controller/panel bu repo bilgisini alıp gerekli Job/Deployment’ı oluşturur). |
| **Mail** | Kendi mail/DNS zonuna ait ayarlar (SMTP, bildirim adresi vb.) panelden verilir; isterse **kapalı** tutulabilir. |
| **DNS** | DNS zonu / kayıt ayarları panelden yapılır; isterse **kapalı** tutulabilir. |
| **Diğer zonlar** | Backup, vb. zonlar kullanıcı bazında açılıp kapatılabilir (panel + controller ile yönetilir). |

Yani: Kullanıcı, kendi namespace’i ve zonları için **her şeyi panel üzerinden** yönetir; istemediği özellikleri kapalı tutabilir.

---

## 5. Özet akış

```
1. Proje indirilir
2. ./scripts/install.sh çalıştırılır
   → Panel domain, mail, admin kullanıcı adı, şifre (x2) sorulur
   → Kurulum başlar, her şey iner
   → Panel ve controller image’ları sisteme çekilir ve çalışır
3. https://<panel-domain> açılır
   → Admin kullanıcı adı + şifre ile giriş
4. Panel üzerinden yeni kullanıcılar oluşturulur
   → Her kullanıcıya otomatik namespace (user-<ad>)
5. Her kullanıcı kendi panelinden:
   → İsterse GitHub’dan site çeker
   → Mail ve DNS ayarlarını açar/kapatır
   → Diğer ayarları panel üzerinden yapar; isterse kapalı tutar
```

---

## 6. Kurulum nasıl akıyor (adım adım)

Kurulum tek komutla başlar; script sizi yönlendirir:

| Adım | Ne olur |
|------|--------|
| **1** | `git clone <repo>` → `cd vhp` → `./scripts/install.sh` çalıştırılıyor. |
| **2** | Script **1/3:** Panel domain ve admin e-posta sorulur (Enter = varsayılan). |
| **3** | Script **2/3:** Admin kullanıcı adı ve şifre (iki kez) sorulur. |
| **4** | Script **3/3:** Hangi servisler kurulsun? Backup, Data, DNS, GitOps, Observability — her biri için Y/n. |
| **5** | Script, girilen değerlerle `.vhp-install-values.yaml` üretir; admin şifre ayrı dosyadan `--set-file` ile Helm'e verilir. |
| **6** | `helm upgrade --install vhp ./helm/vhp -f .vhp-install-values.yaml --set-file global.adminPassword=...` çalışır. |
| **7** | Helm sırayla namespace'leri ve kaynakları oluşturur: önce core/cert/policy, sonra control/panel, sonra seçilen zonlar (backup, data, dns, gitops, observability). |
| **8** | Panel ve controller, repodaki resmi image'lardan (`ghcr.io/vhp-platform/vhp-panel:latest`, `vhp-controller:latest`) çekilir ve deploy edilir. |
| **9** | Kurulum bitince panel adresi gösterilir: `https://<verdiğiniz-panel-domain>`. DNS'i bu domaine yönlendirmeniz gerekir. |
| **10** | Tarayıcıdan panele gidip admin kullanıcı adı ve şifre ile giriş yapılır. |

Panel ve controller image'ları kurulumda sorulmaz; her zaman bu repodaki image'lar kullanılır.

---

## 7. Mimari

VHP, Kubernetes üzerinde **katmanlı** çalışır: sistem (core), yönetim (controller + panel), opsiyonel zonlar.

### 7.1 Katmanlar ve namespace'ler

```
┌─────────────────────────────────────────────────────────────────────────┐
│  SİSTEM (system) — Her zaman açık                                        │
├─────────────────────────────────────────────────────────────────────────┤
│  vhp-core      → Ingress (Nginx), DNS/Mail gateway ConfigMap'leri,      │
│                  platform-config, isteğe bağlı mail-sender               │
│  vhp-cert      → Let's Encrypt (ClusterIssuer), TLS sertifikaları        │
│  vhp-policy    → Kyverno (ingress class zorunlu, LB/NodePort yasak),     │
│                  ResourceQuota, LimitRange, NetworkPolicy                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  YÖNETİM (management) — Her zaman açık                                   │
├─────────────────────────────────────────────────────────────────────────┤
│  vhp-control   → VHP Controller (kullanıcı namespace'leri, zonlar, API) │
│  vhp-panel     → Panel (web arayüzü), Certificate (TLS), Ingress        │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  ZONLAR (zones) — Kurulumda seçilir                                       │
├─────────────────────────────────────────────────────────────────────────┤
│  vhp-backup        → MinIO (S3 uyumlu yedekleme)                         │
│  vhp-data          → PostgreSQL                                          │
│  vhp-dns           → DNS yönetimi                                        │
│  vhp-gitops        → Flux (Git repo'dan senkron)                         │
│  vhp-observability → Prometheus, Loki, Grafana                           │
│  vhp-build         → Kaniko (cluster içi image build)                    │
│  vhp-cron          → CronJob'lar (backup cleanup, cert check, job temizlik)│
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  KULLANICI NAMESPACE'LERİ — Controller tarafından açılır                 │
├─────────────────────────────────────────────────────────────────────────┤
│  user-<ad>    → Her kullanıcıya bir namespace; RBAC, quota, policy       │
│                 şablonları vhp-control'daki ConfigMap'lerden uygulanır  │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Trafik ve erişim

- **Giriş noktası:** Tüm HTTP/HTTPS trafiği `vhp-core` içindeki **Nginx Ingress** ile gelir; IngressClass `vhp-nginx`.
- **Panel:** `vhp-panel` namespace'inde çalışır; kendi Certificate (Let's Encrypt) ve Ingress'i vardır; host = `global.panelHost`.
- **Kullanıcı uygulamaları:** Kullanıcı namespace'lerindeki Ingress'ler de `vhp-nginx` kullanmak zorunda (Kyverno policy).

### 7.3 Özet tablo

| Ne | Nerede |
|----|--------|
| Trafik girişi, gateway'ler | vhp-core |
| TLS sertifikaları | vhp-cert |
| Güvenlik kuralları (Kyverno) | vhp-policy |
| Platform API (namespace, zonlar) | vhp-control (controller) |
| Web arayüzü | vhp-panel |
| Yedek, DB, DNS, GitOps, izleme, build, cron | vhp-backup, vhp-data, vhp-dns, vhp-gitops, vhp-observability, vhp-build, vhp-cron |
| Kullanıcı iş yükleri | user-&lt;ad&gt; (controller ile oluşturulur) |

Detaylı şablon listesi için **`helm/vhp/FILES.md`** dosyasına bakın.

---

## 8. Ingress (dışarıya açma): Nginx — Traefik yok

Dışarıya servis açmak için **Nginx** kullanılıyor; **Traefik kullanılmıyor**.

| Ne | Detay |
|----|--------|
| **Controller** | Kubernetes resmi **ingress-nginx** controller (`registry.k8s.io/ingress-nginx/controller:v1.11.0`). |
| **IngressClass** | `vhp-nginx` (varsayılan class; Kyverno policy ile tüm Ingress'lerin bu class'ı kullanması zorunlu). |
| **Namespace** | `vhp-core`. |
| **Kaynaklar** | IngressClass `vhp-nginx`, ConfigMap `nginx-ingress-controller`, Deployment (replicas: 2), Service (LoadBalancer/NodePort cluster'a göre), ServiceAccount + ClusterRole/ClusterRoleBinding. |
| **values** | `core.ingress.replicas`, `core.ingress.image`. |

Panel ve kullanıcı uygulamaları, `ingressClassName: vhp-nginx` ile Ingress tanımlar; trafik bu Nginx controller'dan geçer. TLS, cert-manager + Let's Encrypt ile `vhp-cert` namespace'inde yönetilir.

---

## 9. Mail servisi (detay)

Mail, **harici SMTP** + isteğe bağlı **cluster içi mail-sender** ile çalışır. Tümü **vhp-core** namespace'inde.

### 9.1 Mail gateway config (her zaman)

| Ne | Nerede | Açıklama |
|----|--------|----------|
| **ConfigMap** | `vhp-core` → `mail-gateway-config` | SMTP ve webhook ayarları (uygulamalar/controller bu ConfigMap'i okuyup mail gönderebilir). |

**ConfigMap alanları (values: `core.mail`):**

| Alan | values anahtarı | Açıklama |
|------|------------------|----------|
| smtp-host | `core.mail.smtpHost` | Harici SMTP sunucusu (örn. `smtp.gmail.com`). Boş bırakılırsa mail gönderimi yapılmaz. |
| smtp-port | `core.mail.smtpPort` | SMTP portu (varsayılan `587`). |
| smtp-from | `core.mail.smtpFrom` | Gönderen adresi (örn. `noreply@example.com`). |
| smtp-tls | `core.mail.smtpTls` | TLS kullanılsın mı (varsayılan `true`). |
| webhook-url | `core.mail.webhookUrl` | İsteğe bağlı webhook URL (bildirimler için). |

Bu ConfigMap sadece **yapılandırma** sağlar; gerçek SMTP bağlantısı uygulamaların (panel, controller vb.) bu değerleri kullanarak harici SMTP'ye bağlanmasıyla yapılır. Kurulumda installer şu an mail (smtpHost, smtpFrom vb.) sormuyor; isterseniz values'ı elle veya `helm upgrade -f` ile güncelleyebilirsiniz.

### 9.2 Opsiyonel: mail-sender (cluster içi relay)

| Ne | Nerede | Açıklama |
|----|--------|----------|
| **Deployment + Service** | `vhp-core` → `mail-sender` | Sadece `core.mail.deploySender: true` ise oluşturulur. |

- **Deployment:** `mail-sender` — Pod'lar `mail-gateway-config` ConfigMap'ini env olarak alır. Varsayılan image `alpine:latest` (sadece placeholder; sürekli uyuyan bir container). Gerçek mail göndermek için `core.mail.senderImage` ile SMTP relay çalıştıran bir image (örn. msmtp veya başka bir relay) verilebilir.
- **Service:** `mail-sender`, port `8025` (isim: smtp). Diğer pod'lar bu Service üzerinden cluster içi bir SMTP relay'e bağlanabilir.

Özet: Mail **ayarları** `vhp-core` → `mail-gateway-config` ConfigMap'inde; **gönderim** ya doğrudan harici SMTP (uygulama bu config'i okuyup kullanır) ya da `deploySender: true` ile açılan `mail-sender` Service'i (ve sizin vereceğiniz relay image) ile yapılır.

---

## 10. Portlar, internete açılan yerler, GitHub/SSH

### 10.1 Portlar (özet)

| Bileşen | Port | Tip | İnternete açık mı? |
|--------|------|-----|---------------------|
| **Nginx Ingress** (vhp-core) | **80**, **443** | LoadBalancer | **Evet** — tek giriş noktası |
| **Mail (mail-sender)** (vhp-core) | **8025** (smtp) | ClusterIP | Hayır; sadece cluster içi |
| **Harici SMTP** (config’teki smtpPort) | **587** (varsayılan) | — | Cluster’dan **dışarı çıkış** (egress); cluster’a gelen değil |
| **DNS (dns-manager)** (vhp-dns) | **8080** (http) | ClusterIP | Hayır; sadece cluster içi (API/placeholder) |
| Panel (vhp-panel) | 3000 | ClusterIP | Hayır; Nginx Ingress üzerinden 80/443 ile erişilir |
| Controller (vhp-control) | 8080 | ClusterIP | Hayır; sadece cluster içi |
| PostgreSQL (vhp-data) | 5432 | ClusterIP | Hayır |
| MinIO (vhp-backup) | 9000, 9001 | ClusterIP | Hayır |

- **Mail:** Config’teki `smtpPort` (587), uygulamanın **dışarıdaki** SMTP sunucusuna bağlanırken kullandığı port. Cluster’da dinlenen tek mail portu: opsiyonel `mail-sender` Service **8025** (ClusterIP, internete açılmaz).
- **DNS:** `dns-manager` şu an placeholder (defaultbackend); **8080** HTTP. Gerçek DNS sunucusu (port 53) chart’ta yok; ileride eklense bile 53’ü internete açmak ayrı bir karar (genelde Ingress/HTTP üzerinden API ile yönetilir).

### 10.2 Mail nasıl çalışıyor? (port açmadan)

Mail **göndermek** için cluster'da dinleyen bir portu internete açmanız gerekmez. Panel/controller, ConfigMap'teki `smtpHost` ve `smtpPort` (örn. `smtp.gmail.com:587`) ile **cluster'dan dışarı çıkış (egress)** yapar — yani bağlantıyı **biz** başlatırız, internetten bize gelen değil. Harici SMTP sunucusu (Gmail, SendGrid, şirket sunucusu vb.) bu çıkış bağlantısını kabul eder, mail gider. Özet: **Gelen** trafik için port açmıyoruz; **giden** trafik (outbound) yeterli. Bu yüzden "mail dışarı açılmaz" = cluster'da 25/587 dinleyen bir servisi internete açmıyoruz; mail yine de çalışır çünkü uygulama harici SMTP'ye **çıkış** yapıyor. `smtpHost` (ve gerekirse kullanıcı/şifre Secret'ı) doğru verildiği sürece panel/controller mail gönderebilir.

### 10.3 Nereden internete açılıyor?

Sadece **Nginx Ingress Controller** servisi dış dünyaya açılır:

- **Service:** `vhp-core` → `nginx-ingress-controller`
- **Tip:** `LoadBalancer`
- **Portlar:** **80** (HTTP), **443** (HTTPS)

Cloud’da (AWS, GCP, Azure vb.) bu LoadBalancer’a bir public IP atanır; DNS’te panel ve uygulama domain’lerini bu IP’ye (veya CNAME) yönlendirirsiniz. Bare metal’de LoadBalancer için MetalLB veya NodePort kullanılır.

Akış: İnternet → **80/443 (Nginx LoadBalancer)** → Nginx Ingress kurallarına göre → Panel veya kullanıcı uygulaması (ClusterIP Service’lere yönlenir). Mail (8025) ve DNS (8080) **hiçbir zaman** doğrudan internete açılmaz; sadece cluster içinden erişilir.

### 10.4 GitHub bağlantısı (GitOps / clone)

**Flux GitOps (vhp-gitops):**

- Repo adresi `gitops.flux.repoUrl` (örn. `https://github.com/org/repo`) ve `gitops.flux.branch` (örn. `main`) ile verilir.
- Flux, cluster **içinden** GitHub’a **çıkış (egress)** yapar: **HTTPS** ile `github.com:443`. Yani cluster’da GitHub için **açılan bir port yok**; pod’lar dışarı çıkıp GitHub’a bağlanır.
- Varsayılan kullanım **HTTPS** clone. Public repo ise ek kimlik yok; private repo ise Flux’ta **token** veya **deploy key** tanımlanır (bu chart’ta GitRepository için secret alanı var; token/deploy key’i siz Secret olarak verirsiniz).

**SSH ile GitHub (git over SSH):**

- Chart’ta şu an Flux için **SSH deploy key** tanımlı değil. İsterseniz Flux’un GitRepository spec’ine `secretRef` ekleyip, içinde SSH private key olan bir Secret referansı verirsiniz; Flux o zaman **SSH** ile clone eder (cluster’dan `github.com:22` **çıkış**).
- Yine cluster’da **22 numaralı port açılmaz**; sadece cluster’dan GitHub’a 22’ye giden çıkış trafiği olur.

**Özet:** GitHub’a bağlantı **hep çıkış (egress)**:
- **HTTPS:** cluster → `github.com:443`
- **SSH:** cluster → `github.com:22` (Flux’ta SSH key Secret ile)

Gelen (internetten cluster’a) GitHub webhook vb. kullanacaksanız, bu **yine Ingress (80/443)** üzerinden bir endpoint açar; ayrı port gerekmez.

---

## 11. Cluster dışına çıkış istemiyorum (hacklenirsem sadece cluster gitsin)

Cluster'dan internete çıkış (egress) kapatılırsa veya çok kısıtlı tutulursa, saldırgan cluster'ı ele geçirse bile dışarıdaki sunucularınıza veya internete pivot atamaz; zarar cluster ile sınırlı kalır.

### 11.1 Nasıl kısıtlanır?

- **Kubernetes NetworkPolicy:** Namespace bazında `Egress` kuralları ile varsayılanı **tüm egress'i reddet**, sonra sadece gerekli hedeflere (IP/CIDR + port) izin ver. Örn. `vhp-core` için egress: yok; `vhp-gitops` için sadece `github.com` IP aralıkları 443.
- **Cloud / firewall:** Cluster node'larının veya VPC'nin çıkış trafiğini firewall'da engelleyin veya sadece belirli hedeflere (Let's Encrypt, container registry) izin verin.
- **Bare metal:** Node'larda iptables/nftables veya ayrı bir güvenlik duvarı ile cluster'dan çıkışı kapatın veya beyaz listeye alın.

Böylece "sadece cluster gitsin" hedefi tutar: cluster ele geçse bile dışarı çıkış yok (veya çok az).

### 11.2 Egress kapatılırsa ne bozulur?

| Bağımlılık | Egress gerekir mi? | Ne olur egress yoksa? |
|------------|--------------------|------------------------|
| **Mail (harici SMTP)** | Evet (cluster → smtp.xxx:587) | Mail gönderilemez. |
| **Flux / GitHub** | Evet (cluster → github.com:443 veya :22) | Repo çekilemez, GitOps durur. |
| **cert-manager (Let's Encrypt)** | Evet (cluster → acme-v02.api.letsencrypt.org) | Otomatik TLS sertifikası alınamaz. |
| **Image pull (harici registry)** | Evet (cluster → registry:443) | Yeni image'lar çekilemez. |
| **Panel/controller** | Harici API yoksa hayır | Sadece cluster içi çalışır. |

Yani egress tamamen kapatılırsa: harici mail çalışmaz, Flux/GitHub çalışmaz, Let's Encrypt çalışmaz, harici registry'den image çekilemez.

### 11.3 Seçenekler

- **Tam kilit (hiç egress yok):**  
  - Mail: Harici SMTP yok; bildirimleri sadece cluster içinde tutun (DB, panel içi mesaj) veya mail-sender'ı sadece cluster içi kullanın.  
  - GitOps: GitHub yerine cluster içi Git mirror (örn. Gitea); mirror'ı başka bir makineden güncellersiniz (o makine çıkış yapabilir).  
  - Sertifika: Let's Encrypt yerine elle verilen veya internal CA sertifikası.  
  - Image: Tüm image'lar önceden node'a çekilmiş veya internal registry (cluster içi) kullanın.

- **Sadece gerekli yerlere izin (beyaz liste):**  
  Egress'i default-deny yapıp sadece şu hedeflere izin verirseniz hem "sadece cluster gitsin" hem de bazı dış servisler çalışır; saldırgan yine sadece bu adreslere çıkış yapabilir, tüm ağınıza değil:  
  - Let's Encrypt ACME (sertifika).  
  - GitHub (veya sadece internal Git).  
  - Mail için tek bir SMTP sunucusu IP'si (isteğe bağlı).  
  - Container registry (ghcr.io vb.) — gerekirse.

Özet: **Cluster dışına çıkmak istemiyorum, hacklenirsem sadece cluster gitsin** derseniz, egress'i NetworkPolicy veya firewall ile kapatın / sınırlayın; mail, GitHub, cert-manager ve image pull için ya tamamen iç çözümler kullanın ya da sadece gerekli hedeflere çıkış izni verin.

---

## Notlar

- **Controller ve panel uygulaması:** Yukarıdaki “kullanıcı oluşturma”, “GitHub’dan site çekme”, “mail/DNS aç/kapa” davranışları **panel ve controller** kodunda (API + UI) implement edilir; Helm chart sadece Secret, env ve altyapıyı sağlar.
- **Secret:** Admin şifre, installer tarafından `--set-file` ile verilir; values dosyasında saklanmaz. Geçici şifre dosyası kurulum sonrası silinir.
