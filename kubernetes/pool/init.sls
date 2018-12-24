{%- from "kubernetes/map.jinja" import pool with context %}
{%- from "kubernetes/map.jinja" import common with context -%}
include:
{%- if not pillar.kubernetes.master is defined %}
{%- if pool.network.get('calico', {}).get('enabled', False) %}
- kubernetes.pool.calico
{%- endif %}
{%- endif %}
{%- if pool.network.get('opencontrail', {}).get('enabled', False) %}
- kubernetes.pool.opencontrail
{%- endif %}
- kubernetes.pool.service
{%- if pool.network.get('flannel', {}).get('enabled', False) %}
- kubernetes.pool.flannel
{%- endif %}
{%- if not pillar.kubernetes.master is defined %}
{%- if pool.network.get('genie', {}).get('enabled', False) %}
- kubernetes.pool.genie
{%- endif %}
{%- endif %}
{%- if pool.network.get('sriov', {}).get('enabled', False) %}
- kubernetes.pool.sriov
{%- endif %}
{%- if pool.get('kube_proxy', {}).get('enabled', True) %}
- kubernetes.pool.kube-proxy
{%- endif %}
{%- if common.addons.get('virtlet', {}).get('use_apparmor') and not pillar.get('kubernetes', {}).get('master', False) %}
- kubernetes.pool.virtlet-apparmor
{%- endif %}
