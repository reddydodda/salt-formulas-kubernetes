{% from "kubernetes/map.jinja" import control with context %}
include:
  {%- if control.job is defined %}
  - kubernetes.control.job
  {%- endif %}
  {%- if control.service is defined %}
  - kubernetes.control.service
  {%- endif %}
  {%- if control.configmap is defined %}
  - kubernetes.control.configmap
  {%- endif %}
  {%- if control.role is defined %}
  - kubernetes.control.role
  {%- endif %}
  {%- if control.priorityclass is defined %}
  - kubernetes.control.priorityclass
  {%- endif %}

/srv/kubernetes:
  file.directory:
  - makedirs: true
