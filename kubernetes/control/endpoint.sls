{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for endpoint_name, endpoint in control.endpoints.items() %}
  {%- if endpoint.get('service_enabled', false) %}

/srv/kubernetes/services/{{ endpoint.cluster }}/{{ endpoint.service }}-svc.yml:
  file.managed:
  - source: salt://kubernetes/files/svc.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      service: {{ endpoint|yaml }}

    {%- if endpoint.get('create', false) %}
      {%- set service_name = endpoint.service + '-' + endpoint.role if endpoint.role is defined else endpoint.service %}
kubernetes_service_create_{{ endpoint.service }}:
  cmd.run:
    - name: kubectl apply -f /srv/kubernetes/services/{{ endpoint.cluster }}/{{ endpoint.service }}-svc.yml
    - unless: kubectl get service -o=custom-columns=NAME:.metadata.name --namespace {{ endpoint.namespace }} | grep -xq {{ endpoint.service }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/services/{{ endpoint.cluster }}/{{ endpoint.service }}-svc.yml
    {%- endif %}

  {%- endif %}

/srv/kubernetes/endpoints/{{ endpoint.cluster }}/{{ endpoint_name }}.yml:
  file.managed:
  - source: salt://kubernetes/files/endpoint.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      endpoint: {{ endpoint|yaml }}
      endpoint_name: {{ endpoint_name }}

    {%- if endpoint.get('create', false) %}
kubernetes_endpoint_create_{{ endpoint_name }}:
  cmd.run:
    - name: kubectl apply -f /srv/kubernetes/endpoints/{{ endpoint.cluster }}/{{ endpoint_name }}.yml
    - unless: kubectl get endpoint -o=custom-columns=NAME:.metadata.name --namespace {{ endpoint.namespace }} | grep -xq {{ endpoint_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/endpoints/{{ endpoint.cluster }}/{{ endpoint_name }}.yml
    {%- endif %}

{%- endfor %}
