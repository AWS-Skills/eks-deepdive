#!/bin/bash
export AWS_REGION=""
export CLUSTER_NAME=""
# echo "AWS_REGION=''" >>/home/ec2-user/.bashrc
# echo "CLUSTER_NAME=''" >>/home/ec2-user/.bashrc
source /home/ec2-user/.bashrc
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/lbc-helm.html

OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $OIDC_ID
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
aws iam list-open-id-connect-providers | grep $OIDC_ID | cut -d "/" -f4

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/docs/install/iam_policy.json
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://iam_policy.json
rm iam_policy.json

eksctl create iamserviceaccount \
--cluster=$CLUSTER_NAME \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--role-name AmazonEKSLoadBalancerControllerRole \
--attach-policy-arn="arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy" \
--approve --region $AWS_REGION
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
--set clusterName=$CLUSTER_NAME \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set region=$AWS_REGION \
--set vpcId=$VPC_ID
kubectl rollout status -n kube-system deploy aws-load-balancer-controller