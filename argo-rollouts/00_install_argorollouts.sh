#!/bin/bash
export CLUSTER_NAME=""
export AWS_REGION=""
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
aws iam create-policy \
--policy-name ArgoRolloutsIAMPolicy \
--policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTargetHealth"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}'
eksctl create iamserviceaccount \
--cluster=$CLUSTER_NAME --namespace=argo-rollouts --name=argo-rollouts \
--role-name ArgoRolloutsRole \
--attach-policy-arn="arn:aws:iam::$ACCOUNT_ID:policy/ArgoRolloutsIAMPolicy" \
--override-existing-serviceaccounts --approve
kubectl -n argo-rollouts patch deployment argo-rollouts --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--aws-verify-target-group"]}]'
kubectl -n argo-rollouts set env deployment argo-rollouts AWS_REGION=$AWS_REGION
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