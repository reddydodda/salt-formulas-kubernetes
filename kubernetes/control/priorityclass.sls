{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for priorityclass_name, priorityclass in control.priorityclass.iteritems() %}
  {%- set priorityclass_name = priorityclass.name|default(priorityclass_name) %}
  {%- set priorityclass_value = priorityclass.priority_value %}
  {%- set is_default_priorityclass = priorityclass.is_default|default(False) %}
  {%- set priorityclass_description = priorityclass.description|default(priorityclass_name) %}

/srv/kubernetes/priorityclasses/{{ priorityclass_name }}.yml:
  file.managed:
  - source: salt://kubernetes/files/priorityclass.yml
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      priorityclass: {{ priorityclass|yaml }}
      priorityclass_name: {{ priorityclass_name }}
      priorityclass_value: {{ priorityclass_value }}
      is_default_priorityclass: {{ is_default_priorityclass }}
      priorityclass_description: {{ priorityclass_description }}

kubernetes_priorityclass_create_{{ priorityclass_name }}:
  cmd.run:
    - name: kubectl apply -f /srv/kubernetes/priorityclasses/{{ priorityclass_name }}.yml
    - unless: kubectl get priorityclass -o=custom-columns=NAME:.metadata.name | grep -xq {{ priorityclass_name }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - require:
      - file: /srv/kubernetes/priorityclasses/{{ priorityclass_name }}.yml

{%- endfor %}
