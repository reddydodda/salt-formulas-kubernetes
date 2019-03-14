{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.get('enabled', False) and pool.get('images', {}) %}

{%- for image in pool.get('images', []) %}

{{ image }}_image:
  cmd.run:
    - name: /usr/local/bin/crictl pull {{ image }}
    - onlyif: "test -e /usr/local/bin/crictl"
    - unless: "/usr/local/bin/crictl images -o yaml | grep {{ image }}"

{%- endfor %}

{%- endif %}