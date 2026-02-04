# VHP Kullanıcı Alanı: {{ .Name }}

Bu alan otomatik olarak oluşturulmuştur.

## Erişim Bilgileri
- **Namespace:** user-{{ .Name }}
- **Oluşturulma Tarihi:** {{ .Date }}

## Güvenlik Notları
- Bu alandaki kaynak kullanımı (CPU/RAM) `user-quota` ile sınırlandırılmıştır.
- Diğer kullanıcıların ağlarına (NetworkPolicy gereği) erişiminiz kapalıdır.
- Tüm Ingress tanımlarınızda `vhp-nginx` sınıfını kullanmanız zorunludur.

---
VHP Automation System tarafından üretilmiştir.