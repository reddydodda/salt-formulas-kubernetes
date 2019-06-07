{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for secret_name, secret in control.secret.items() %}
  {%- if secret.get('enabled', false) %}

/srv/kubernetes/secrets/{{ secret.namespace }}/{{ secret_name }}.yml:
  file.managed:
  - source: salt://kubernetes/files/secret.yml
  - user: root
  - group: root
  - mode: 750
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      secret: {{ secret|yaml }}

    {%- if secret.get('create', false) %}
  cmd.wait:
    - name: kubectl apply -f /srv/kubernetes/secrets/{{ secret.namespace }}/{{ secret_name }}.yml
    - unless: kubectl get secret -o=custom-columns=NAME:.metadata.name --namespace {{ secret.namespace }} | grep -xq {{ secret_name }}
      {%- if grains.get('noservices') %}
    - onlyif: /bin/false
      {%- endif %}
    - watch:
      - file: /srv/kubernetes/secrets/{{ secret.namespace }}/{{ secret_name }}.yml
    {%- endif %}

  {%- endif %}
{%- endfor %}