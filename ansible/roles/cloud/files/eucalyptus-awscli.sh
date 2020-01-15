#!/bin/sh
# Wrapper for awscli providing eucalyptus integration
# alias aws='/path/to/awscli-eucalyptus.sh'

AWS_ARGS=( "$@" )
AWS_PROFILE=""
AWS_REGION="${AWS_DEFAULT_REGION}"
AWS_SERVICE=""
AWS_ENDPOINT=""

while (( "$#" )); do
  AWS_ARG="$1"
  case "${AWS_ARG}" in
    --debug|--no-verify-ssl|--no-paginate|--no-sign-request)
      ;;
    --endpoint)
      shift
      AWS_ENDPOINT="$1"
      ;;
    --profile)
      shift
      AWS_PROFILE="$1"
      ;;
    --region)
      shift
      AWS_REGION="$1"
      ;;
    --*)
      shift
      ;;
    *)
      AWS_SERVICE="${AWS_SERVICE:-$1}"
      ;;
  esac
  shift
done

if [ -z "${AWS_REGION}" ] ; then
  if [ -z "${AWS_PROFILE}" ] ; then
    AWS_REGION="$(aws configure get region)"
  else
    AWS_REGION="$(aws --profile '${AWS_PROFILE}' configure get region)"
  fi
fi

if [ "${AWS_REGION}" = "eucalyptus" ] && [ -z "${AWS_AUTO_SCALING_URL}" ]; then
  eval $(euca-generate-environment-config)
fi

AWS_EXTRA_ARGS=""
if [ -z "${AWS_ENDPOINT}" ] ; then
  case "${AWS_SERVICE}" in
    autoscaling)
      AWS_ENDPOINT="${AWS_AUTO_SCALING_URL}"
      ;;
    cloudformation)
      AWS_ENDPOINT="${AWS_CLOUDFORMATION_URL}"
      ;;
    cloudwatch)
      AWS_ENDPOINT="${AWS_CLOUDWATCH_URL}"
      ;;
    ec2)
      AWS_ENDPOINT="${EC2_URL}"
      ;;
    elb)
      AWS_ENDPOINT="${AWS_ELB_URL}"
      ;;
    iam)
      AWS_ENDPOINT="${AWS_IAM_URL}"
      ;;
    s3|s3api)
      AWS_ENDPOINT="${S3_URL}"
      ;;
    sts)
      AWS_ENDPOINT="${TOKEN_URL}"
      ;;
  esac

  if [ ! -z "${AWS_ENDPOINT}" ] ; then
    AWS_EXTRA_ARGS="--endpoint ${AWS_ENDPOINT}"
  fi
fi

exec aws ${AWS_EXTRA_ARGS} "${AWS_ARGS[@]}"
