# VHP Controller

Bu reponun resmi controller uygulaması. Kullanıcı namespace’leri ve zonları yönetir.

- **Geliştirme:** `go run .` (port 8080)
- **Image:** `docker build -t vhp-controller .` (veya repo kökünden `./scripts/build-images.sh`)
- Health: `/healthz`, `/readyz`

Gerçek mantık (namespace oluşturma, RBAC, DNS/backup zonları) bu yapı üzerine eklenecek.
