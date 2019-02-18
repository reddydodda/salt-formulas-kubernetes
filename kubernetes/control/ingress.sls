{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for ingress_name, ingress in control.ingress.items() %}
  {%- if ingress.get('enabled', false) %}

/srv/kubernetes/ingress/{{ ingress.cluster }}/{{ ingress_name }}-ingress.yml:
  file.managed:
  - source: salt://kubernetes/files/ingress.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      ingress: {{ ingress|yaml }}
      ingress_name: {{ ingress_name }}

    {%- if ingress.get('create', false) %}
kubernetes_ingress_create_{{ ingress_name }}:
  cmd.wait:
    - name: kubectl apply -f /srv/kubernetes/ingress/{{ ingress.cluster }}/{{ ingress_name }}-ingress.yml
    - unless: kubectl get ingress -o=custom-columns=NAME:.metadata.name --namespace {{ ingress.namespace }} | grep -xq {{ ingress_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/ingress/{{ ingress.cluster }}/{{ ingress_name }}-ingress.yml
    {%- endif %}

  {%- endif %}
{%- endfor %}
