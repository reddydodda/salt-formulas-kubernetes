kubernetes:
  common:
    cluster_domain: cluster.local
    cluster_name: cluster
    hyperkube:
      image: hyperkube-amd64:v1.6.4-3
      source: hyperkube-amd64:v1.6.4-3
      source_hash: hnsj0XqABgrSww7Nqo7UVTSZLJUt2XRd
    addons:
      dns:
        domain: cluster.local
        enabled: false
        replicas: 1
        server: 10.254.0.10
        autoscaler:
          enabled: true
      heapster_influxdb:
        enabled: true
        public_ip: 185.22.97.132
      dashboard:
        enabled: true
        public_ip: 185.22.97.131
      helm:
        enabled: true
        tiller_image: gcr.io/kubernetes-helm/tiller:v2.2.3
        client:
          source: https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-linux-amd64.tar.gz
          hash: sha256=3425a1b37954dabdf2ba37d5d8a0bd24a225bb8454a06f12b115c55907809107
      netchecker:
        enabled: true
        namespace: netchecker
        port: 80
        interval: 60
        server_image: image
        agent_image: image
        agent_probeurls: "http://ipinfo.io"
      virtlet:
        enabled: true
        namespace: kube-system
        image: mirantis/virtlet:v1.0.3
    monitoring:
      backend: prometheus
  master:
    admin:
      password: password
      username: admin
    registry:
        host: tcpcloud
    host:
      name: node040
    apiserver:
      address: 10.0.175.100
      secure_port: 6443
      internal_address: 182.22.97.1
      insecure_address: 127.0.0.1
      insecure_port: 8080
    ca: kubernetes
    enabled: true
    unschedulable: true
    etcd:
      members:
      - host: 10.0.175.100
        name: node040
    kubelet:
      address: 10.0.175.100
      allow_privileged: true
    network:
      calico:
        enabled: true
        calicoctl_source: calico/ctl
        calicoctl_source_hash: d41d8cd98f00b204e9800998ecf8427e
        image: calico/node
        kube_controllers_image: calico/kube-controllers
        etcd:
          members:
          - host: 127.0.0.1
            port: 4001
          - host: 127.0.0.1
            port: 4001
          - host: 127.0.0.1
            port: 4001
    service_addresses: 10.254.0.0/16
    storage:
      engine: glusterfs
      members:
      - host: 10.0.175.101
        port: 24007
      - host: 10.0.175.102
        port: 24007
      - host: 10.0.175.103
        port: 24007
      port: 24007
    token:
      admin: DFvQ8GJ9JD4fKNfuyEddw3rjnFTkUKsv
      controller_manager: EreGh6AnWf8DxH8cYavB2zS029PUi7vx
      dns: RAFeVSE4UvsCz4gk3KYReuOI5jsZ1Xt3
      kube_proxy: DFvQ8GelB7afH3wClC9romaMPhquyyEe
      kubelet: 7bN5hJ9JD4fKjnFTkUKsvVNfuyEddw3r
      logging: MJkXKdbgqRmTHSa2ykTaOaMykgO6KcEf
      monitoring: hnsj0XqABgrSww7Nqo7UVTSZLJUt2XRd
      scheduler: HY1UUxEPpmjW4a1dDLGIANYQp1nZkLDk
    version: v1.2.4
    namespace:
      kube-system:
        enabled: true
      netchecker:
        enabled: true
