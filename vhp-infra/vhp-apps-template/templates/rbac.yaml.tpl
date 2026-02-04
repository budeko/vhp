apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-admin-binding
  namespace: user-{{ .Name }}
subjects:
- kind: User
  name: "{{ .Email }}"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit # Kullanıcıya kendi alanında düzenleme yetkisi verir, silme yetkisini kısıtlar
  apiGroup: rbac.authorization.k8s.io