{%- from "kubernetes/map.jinja" import client, common with context -%}
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

{%- if client.helm is defined %}

openstack_helm_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

{%- set _helm = client.helm %}
{%- if _helm.get('enabled', false) %}
  {%- if _helm.repos is defined  %}
    {%- for repo_id, helm_repo in _helm.repos.iteritems() %}
      {%- if helm_repo.get('enabled', True) %}
repo_{{ repo_id }}_managed:
  k8s_helm_repos.managed:
    - present:
        {{ helm_repo['repository'] }}
    - helm_home: {{ common.helm_home }}
      {%- endif %}
    {%- endfor %}
repos_updated:
  k8s_helm_repos.updated:
    - helm_home: {{ common.helm_home }}
  {%- endif %}

  {%- if _helm.charts is defined  %}
    {%- for release_id, helm_chart in _helm.charts|dictsort %}
      {%- set release_name = helm_chart.get('release', release_id) %}
      {%- set namespace = helm_chart.get('namespace', 'default') %}
      {%- set values_file = "/tmp/helm_chart_" + release_name + "_values.yaml" %}
      {%- if helm_chart.get('enabled', True) %}
        {%- if helm_chart.get("values") %}
{{ values_file }}:
  file.managed:
    - makedirs: True
    - contents: |
        {{ helm_chart['values'] | yaml(false) | indent(8) }}
        {%- endif %}

ensure_{{ release_id }}_release:
  k8s_helm_release.present:
    - name: {{ release_name }}
    - chart_name: {{ helm_chart.chart_name }}
    - namespace: {{ namespace }}
    - helm_home: {{ common.helm_home }}
    {%- if helm_chart.version is defined %}
    - version: {{ helm_chart.version }}
    {%- endif %}
    {%- if helm_chart.values is defined %}
    - values_file: {{ values_file }}
    {%- endif %}
      {%- endif %}

    {%- endfor %}
  {%- endif %}
{%- endif %}
{%- endif %}

{%- endif %}
