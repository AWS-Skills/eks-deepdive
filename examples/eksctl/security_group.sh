#!/bin/bash

cluster_name=""
bastion_id=$(ec2-metadata -i | cut -d " " -f 2)
cluster_sg=$(aws eks describe-cluster --name $cluster_name --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
bastion_sg=$(aws ec2 describe-instances --instance-ids $bastion_id --query "Reservations[].Instances[].SecurityGroups[].GroupId" --output text)
aws ec2 modify-instance-attribute --instance-id $bastion_id --groups $bastion_sg $cluster_sg