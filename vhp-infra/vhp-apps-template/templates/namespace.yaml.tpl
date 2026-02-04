apiVersion: v1
kind: Namespace
metadata:
  name: user-{{ .Name }}
  labels:
    vhp-managed: "true"
    vhp-type: "user-space"
    vhp-user-id: "{{ .ID }}"