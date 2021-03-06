{%- from "kubernetes/map.jinja" import master with context %}
{%- from "kubernetes/map.jinja" import common with context %}
{%- from "kubernetes/map.jinja" import version %}
{%- from "kubernetes/map.jinja" import full_version %}
{%- if master.enabled %}

{%- if master.auth.get('token', {}).enabled|default(True) %}
kubernetes_known_tokens:
  file.managed:
  - name: {{ master.auth.token.file|default("/srv/kubernetes/known_tokens.csv") }}
  - source: salt://kubernetes/files/known_tokens.csv
  - template: jinja
  - user: root
  - group: root
  - mode: 644
  - makedirs: true
  {%- if not master.get('container', 'true') %}
  - watch_in:
    - service: master_services
  {%- endif %}
{%- endif %}

{%- if master.auth.get('basic', {}).enabled|default(True) %}
kubernetes_basic_auth:
  file.managed:
  - name: {{ master.auth.basic.file|default("/srv/kubernetes/basic_auth.csv") }}
  - source: salt://kubernetes/files/basic_auth.csv
  - template: jinja
  - user: root
  - group: root
  - mode: 644
  - makedirs: true
  {%- if not master.get('container', 'true') %}
  - watch_in:
    - service: master_services
  {%- endif %}
{%- endif %}

{%- if master.get('container', 'true') %}

/var/log/kube-apiserver.log:
  file.managed:
  - user: root
  - group: root
  - mode: 644

/etc/kubernetes/manifests/kube-apiserver.manifest:
  file.managed:
  - source: salt://kubernetes/files/manifest/kube-apiserver.manifest
  - template: jinja
  - user: root
  - group: root
  - mode: 644
  - makedirs: true
  - dir_mode: 755

/etc/kubernetes/manifests/kube-controller-manager.manifest:
  file.managed:
    - source: salt://kubernetes/files/manifest/kube-controller-manager.manifest
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755

/var/log/kube-controller-manager.log:
  file.managed:
    - user: root
    - group: root
    - mode: 644

/etc/kubernetes/manifests/kube-scheduler.manifest:
  file.managed:
    - source: salt://kubernetes/files/manifest/kube-scheduler.manifest
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755

/var/log/kube-scheduler.log:
  file.managed:
    - user: root
    - group: root
    - mode: 644

{%- else %}


{%- if common.get('cloudprovider', {}).get('enabled') %}
{%- if common.get('cloudprovider', {}).get('provider') == 'openstack' %}
/usr/bin/openstack-cloud-controller-manager:
  file.managed:
    - source: {{ common.cloudprovider.params.binary }}
    - mode: 751
    - makedirs: true
    - user: root
    - group: root
    - source_hash: {{ common.cloudprovider.params.binary_hash }}

/etc/default/openstack-cloud-controller-manager:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: >-
        DAEMON_ARGS="
        --cloud-provider=openstack
        --cloud-config /etc/kubernetes/cloud-config
        --cluster-name=kubernetes
        --kubeconfig /etc/kubernetes/controller-manager.kubeconfig
        --leader-elect=true
        --v={{ master.get('verbosity', 2) }}"

/etc/systemd/system/openstack-cloud-controller-manager.service:
  file.managed:
  - source: salt://kubernetes/files/systemd/openstack-cloud-controller-manager.service
  - template: jinja
  - user: root
  - group: root
  - mode: 644
{%- endif %}
{%- endif %}

/etc/default/kube-apiserver:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: >-
        # Using hyperkube version v{{ full_version }}

        DAEMON_ARGS="
        {%- if common.get('cloudprovider', {}).get('enabled') %}
        {%- if common.get('cloudprovider', {}).get('provider') == 'openstack' %}
        --runtime-config=admissionregistration.k8s.io/v1alpha1
        --enable-admission-plugins=Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,DefaultStorageClass
        --disable-admission-plugins=PersistentVolumeLabel
        {%- endif %}
        {%- else %}
        --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,DefaultStorageClass
        {%- endif %}
        --allow-privileged=True
        {%- if master.auth.get('mode') %}
        --authorization-mode={{ master.auth.mode }}
        {%- endif %}
        {%- if master.auth.get('basic', {}).enabled|default(True) %}
        --basic-auth-file={{ master.auth.basic.file|default("/srv/kubernetes/basic_auth.csv") }}
        {%- endif %}
        --bind-address={{ master.apiserver.get('bind_address', master.apiserver.address) }}
        {%- if master.auth.get('ssl', {}).enabled|default(True) %}
        --client-ca-file={{ master.auth.get('ssl', {}).ca_file|default("/etc/kubernetes/ssl/ca-"+master.ca+".crt") }}
        {%- endif %}
        {%- if master.auth.get('proxy', {}).enabled|default(False) %}
        --requestheader-allowed-names=system:kube-controller-manager
        --requestheader-username-headers={{ master.auth.proxy.header.user }}
        --requestheader-group-headers={{ master.auth.proxy.header.group }}
        --requestheader-extra-headers-prefix={{ master.auth.proxy.header.extra }}
        --requestheader-client-ca-file={{ master.auth.proxy.ca_file|default("/etc/kubernetes/ssl/ca-"+master.ca+".crt") }}
        --proxy-client-cert-file={{ master.auth.proxy.client_cert|default("/etc/kubernetes/ssl/kube-aggregator-proxy-client.crt") }}
        --proxy-client-key-file={{ master.auth.proxy.client_key|default("/etc/kubernetes/ssl/kube-aggregator-proxy-client.key") }}
        {%- endif %}
        --anonymous-auth={{ master.auth.get('anonymous', {}).enabled|default(False) }}
        --insecure-bind-address={{ master.apiserver.insecure_address }}
        --insecure-port={{ master.apiserver.insecure_port }}
        --secure-port={{ master.apiserver.secure_port }}
        --service-cluster-ip-range={{ master.service_addresses }}
        --tls-cert-file=/etc/kubernetes/ssl/kubernetes-server.crt
        --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-server.key
        {%- if master.auth.get('token', {}).enabled|default(True) %}
        --token-auth-file={{ master.auth.token.file|default("/srv/kubernetes/known_tokens.csv") }}
        {%- endif %}
        --v={{ master.get('verbosity', 2) }}
        --advertise-address={{ master.apiserver.address }}
        --etcd-servers=
{%- for member in master.etcd.members -%}
          http{% if master.etcd.get('ssl', {}).get('enabled') %}s{% endif %}://{{ member.host }}:{{ member.get('port', 4001) }}{% if not loop.last %},{% endif %}
{%- endfor %}
{%- if master.etcd.get('ssl', {}).get('enabled') %}
        --etcd-cafile /var/lib/etcd/ca.pem
        --etcd-certfile /var/lib/etcd/etcd-client.crt
        --etcd-keyfile /var/lib/etcd/etcd-client.key
{%- endif %}
{%- if master.apiserver.node_port_range is defined %}
        --service-node-port-range {{ master.apiserver.node_port_range }}
{%- endif %}
{%- if common.addons.get('virtlet', {}).get('enabled') %}
{%- if salt['pkg.version_cmp'](version,'1.8') >= 0 %}
        --feature-gates=MountPropagation=true
{%- endif %}
{%- if salt['pkg.version_cmp'](version,'1.9') >= 0 %}
        --endpoint-reconciler-type={{ master.apiserver.get('endpoint-reconciler', 'lease') }}
{%- else %}
        --apiserver-count={{ master.apiserver.get('count', 1) }}
{%- endif %}

{%- endif %}
{%- for key, value in master.get('apiserver', {}).get('daemon_opts', {}).items() %}
        --{{ key }}={{ value }}
{%- endfor %}"

{% for component in ['scheduler', 'controller-manager'] %}

/etc/kubernetes/{{ component }}.kubeconfig:
  file.managed:
    - source: salt://kubernetes/files/kube-{{ component }}/{{ component }}.kubeconfig
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - watch_in:
        - service: master_services

{% endfor %}

/etc/default/kube-controller-manager:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: >-
        # Using hyperkube version v{{ full_version }}

        DAEMON_ARGS="
        --cluster-name=kubernetes
        --kubeconfig /etc/kubernetes/controller-manager.kubeconfig
        --leader-elect=true
        --root-ca-file=/etc/kubernetes/ssl/ca-{{ master.ca }}.crt
        --service-account-private-key-file=/etc/kubernetes/ssl/kubernetes-server.key
        --use-service-account-credentials
{%- if common.get('cloudprovider', {}).get('enabled') and common.get('cloudprovider', {}).get('provider') == 'openstack' %}
        --external-cloud-volume-plugin=openstack
        --cloud-config /etc/kubernetes/cloud-config.intree
        --cloud-provider external
{%- endif %}
        --v={{ master.get('verbosity', 2) }}
{%- if master.network.get('flannel', {}).get('enabled', False) %}
        --allocate-node-cidrs=true
        --cluster-cidr={{ master.network.flannel.private_ip_range }}
{%- endif %}
{%- for key, value in master.get('controller_manager', {}).get('daemon_opts', {}).items() %}
        --{{ key }}={{ value }}
{% endfor %}"

/etc/default/kube-scheduler:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: >-
        # Using hyperkube version v{{ full_version }}

        DAEMON_ARGS="
        --kubeconfig /etc/kubernetes/scheduler.kubeconfig
        --leader-elect=true
        --v={{ master.get('verbosity', 2) }}
{%- for key, value in master.get('scheduler', {}).get('daemon_opts', {}).items() %}
        --{{ key }}={{ value }}
{% endfor %}"

/etc/systemd/system/kube-apiserver.service:
  file.managed:
  - source: salt://kubernetes/files/systemd/kube-apiserver.service
  - template: jinja
  - user: root
  - group: root
  - mode: 644

/etc/systemd/system/kube-scheduler.service:
  file.managed:
  - source: salt://kubernetes/files/systemd/kube-scheduler.service
  - template: jinja
  - user: root
  - group: root
  - mode: 644

/etc/systemd/system/kube-controller-manager.service:
  file.managed:
  - source: salt://kubernetes/files/systemd/kube-controller-manager.service
  - template: jinja
  - user: root
  - group: root
  - mode: 644

{% for filename in ['kubernetes-server.crt', 'kubernetes-server.key', 'kubernetes-server.pem'] %}

/etc/kubernetes/ssl/{{ filename }}:
  file.managed:
    - source: salt://{{ master.get('cert_source','_certs/kubernetes') }}/{{ filename }}
    - user: root
    {%- if pillar.get('haproxy', {}).get('proxy', {}).get('enabled') %}
    - group: haproxy
    {%- else %}
    - group: root
    {%- endif %}
    - mode: 640
    - watch_in:
      - service: master_services

{% endfor %}

master_services:
  service.running:
  - names: {{ master.services }}
  - enable: True
  - watch:
    - file: /etc/default/kube-apiserver
    - file: /etc/default/kube-scheduler
    - file: /etc/default/kube-controller-manager
    - file: /usr/bin/hyperkube

{%- if common.get('cloudprovider', {}).get('enabled') %}
{%- if common.get('cloudprovider', {}).get('provider') == 'openstack' %}
openstack_cloud_controller_service:
  service.running:
  - name: openstack-cloud-controller-manager
  - enable: True
  - watch:
    - file: /etc/kubernetes/cloud-config
    - file: /etc/default/openstack-cloud-controller-manager
    - file: /etc/kubernetes/controller-manager.kubeconfig
    - file: /usr/bin/openstack-cloud-controller-manager

kube_controller_mnanager_service:
  service.running:
  - name: kube-controller-manager
  - watch:
    - file: /etc/kubernetes/cloud-config.intree
{%- endif %}
{%- endif %}

{%- endif %}

{%- if master.namespace is defined %}

{%- for name,namespace in master.namespace.items() %}

{%- if namespace.enabled %}

{%- set date = salt['cmd.run']('date "+%FT%TZ"') %}

kubernetes_namespace_create_{{ name }}:
  cmd.run:
    - name: kubectl create ns "{{ name }}"
    - unless: kubectl get ns -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep "{{ name }}"
    - retry:
        attempts: 3
        until: True
        interval: 10
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- else %}

kubernetes_namespace_delete_{{ name }}:
  cmd.run:
    - name: kubectl delete ns "{{ name }}"
    - onlyif:
      - kubectl get ns -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep "{{ name }}" > /dev/null
      {%- if grains.get('noservices') %}
      - /bin/false
      {%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}

{%- if master.registry.secret is defined %}

{%- for name,registry in master.registry.secret.items() %}

{%- if registry.enabled %}

/registry/secrets/{{ registry.namespace }}/{{ name }}:
  etcd.set:
    - value: '{"kind":"Secret","apiVersion":"v1","metadata":{"name":"{{ name }}","namespace":"{{ registry.namespace }}"},"data":{".dockerconfigjson":"{{ registry.key }}"},"type":"kubernetes.io/dockerconfigjson"}'
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- else %}

/registry/secrets/{{ registry.namespace }}/{{ name }}:
  etcd.rm

{%- endif %}

{%- endfor %}

{%- endif %}

{%- endif %}
