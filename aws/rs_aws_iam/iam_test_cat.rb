name 'iam test CAT'
rs_ca_ver 20161221
short_description "Amazon Web Services - IAM"
long_description "creates and destroys test IAM role and policy"
import "plugins/rs_aws_iam"


output "role_name" do
  label "IAM Role Name"
  default_value @my_role.RoleName
end

output "policy_name" do
  label "IAM Policy Name"
  default_value @my_policy.PolicyName
end

resource "my_role", type: "rs_aws_iam.role" do
  name 'MyTestRole'
  assume_role_policy_document <<-EOS
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":["ec2.amazonaws.com"]},"Action":["sts:AssumeRole"]}]}
EOS
  description "test role description"
  max_session_duration 3600
end

resource "my_policy", type: "rs_aws_iam.policy" do
  name "MyTestPolicy"
  policy_document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListAllMyBuckets",
"Resource":"arn:aws:s3:::*"},{"Effect":"Allow","Action":["s3:Get*","s3:List*"],"Resource":
["arn:aws:s3:::EXAMPLE-BUCKET","arn:aws:s3:::EXAMPLE-BUCKET/*"]}]}'
  description "test policy description"
end
