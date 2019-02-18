{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for service_name, service in control.service.items() %}
  {%- if service.get('enabled', false) %}

/srv/kubernetes/services/{{ service.cluster }}/{{ service_name }}-svc.yml:
  file.managed:
  - source: salt://kubernetes/files/svc.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      service: {{ service|yaml }}

    {%- if service.get('create', false) %}
      {%- set service_real_name = service.service + '-' + service.role if service.role is defined else service.service %}
kubernetes_service_create_{{ service_name }}:
  cmd.wait:
    - name: kubectl apply -f /srv/kubernetes/services/{{ service.cluster }}/{{ service_name }}-svc.yml
    - unless: kubectl get service -o=custom-columns=NAME:.metadata.name --namespace {{ service.namespace }} | grep -xq {{ service_real_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/services/{{ service.cluster }}/{{ service_name }}-svc.yml
    {%- endif %}

  {%- endif %}

/srv/kubernetes/{{ service.kind|lower }}/{{ service_name }}-{{ service.kind }}.yml:
  file.managed:
  - source: salt://kubernetes/files/rc.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      service: {{ service|yaml }}

    {%- if service.get('create', false) %}
      {%- set service_real_name = service.service + '-' + service.role if service.role is defined else service.service %}
kubernetes_{{ service.kind|lower }}_create_{{ service_name }}:
  cmd.wait:
    - name: kubectl apply -f /srv/kubernetes/{{ service.kind|lower }}/{{ service_name }}-{{ service.kind }}.yml
    - unless: kubectl get {{ service.kind|lower }} -o=custom-columns=NAME:.metadata.name --namespace {{ service.namespace }} | grep -xq {{ service_real_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/{{ service.kind|lower }}/{{ service_name }}-{{ service.kind }}.yml
    {%- endif %}

{%- endfor %}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').items() %}

  {%- if node_grains.get('kubernetes', {}).service is defined %}
    {%- set service = node_grains.get('kubernetes', {}).get('service', {}) %}
    {%- if service.enabled %}

/srv/kubernetes/services/{{ node_name }}-svc.yml:
  file.managed:
  - source: salt://kubernetes/files/svc.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      service: {{ service|yaml }}

      {%- if service.get('create', false) %}
        {%- set service_real_name = service.service + '-' + service.role if service.role is defined else service.service %}
kubernetes_service_create_{{ service.service }}:
  cmd.wait:
    - name: kubectl apply -f /srv/kubernetes/services/{{ node_name }}-svc.yml
    - unless: kubectl get service -o=custom-columns=NAME:.metadata.name --namespace {{ service.namespace }} | grep -xq {{ service_real_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/services/{{ node_name }}-svc.yml
      {%- endif %}

    {%- endif %}
/srv/kubernetes/{{ service.kind|lower }}/{{ node_name }}-{{ service.kind }}.yml:
  file.managed:
  - source: salt://kubernetes/files/rc.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      service: {{ service|yaml }}

    {%- if service.get('create', false) %}
      {%- set service_real_name = service.service + '-' + service.role if service.role is defined else service.service %}
kubernetes_{{ service.kind|lower }}_create_{{ service_name }}:
  cmd.wait:
    - name: kubectl apply -f /srv/kubernetes/{{ service.kind|lower }}/{{ node_name }}-{{ service.kind }}.yml
    - unless: kubectl get {{ service.kind|lower }} -o=custom-columns=NAME:.metadata.name --namespace {{ service.namespace }} | grep -xq {{ service_real_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: /srv/kubernetes/{{ service.kind|lower }}/{{ node_name }}-{{ service.kind }}.yml
    {%- endif %}

  {%- endif %}

{%- endfor %}
