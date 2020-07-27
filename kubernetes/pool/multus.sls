{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/etc/cni/net.d/00-multus.conf:
  file.managed:
    - source: salt://kubernetes/files/kube-addons/multus/multus.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

{%- if not pool.network.get('multus', {}).get('enabled') %}

/etc/cni/net.d/00-multus.conf:
  file.absent

{%- endif %}

{%- endif %}
