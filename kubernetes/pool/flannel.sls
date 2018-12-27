{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/etc/cni/net.d/12-flannel.conflist:
  file.managed:
    - source: salt://kubernetes/files/flannel/flannel.conflist
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

{%- endif %}
