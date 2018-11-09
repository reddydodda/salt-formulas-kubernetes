{%- from "kubernetes/map.jinja" import common with context %}
{%- from "kubernetes/map.jinja" import master with context %}
{%- if master.enabled %}

/etc/calico/network-environment:
  file.managed:
    - source: salt://kubernetes/files/calico/network-environment.master
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/etc/calico/calicoctl.cfg:
  file.managed:
    - source: salt://kubernetes/files/calico/calicoctl.cfg.master
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/usr/bin/calicoctl:
  file.managed:
    - source: {{ master.network.calico.calicoctl_source }}
    - source_hash: {{ master.network.calico.calicoctl_source_hash }}
    - mode: 751
    - user: root
    - group: root
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
{%- if master.network.calico.get('systemd', true) %}

{%- if common.get('containerd', {}).get('enabled', false) %}
/etc/systemd/system/calico-node.service:
  file.managed:
    - source: salt://kubernetes/files/calico/calico-node.service.ctr
    - user: root
    - group: root
    - template: jinja
    - require:
      - service: containerd
    - defaults:
      hostname: {{ master.host.name }}{% if master.host.get('domain') %}.{{ master.host.domain }}{%- endif %}
      address: {{ master.apiserver.address }}
      calico: {{ master.network.calico }}
{%- else %}
/etc/systemd/system/calico-node.service:
  file.managed:
    - source: salt://kubernetes/files/calico/calico-node.service.master
    - user: root
    - group: root
    - template: jinja
{%- endif %}

{%- for dirname in ['lib', 'log'] %}
/var/{{ dirname }}/calico:
  file.directory:
      - user: root
      - group: root
      - require_in:
        - service: calico-node
{%- endfor %}

calico_node:
  service.running:
    - name: calico-node
    - enable: True
    - watch:
      - file: /etc/systemd/system/calico-node.service
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    
{%- endif %}

{%- endif %}
