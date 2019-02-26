{%- from "kubernetes/map.jinja" import client with context -%}
{%- if client.enabled %}
  {%- if client.get('resources', {}).get('enabled') %}

    {%- for name,label in client.resources.get('label', {}).iteritems() %}

      {%- if label.enabled %}
        {%- if label.get('status', 'present') == 'present' %}
          {%- for node in label.node %}
# TODO(vsaienko) switch to kubernetes. salt module once kubernets-client python is packages and
# awailable for installation.
{{ name }}_{{ node }}:
  k8s.label_present:
    - name: {{ label.key }}
    - value: {{ label.value }}
    - node: {{ node }}
    # TODO(vsaienko): move to profiles
    - apiserver: http://{{ client.apiserver.insecure_address }}:{{ client.apiserver.insecure_port }}
          {%- endfor %}

        {%- elif label.get('status', 'present') == 'absent' %}
          {%- for node in label.node %}
{{ name }}_{{ node }}:
  k8s.label_absent:
    - name: {{ label.key }}
    - node: {{ node }}
    - apiserver: http://{{ client.apiserver.insecure_address }}:{{ client.apiserver.insecure_port }}
          {%- endfor %} # endfor label.node.iteritems
        {%- endif %} # endif label.present
      {%- endif %} # endif label.enabled
    {%- endfor %} # endfor client.resources.label
  {%- endif %} # endif client.resources.enabled
{%- endif %} # endif client.enabled
