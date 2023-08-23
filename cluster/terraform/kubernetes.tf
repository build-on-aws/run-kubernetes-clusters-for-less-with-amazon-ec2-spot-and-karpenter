resource "kubectl_manifest" "provisioner_default" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      labels:
        intent: apps
      requirements:
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: NotIn
          values: [""]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ${jsonencode(local.azs)}
      kubeletConfiguration:
        containerRuntime: containerd
        podsPerCore: 20
      limits:
        resources:
          cpu: 100000
          memory: 5000Gi
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 604800
      providerRef:
        name: default
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "node_template_default" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
      instanceProfile: ${module.eks_blueprints_addons.karpenter.node_instance_profile_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
        intent: apps
        project: karpenter-patterns
        KarpenerProvisionerName: "default"
        NodeType: "default"
        IntentLabel: "apps"
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}