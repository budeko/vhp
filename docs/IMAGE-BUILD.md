# Panel ve Controller: Bu Repoda, Herkes Aynı Image'ı Kullanır

Panel ve controller **bu reponun içinde** yer alır (`panel/` ve `controller/`). Herkes kendi panel/controller’ını yazmak zorunda değildir; kurulumda **bu repodaki resmi image’lar** varsayılan olarak kullanılır.

---

## 1. Repo yapısı

```
vhp/
├── panel/           # Panel uygulaması (Node.js)
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── controller/      # Controller uygulaması (Go)
│   ├── Dockerfile
│   ├── go.mod
│   └── main.go
├── helm/
├── scripts/
└── ...
```

- **panel/** — VHP yönetim paneli (şu an minimal sunucu; gerçek UI ve API bu yapı üzerine eklenir).
- **controller/** — Kullanıcı namespace, RBAC, zon yönetimi (şu an minimal HTTP server; gerçek mantık bu yapı üzerine eklenir).

---

## 2. Image’lar nereden çekilir?

Varsayılan değerler:

- **Panel:** `ghcr.io/vhp-platform/vhp-panel:latest`
- **Controller:** `ghcr.io/vhp-platform/vhp-controller:latest`

Kurulumda (installer) bu varsayılanlar kullanılır; kullanıcı değiştirmezse **bu repodan üretilmiş image’lar** çekilir. Registry/org adını (örn. `vhp-platform`) kendi GitHub/GitLab org’unuza göre değiştirebilirsiniz.

---

## 3. Image’lar nasıl oluşturulur?

Bu repodaki `panel/` ve `controller/` ile image üretilir. Seçenekler:

### A) CI/CD (önerilen)

Bu repo için bir workflow tanımlayın; her push veya tag’te `panel/` ve `controller/` build edilip registry’e push edilsin. Böylece herkes aynı image’ları kullanır.

Örnek (GitHub Actions):

```yaml
# .github/workflows/build.yaml
name: Build Panel and Controller
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push panel
        uses: docker/build-push-action@v5
        with:
          context: ./panel
          push: true
          tags: ghcr.io/${{ github.repository_owner }}/vhp-panel:latest
      - name: Build and push controller
        uses: docker/build-push-action@v5
        with:
          context: ./controller
          push: true
          tags: ghcr.io/${{ github.repository_owner }}/vhp-controller:latest
```

`github.repository_owner` sizin org’unuz (örn. `vhp-platform`). values/installer’daki registry/org ile aynı olmalı.

### B) Lokal build (geliştirme veya kendi registry’niz)

Bu repodan image’ları kendiniz build edip kendi registry’inize push edebilirsiniz:

```bash
# Varsayılan: panel/ ve controller/ bu repo içinde, registry ghcr.io/vhp-platform
./scripts/build-images.sh
```

Gerekirse override:

```bash
export VHP_REGISTRY=ghcr.io/sizin-org
./scripts/build-images.sh
```

Çıktıdaki image URL’lerini kurulumda kullanın.

### C) Cluster’da Kaniko

Build zonu açıksa (`build.enabled: true`), Kaniko Job’ı bu repo’ya (veya fork’unuza) bakacak şekilde ayarlanabilir; build edilen image’lar registry’e push edilir ve aynı tag’ler kullanılır.

---

## 4. Özet

| Soru | Cevap |
|------|--------|
| Panel/controller kodu nerede? | **Bu repoda:** `panel/` ve `controller/`. |
| Herkes kendi panelini mi yazar? | **Hayır.** Varsayılan olarak bu repodaki resmi panel ve controller kullanılır. |
| Image’lar nereden çekilir? | Varsayılan: `ghcr.io/vhp-platform/vhp-panel:latest` ve `vhp-controller:latest`. Registry/org sizin publish ettiğiniz yere göre değiştirilebilir. |
| Image’ları kim build eder? | Siz (repo sahibi): CI/CD veya `scripts/build-images.sh` ile. Kullanıcılar sadece kurulumda bu image’ları çeker. |
