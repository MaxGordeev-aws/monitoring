#!/bin/bash
#
# Usage:
#	Loops over the file names in <secrets_dir> and creates or updates the corresponding secrets in
#	AWS secret manager . If <secrets_dir> is not specified it defaults to "./aws/secrets".
#	<key_name> is the name of the AWS KMS key to use to create the secrets. It not specified
#	it defaults to "secretskey".
#

# TODO: add getop and proper usage doc
service=$1
secrets=$2
if [ -z "$service" ] || [ -z "$secrets" ]
then
      echo "usage: $0 <service> <secrets_directory>"
	  exit 1
fi

kmsKeyName="secretskey"
export AWS_DEFAULT_REGION=us-east-1
#kmsKeyArn=$(aws kms describe-key --key-id alias/${kmsKeyName} --query 'KeyMetadata.Arn' --output text)
secretSharingPolicy=$(cat <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "ROLE_ARN"
      },
      "Action" : "secretsmanager:GetSecretValue",
      "Resource" : "*",
      "Condition" : {
        "ForAnyValue:StringEquals" : {
          "secretsmanager:VersionStage" : "AWSCURRENT"
        }
      }
    }
  ]
}
EOF
)


for secret in $(ls ${secrets})
do
  secretkey=$service-$secret
  jsonlint -q ${secrets}/${secret}
	aws secretsmanager put-secret-value --secret-id ${secretkey%.json} \
		--secret-string file://${secrets}/${secret}

  # Presumably there is no need to update the sharing policies here?
  # Otherwise reuse the code in aws-secretsmanager-create-secrets

done

exit 0
