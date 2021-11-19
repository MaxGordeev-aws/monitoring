#!/bin/bash
#
# Usage:
# k8s-inject-aws-secrets <service_name> [ <secrets_dir> ]
#	Loops over the file names in <secrets_dir> and imports the corresponding secrets from
#	AWS secret manager into the current namespace in k8s. If <secrets_dir> is not specified
#	it defaults to "./aws/secrets".
#

set -e

export AWS_DEFAULT_REGION=us-east-1
service=$1
namespace=$2
secrets=$3
if [ -z "$service" ] || [ -z "$namespace" ] || [ -z "$secrets" ]
then
      echo "usage: $0 <service> <namespace> <secrets_directory>"
	  exit 1
fi

secretsYaml=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: SERVICE_NAME-SECRET_NAME
type: Opaque
data:
EOF
)

for secret in $(ls $secrets); do
    secretkey=$service-$secret
	value=$(aws secretsmanager get-secret-value --secret-id ${secretkey%.json} \
		| jq --raw-output '.SecretString' \
		| jq -r 'to_entries[] | "  \(.key): \(.value | @base64)"')
	((echo "$secretsYaml" \
		| sed "s/SERVICE_NAME/${service}/g; s/SECRET_NAME/${secret%.json}/g;") && echo "${value}") \
        | kubectl -n $namespace apply -f -
done

exit 0