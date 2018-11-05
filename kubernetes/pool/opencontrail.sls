{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/etc/cni/net.d/11-opencontrail.conf:
  file.managed:
    - source: salt://kubernetes/files/opencontrail/opencontrail.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

opencontrail_cni_package:
  pkg.installed:
  - name: contrail-k8s-cni
  - force_yes: True

opencontrail_cni_symlink:
  file.symlink:
  - name: /opt/cni/bin/opencontrail
  - target: /usr/bin/contrail-k8s-cni
  - force: true
  - makedirs: true
  - watch_in:
    - service: kubelet_service
  - require:
    - pkg: opencontrail_cni_package

{%- endif %}
