# Configure COS Bucket for Version Management

## Outline
This project configures the cos bucket to maintain last n iterations of the object.  

  

### Steps involved for configuration are
1. Loging in IBM Cloud using ibmcloud cli
2. Cloning the code repository and constructing an image containing a Flask server for version management.
3. The build image is pushed to IBM CONTAINER REGISTRY or ICR which will be further deployed in code engine
4. Creating an Code Engine Project to deploy the build image 
5. Configuring the Notification Manager to serve as a bridge between the created Code Engine project and the Cloud Object Storage (COS) instance.
6. Create a registry secret in Code Engine to retrieve the pushed image from the IBM Container Registry (ICR).
7. Deploy the application
8. Create an Event Subscription in Code Engine.


## Pre-requisites
1. Install ibmcloud-cli
2. Install podman



## Configuration Steps
1. Fill all the parameters encoded with "<>" symbol in provision.sh 
   1. IBM Cloud Credentials
      1. ibm_cloud_registry=`"<IBM CLOUD REGISTRY>"` #Example -> "us.icr.io/cos"
      2. ibm_cloud_api_key=`"<IBM CLOUD API KEY>"`
      3. ibm_cloud_email=`"<IBM CLOUD EMAIL>"` #Example -> "abc@***.com"
   2. COS Configuration
      1. cos_instance_name=`"<COS INSTANCE NAME>"` #Example -> "cos-versioning-demo"
      2. cos_bucket_name=`"<COS BUCKET NAME>"` #Example -> "cos-versioning-demo-bucket"cos_api_key="<COS INSTANCE API KEY>"
      3. cos_api_key=`"<COS INSTANCE API KEY>"`
      4. cos_api_endpoint=`"<COS INSTANCE API ENDPOINT>"` #Example -> "https://s3.us-south.cloud-object-storage.appdomain.cloud"
      5. cos_resource_crn=`"<COS INSTANCE RESOURCE CRN>"`
      6. cos_bucket_versions=`<NUMBER OF VERSIONS TO MAINTAIN>`

2. Add permissions to provision.sh script using the command `chmod 600 provision.sh`
3. Run provision.sh script using the command `./provision.sh`

