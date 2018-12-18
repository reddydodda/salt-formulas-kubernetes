{%- from "kubernetes/map.jinja" import common with context -%}
{%- from "kubernetes/map.jinja" import master with context -%}
{%- if master.enabled %}

/etc/kubernetes/kubeconfig.sh:
  file.managed:
    - source: salt://kubernetes/files/kubeconfig.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

generate_admin_kube_config:
  cmd.run:
    - name: /etc/kubernetes/kubeconfig.sh > /etc/kubernetes/admin-kube-config
    - watch:
      - file: /etc/kubernetes/kubeconfig.sh

/etc/kubernetes/addons/namespace.yaml:
  file.managed:
    - source: salt://kubernetes/files/kube-addon-manager/namespace.yaml
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

{%- if common.get('addonmanager', {}).get('container', false) %}

/etc/kubernetes/manifests/kube-addon-manager.yml:
  file.managed:
    - source: salt://kubernetes/files/manifest/kube-addon-manager.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

/etc/default/kube-addon-manager:
  file.absent

/usr/bin/kube-addons.sh:
  file.absent

kube-addon-manager_service_dead:
  service.dead:
  - name: kube-addon-manager
  - enable: False

/etc/systemd/system/kube-addon-manager.service:
  file.absent

{%- else %}

/etc/kubernetes/manifests/kube-addon-manager.yml:
  file.absent

/etc/default/kube-addon-manager:
  file.managed:
    - source: salt://kubernetes/files/kube-addon-manager/kube-addons.config
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/usr/bin/kube-addons.sh:
  file.managed:
    - source: salt://kubernetes/files/kube-addon-manager/kube-addons.sh
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/systemd/system/kube-addon-manager.service:
  file.managed:
    - source: salt://kubernetes/files/systemd/kube-addon-manager.service
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

kube-addon-manager_service:
  service.running:
  - name: kube-addon-manager
  - enable: True
  - watch:
    - file: /etc/default/kube-addon-manager
    - file: /usr/bin/kube-addons.sh
    - file: /etc/systemd/system/kube-addon-manager.service
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

/srv/kubernetes/conformance.yml:
  file.managed:
    - source: salt://kubernetes/files/conformance/conformance.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

{%- if common.addons.get('virtlet', {}).get('enabled') %}

/srv/kubernetes/virtlet_conformance.yml:
  file.managed:
    - source: salt://kubernetes/files/conformance/virtlet_conformance.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

{%- endif %}

{%- if master.label is defined %}

{%- for name,label in master.label.items() %}

{%- if label.enabled %}

{{ name }}_{{ label.node }}:
  k8s.label_present:
    - name: {{ label.key }}
    - value: {{ label.value }}
    - node: {{ label.node }}
    - apiserver: http://{{ master.apiserver.insecure_address }}:{{ master.apiserver.insecure_port }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- else %}

{{ name }}_{{ label.node }}:
  k8s.label_absent:
    - name: {{ label.key }}
    - node: {{ label.node }}
    - apiserver: http://{{ master.apiserver.insecure_address }}:{{ master.apiserver.insecure_port }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}

{%- endif %}
