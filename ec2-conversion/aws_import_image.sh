#!/usr/bin/env bash
RELEASE_VERSION=$1
VERSION=$2

importId=$(aws ec2 import-image --description 'Nimbus Server Import' --license-type BYOL --disk-containers Description='Nimbus Server Import',Format=vmdk,UserBucket=\{S3Bucket=s3-adm-ftp,S3Key=nimbusserver-beta/${RELEASE_VERSION}/vmdk/disk.vmdk\} | jq -r .ImportTaskId )
printf '%s\n' "${importId}"
importStatus=$(aws ec2 describe-import-image-tasks --import-task-ids ${importId} | jq -r .ImportImageTasks[0].Status)
while [[ ${importStatus} == "active" ]]; do
  sleep 300
  importStatus=$(aws ec2 describe-import-image-tasks --import-task-ids ${importId} | jq -r .ImportImageTasks[0].Status)
  printf '%s\n' "$importStatus"
done

importObject=$(aws ec2 describe-import-image-tasks --import-task-ids ${importId})
imageId=$(printf '%s\n' "$importObject" | jq -r .ImportImageTasks[0].ImageId)
echo ${imageId}

imageStatus=$(aws ec2 describe-images --image-ids ${imageId})
while [[ ${imageStatus} == "pending" ]]; do
  sleep 300
  imageStatus=$(aws ec2 describe-images --image-ids ${imageId})
  echo Import Image Status - ${imageStatus}
done

echo "Create Instance - to set EBS to self terminate"
instanceId=$(aws ec2 run-instances --image-id ${imageId} --count 1 --instance-type t2.xlarge --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":true}}]" | jq -r .Instances[0].InstanceId )

instanceStatus=$(aws ec2 describe-instance-status --instance-id ${instanceId} --output text --query "InstanceStatuses[*].InstanceStatus.Status")
while [[ ${instanceStatus} != "ok" ]]; do
  sleep 60
  instanceStatus=$(aws ec2 describe-instance-status --instance-id ${instanceId} --output text --query "InstanceStatuses[*].InstanceStatus.Status")
  echo Instance Status - ${instanceStatus}
done

echo "Stopping Instance"
aws ec2 stop-instances --instance-ids ${instanceId}
instanceStatus=$(aws ec2 describe-instances --instance-id ${instanceId} | jq -r .Reservations[0].Instances[0].State.Name)
while [[ ${instanceStatus} != "stopped" ]]; do
  sleep 60
  instanceStatus=$(aws ec2 describe-instances --instance-id ${instanceId} | jq -r .Reservations[0].Instances[0].State.Name)
  echo Instance Status - ${instanceStatus}
done

echo "Creating Image from Stopped Instance"
copyId=$(aws ec2 create-image --instance-id ${instanceId} --region us-east-1 --name nimbusserver-${RELEASE_VERSION} --description nimbusserver-${RELEASE_VERSION} | jq -r .ImageId )
copyStatus=$(aws ec2 describe-images --image-ids ${copyId})
while [[ $copyStatus == "pending" ]]; do
  sleep 300
  copyStatus=$(aws ec2 describe-images --image-ids ${copyId})
  echo ${copyStatus}
done

echo "Set name tag for new image"
aws ec2 create-tags --resources ${copyId} --tags Key=Name,Value=nimbusserver-${RELEASE_VERSION}

echo "Delete Instance"
aws ec2 terminate-instances --instance-ids ${instanceId}

copyStatus=$(aws ec2 describe-images --image-ids ${copyId})
while [[ $copyStatus == "terminated" ]]; do
  sleep 10
  copyStatus=$(aws ec2 describe-images --image-ids ${copyId})
  echo ${copyStatus}
done

deregisterObject=$(aws ec2 deregister-image --image-id ${imageId})
printf '%s\n' "$deregisterObject"