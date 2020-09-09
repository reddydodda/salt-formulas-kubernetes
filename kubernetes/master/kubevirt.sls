{%- from "kubernetes/map.jinja" import common with context -%}
{%- from "kubernetes/map.jinja" import master with context -%}
{%- from "kubernetes/map.jinja" import version %}
{%- if master.enabled %}

{%- if common.addons.get('multus', {}).get('enabled') %}

/etc/kubernetes/kubevirt/multus-crd.yml:
  file.managed:
    - source: salt://kubernetes/files/kube-addons/multus/multus-crd.yml
    - template: jinja
    - group: root
    - dir_mode: 755
    - makedirs: True

/etc/kubernetes/kubevirt/multus-nad.yml:
  file.managed:
    - source: salt://kubernetes/files/kube-addons/multus/multus-nad.yml
    - template: jinja
    - group: root
    - dir_mode: 755
    - makedirs: True

kubernetes_multus_crd_create:
  cmd.run:
    - name: kubectl apply -f /etc/kubernetes/kubevirt/multus-crd.yml
    - require:
      - file: /etc/kubernetes/kubevirt/multus-crd.yml

kubernetes_multus_nad_create:
  cmd.run:
    - name: kubectl apply -f /etc/kubernetes/kubevirt/multus-nad.yml
    - require:
      - file: /etc/kubernetes/kubevirt/multus-nad.yml

{% endif %}

{%- if not common.addons.get('multus', {}).get('enabled') %}

kubernetes_multus_nad_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/multus-nad.yml
    - onlyif: "kubectl get sa -n kube-system -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep multus"

kubernetes_multus_crd_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/multus-crd.yml
    - onlyif: "kubectl get sa -n kube-system -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep multus"

/etc/cni/net.d/00-multus.conf:
  file.absent

{% endif %}

{%- if common.addons.get('kubevirt', {}).get('enabled') %}

/etc/kubernetes/kubevirt/kubevirt-operator.yml:
  file.managed:
    - source: salt://kubernetes/files/kube-addons/kubevirt/kubevirt-operator.yml
    - template: jinja
    - group: root
    - dir_mode: 755
    - makedirs: True

/etc/kubernetes/kubevirt/kubevirt-cr.yml:
  file.managed:
    - source: salt://kubernetes/files/kube-addons/kubevirt/kubevirt-cr.yml
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

{%- if not common.addons.get('kubevirt', {}).get('enabled') %}

kubernetes_kubevirt_cr_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/kubevirt-cr.yml
    - onlyif: "kubectl get ns -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep kubevirt"

kubernetes_kubevirt_operator_delete:
  cmd.run:
    - name: kubectl delete -f /etc/kubernetes/kubevirt/kubevirt-operator.yml
    - onlyif: "kubectl get ns -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep kubevirt"

{% endif %}

{% endif %}
