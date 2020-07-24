{%- from "kubernetes/map.jinja" import common with context -%}
{%- from "kubernetes/map.jinja" import master with context -%}
{%- from "kubernetes/map.jinja" import version %}
{%- if master.enabled %}

{%- if common.addons.get('multus', {}).get('enabled') %}

/etc/kubernetes/kubevirt/multus-crd.yml:
  file.managed:
    - source: salt://kubernetes/files/kubevirt/multus-crd.yml
    - template: jinja
    - group: root
    - dir_mode: 755
    - makedirs: True

kubernetes_multus_crd_create:
  cmd.run:
    - name: kubectl apply -f /etc/kubernetes/kubevirt/multus-crd.yml
    - require:
      - file: /etc/kubernetes/kubevirt/multus-crd.yml

{% endif %}

kubernetes_multus_crd_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/multus-crd.yml
    - onlyif: "{%- if common.addons.get('multus', {}).get('enabled') == 'false' or common.addons.get('multus', {}).get('enabled') == 'False' %}"
    - require:
      - file: /etc/kubernetes/kubevirt/multus-crd.yml

{%- if common.addons.get('kubevirt', {}).get('enabled') %}

/etc/kubernetes/kubevirt/kubevirt-operator.yml:
  file.managed:
    - source: salt://kubernetes/files/kubevirt/kubevirt-operator.yml
    - template: jinja
    - group: root
    - dir_mode: 755
    - makedirs: True

/etc/kubernetes/kubevirt/kubevirt-cr.yml:
  file.managed:
    - source: salt://kubernetes/files/kubevirt/kubevirt-cr.yml
    - template: jinja
    - group: root
    - dir_mode: 755
    - makedirs: True

kubernetes_kubevirt_operator_create:
  cmd.run:
    - name: kubectl apply -f /etc/kubernetes/kubevirt/kubevirt-operator.yml
    - require:
      - file: /etc/kubernetes/kubevirt/kubevirt-operator.yml

kubernetes_kubevirt_cr_create:
  cmd.run:
    - name: kubectl apply -f /etc/kubernetes/kubevirt/kubevirt-cr.yml
    - require:
      - file: /etc/kubernetes/kubevirt/kubevirt-cr.yml

{% endif %}

kubernetes_kubevirt_operator_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/kubevirt-operator.yml
    - onlyif: "{%- if common.addons.get('kubevirt', {}).get('enabled') == 'false' or common.addons.get('kubevirt', {}).get('enabled') == 'False' %}"
    - require:
      - file: /etc/kubernetes/kubevirt/kubevirt-operator.yml

kubernetes_kubevirt_cr_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/kubevirt-cr.yml
    - onlyif: "{%- if common.addons.get('kubevirt', {}).get('enabled') == 'false' or common.addons.get('kubevirt', {}).get('enabled') == 'False' %}"
    - require:
      - file: /etc/kubernetes/kubevirt/kubevirt-cr.yml

{% endif %}
