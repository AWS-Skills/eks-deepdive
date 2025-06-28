#!/bin/bash
export aws_region=""
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl -n argo-rollouts patch deployment argo-rollouts --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--aws-verify-target-group"]}]'
kubectl -n argo-rollouts set env deployment argo-rollouts AWS_REGION=$aws_region
kubectl -n argo-rollouts rollout status deploy argo-rollouts

curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
kubectl argo rollouts version
cat <<EOF >kubectl_complete-argo-rollouts
#!/usr/bin/env sh
# Call the __complete command passing it all arguments
kubectl argo rollouts __complete "\$@"
EOF
chmod +x kubectl_complete-argo-rollouts
sudo mv ./kubectl_complete-argo-rollouts /usr/local/bin/