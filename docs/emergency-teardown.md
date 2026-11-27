# Emergency teardown
NEVER run a plain `terraform destroy`: it also deletes ECR and the CI role.

1. Release Kubernetes-created resources:
   kubectl delete -f k8s/argocd/apps.yaml --ignore-not-found
   kubectl delete ingress --all -A
   kubectl delete pvc --all -A
2. Wait until this prints nothing (ALB gone):
   aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName" --output text
3. Delete leftover controller security groups:
   aws ec2 describe-security-groups --filters "Name=group-name,Values=k8s-*" --query "SecurityGroups[].GroupId" --output text
   aws ec2 delete-security-group --group-id sg-XXXX
4. Targeted destroy (from infra/terraform/envs/dev):
   terraform destroy -target=module.eks -target=aws_eks_addon.ebs_csi -target=module.ebs_csi_irsa -target=module.alb_controller_irsa -target=module.eso_irsa -target=module.cluster_autoscaler_irsa -target=module.vpc
5. Verify all empty: eks list-clusters, NAT gateways, Elastic IPs, EBS volumes, load balancers, VPCs.
