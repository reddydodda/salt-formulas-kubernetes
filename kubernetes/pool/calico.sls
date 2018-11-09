{%- from "kubernetes/map.jinja" import common with context %}
{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/usr/bin/calicoctl:
  file.managed:
    - source: {{ pool.network.calico.calicoctl_source }}
    - source_hash: {{ pool.network.calico.calicoctl_source_hash }}
    - mode: 751
    - user: root
    - group: root
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/usr/bin/birdcl:
  file.managed:
    - source: {{ pool.network.calico.birdcl_source }}
    - source_hash: {{ pool.network.calico.birdcl_source_hash }}
    - mode: 751
    - user: root
    - group: root
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/opt/cni/bin/calico:
  file.managed:
    - source: {{ pool.network.calico.cni_source }}
    - source_hash: {{ pool.network.calico.cni_source_hash }}
    - mode: 751
    - makedirs: true
    - user: root
    - group: root
    - require_in:
      - service: calico_node
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/opt/cni/bin/calico-ipam:
  file.managed:
    - source: {{ pool.network.calico.cni_ipam_source }}
    - source_hash: {{ pool.network.calico.cni_ipam_source_hash }}
    - mode: 751
    - makedirs: true
    - user: root
    - group: root
    - require_in:
      - service: calico_node
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/etc/cni/net.d/10-calico.conf:
  file.managed:
    - source: salt://kubernetes/files/calico/calico.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/etc/calico/network-environment:
  file.managed:
    - source: salt://kubernetes/files/calico/network-environment.pool
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/etc/calico/calicoctl.cfg:
  file.managed:
    - source: salt://kubernetes/files/calico/calicoctl.cfg.pool
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

{%- if pool.network.calico.get('systemd', true) %}

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
      hostname: {{ pool.host.name }}{% if pool.host.get('domain') %}.{{ pool.host.domain }}{%- endif %}
      address: {{ pool.address }}
      calico: {{ pool.network.calico }}
{%- else %}
/etc/systemd/system/calico-node.service:
  file.managed:
    - source: salt://kubernetes/files/calico/calico-node.service.pool
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
