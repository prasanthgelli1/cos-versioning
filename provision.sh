#!/bin/bash


# Set your variables
repository_url="https://github.com/prasanthgelli1/cos-versioning.git"
image_name="cos-versioning"
tag="latest"
code_engine_project="cos-versioning"

#IBM Cloud Credentials
ibm_cloud_registry="us.icr.io/cos" #Example -> "us.icr.io/cos"
ibm_cloud_api_key="<IBM CLOUD API KEY>"
ibm_cloud_email="<IBM CLOUD EMAIL>" #Example -> "abc@***.com"

#COS Configuration
cos_instance_name="<COS INSTANCE NAME>" #Example -> "cos-versioning-demo"
cos_bucket_name="<COS BUCKET NAME" #Example -> "cos-versioning-demo-bucket"
cos_api_key="<COS INSTANCE API KEY>"
cos_api_endpoint="<COS INSTANCE API ENDPOINT>" #Example -> "https://s3.us-south.cloud-object-storage.appdomain.cloud"
cos_resource_crn="<COS INSTANCE RESOURCE CRN>" 
cos_bucket_versions="<NUMBER OF VERSIONS TO MAINTAIN>" #Example -> 4

# Logging into ibmcloud account
echo "Logging in to IBM Cloud account"
ibmcloud config --check-version=false
ibmcloud login -r us-south --apikey $ibm_cloud_api_key
ibmcloud target -g Default

# Clone the Git repository
git clone $repository_url

# Change to the cloned repository directory
cd $(basename $repository_url .git)

# Build the container image using Podman
podman build -t $image_name:$tag .

# Log in to IBM Cloud Container Registry
echo "Logging in to IBM Cloud Container Registry..."
ibmcloud cr login

# Tag the container image for IBM Cloud Container Registry
podman tag $image_name:$tag $ibm_cloud_registry/$image_name

# Push the container image to IBM Cloud Container Registry
echo "Pushing the image to IBM Cloud Container Registry..."
podman push $ibm_cloud_registry/$image_name:$tag

# Clean up - Remove local container image & Clones Repo
echo "Cleaning up..."
echo "Deleting Cloned repo"
rm -rf cos-versioning/

echo "Removing Build Local Image"
podman rmi $image_name:$tag

# Create a new Code Engine Project
echo "Creating new Code Engine Project with name $code_engine_project"
ibmcloud ce project create --name $code_engine_project

# Select the newly Created Code Engine Project
echo "Selecting $code_engine_project project"
ibmcloud ce project select -n $code_engine_project

# Assigning the Notifications Manager role to Code Engine
echo "Assigning the Notifications Manager role to Code Engine"
ibmcloud iam authorization-policy-create codeengine cloud-object-storage "Notifications Manager" \
 --source-service-instance-name $code_engine_project \
 --target-service-instance-name $cos_instance_name

# # Creating Code Engine registry secret to pull image from ICR
IFS="/" read -ra parts <<< "$ibm_cloud_registry"
registry_server="${parts[0]}"
echo "Registry Server is $registry_server"


echo "Creating Code Engine registry secret to pull image from ICR"
ibmcloud ce registry create --name cos-versioning-secret \
 --username iamapikey \
 --password $ibm_cloud_api_key \
 --server $registry_server \
 --email $ibm_cloud_email

# Deploying the custom cos-versioning app to code engine
echo "Creating cos-versioning-app application in code engine"
ibmcloud ce app create --name cos-versioning-app \
 --image $ibm_cloud_registry/$image_name \
 --registry-secret cos-versioning-secret \
 --env COS_ENDPOINT=$cos_api_endpoint --env COS_INSTANCE__RESOURCE_CRN=$cos_resource_crn \
 --env COS_API_KEY=$cos_api_key \
 --env VERSIONS=$cos_bucket_versions

# Create an event subscription
echo "Creating an event subscription"
ibmcloud ce sub cos create \
 --name cos-versioning-subscription \
 --destination cos-versioning-app \
 --bucket $cos_bucket_name \
 --event-type all \
 --path /
ibmcloud ce subscription cos get -n cos-versioning-subscription


