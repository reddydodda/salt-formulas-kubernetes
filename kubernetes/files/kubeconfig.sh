{%- from "kubernetes/map.jinja" import common with context -%}
#!/bin/bash

# server url
server="$(awk '/server/ { print $2 }' /etc/kubernetes/kubelet.kubeconfig)"

# certificates
{%- if common.get('cloudprovider', {}).get('enabled') and common.get('cloudprovider', {}).get('provider') == 'openstack' %}
cert="$(base64 --wrap=0 /etc/kubernetes/ssl/kubelet-client.crt)"
key="$(base64 --wrap=0 /etc/kubernetes/ssl/kubelet-client.key)"
{%- else %}
cert="$(base64 --wrap=0 /etc/kubernetes/ssl/kubelet-client-fqdn.crt)"
key="$(base64 --wrap=0 /etc/kubernetes/ssl/kubelet-client-fqdn.key)"
{%- endif %}
ca="$(base64 --wrap=0 /etc/kubernetes/ssl/ca-kubernetes.crt )"
cluster="{{ common.cluster_name }}"

echo "apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${ca}
    server: ${server}
  name: ${cluster}
- cluster:
    server: http://localhost:8080
  name: local
contexts:
- context:
    cluster: ${cluster}
    user: admin-${cluster}
  name: ${cluster}
- context:
    cluster: local
    namespace: default
    user: ""
  name: local
current-context: ${cluster}
users:
- name: admin-${cluster}
  user:
    client-certificate-data: ${cert}
    client-key-data: ${key}
kind: Config
preferences: {}"
