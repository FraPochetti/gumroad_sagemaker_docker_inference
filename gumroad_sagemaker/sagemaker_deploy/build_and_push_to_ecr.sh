TAG="gumroad"
IMAGE_URI="custom-images"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION="eu-west-1"

docker build -t $TAG -f Dockerfile.ModelS3 .
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker tag $TAG:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$IMAGE_URI:$TAG
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$IMAGE_URI:$TAG

aws ecr describe-repositories --region $REGION \
| jq --raw-output .repositories[].repositoryName \
| while read repo; do  
    imageIds=$(aws ecr list-images --region $REGION --repository-name $repo --filter tagStatus=UNTAGGED --query 'imageIds[*]' --output json | jq -r '[.[].imageDigest] | map("imageDigest="+.) | join (" ")');
    if [[ "$imageIds" == "" ]]; then continue; fi
    aws ecr batch-delete-image --region $REGION --repository-name $repo --image-ids $imageIds; 
done