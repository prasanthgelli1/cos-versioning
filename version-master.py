from flask import Flask, request
import ibm_boto3
from ibm_botocore.client import Config, ClientError
import json
import os
app = Flask(__name__)

# Define a route for the root ("/") using the default HTTP method (GET).
class COS:
    def __init__(self,bucket_name,object_name):
        self.COS_ENDPOINT = os.getenv("COS_ENDPOINT")
        self.COS_API_KEY = os.getenv("COS_API_KEY")
        # Resource CRN
        self.COS_INSTANCE_CRN = os.getenv("COS_INSTANCE__RESOURCE_CRN")
        
        self.bucket_name = bucket_name
        self.object_name = object_name
    
    def connect(self):
        print("Connecting to COS.....")
        try:
            self.cos = ibm_boto3.resource("s3",
                ibm_api_key_id=self.COS_API_KEY,
                ibm_service_instance_id=self.COS_INSTANCE_CRN,
                config=Config(signature_version="oauth"),
                endpoint_url=self.COS_ENDPOINT
            )
            print("Connection Successfull")
            return self.cos
        except ClientError as be:
            print("CLIENT ERROR: {0}\n".format(be))
        except Exception as e:
            print("Exception due to {0}".format(e))
    
    def get_all_versions_of_object(self):
        object_versions = self.cos.Bucket(self.bucket_name).object_versions.filter(Prefix=self.object_name)
        versions_data = []

        for version in object_versions:
            tmp = {"bucket_name":version.bucket_name,"object_key":version.object_key,"id":version.id,"last_modified":version.last_modified.strftime("%Y-%m-%d %H:%M:%S")}
            versions_data.append(tmp)
        #sort based on last_modified
        versions_data = sorted(versions_data, key=lambda x: x["last_modified"],reverse=True)
        return versions_data

    def get_versions_to_delete(self,n,versions_data):
        versions_data_to_delete = versions_data[n:]
        versions_to_delete = [item["id"] for item in versions_data_to_delete]
        return versions_to_delete

    def delete_specific_version(self,object_key, version_id):
        try:
            bucket = self.cos.Bucket(self.bucket_name)

            object_version = bucket.Object(object_key).Version(version_id)
            object_version.delete()
            print(f"Version {version_id} of {object_key} in {self.bucket_name} deleted successfully.")
            return "Successfull"
        except Exception as e:
            print(f"Error deleting version {version_id} of {object_key}: {e}")
            return "Unsuccessfull"
    
    #def get_list_of_versions_to_delete(self,versions_data):



@app.route("/", methods=["POST"])
def root():
    return_payload = {}
    versions_count =  os.getenv("VERSIONS")
    event = json.loads(request.data)["notification"]
    bucket_name = event["bucket_name"]
    object_name = event["object_name"]
    print("Here is cos versioning")
    print(versions_count)
    cos = COS(bucket_name,object_name)
    cos.connect()
    versions_data = cos.get_all_versions_of_object()
    versions_to_delete = cos.get_versions_to_delete(versions_count,versions_data)
    for version_id in versions_to_delete:
        print(f"Deleting object ->{object_name} & Version {version_id} from bucket -> {bucket_name}")
        response = cos.delete_specific_version(object_name,version_id)
        return_payload[version_id] = {"bucket_name":bucket_name,"object_name":object_name,"delete_status":response}
    return return_payload
if __name__ == "__main__":
    app.run(port=8080,debug=True)
