# Jenkins Build Jobs

# Overview
Jenkins jobs for use with eucalyptus build, deploy, and test.

These are known to work with the following jenkins and plugins versions:

* Jenkins 2.46.3
* Copy Artifact Plugin 1.39
* user build vars plugin 1.5

The above plugins are required.

# Setup
For initial setup you can copy the jobs to a jenkins install or use the jenkins cli.

## Jenkins global configuraiton
There are various global environment variables that may be configured to customize the deployment:

| Name | Example | Description |
| --- | --- | --- |
| EUCALYPTUS_GLOBAL_CLOUD_OPTS | -Xmx4g | Cloud options for every deployment |
| EUCALYPTUS_GLOBAL_COBBLER_SERVER | 1.2.3.4 | IP address of the cobbler server |
| EUCALYPTUS_GLOBAL_DNS_SERVER | 1.2.3.4 | IP address of the dns server |
| EUCALYPTUS_GLOBAL_DOCKER_PULLS | false | Should images be automatically updated? |
| EUCALYPTUS_GLOBAL_DOCKER_RUN_OPTS | --dns 1.2.3.4 | Any additional docker options for run commands |
| EUCALYPTUS_GLOBAL_EUCA2OOLS_YUM_REPO |  | Local euca2ools mirror |
| EUCALYPTUS_GLOBAL_EUCALYPTUS_DNS_DOMAIN |  | Domain name pattern for deployments |
| EUCALYPTUS_GLOBAL_EUCALYPTUS_YUM_REPO |  | 4.4.2 eucalyptus mirror |
| EUCALYPTUS_GLOBAL_EUCALYPTUS_YUM_REPO_DEV |  | 4.4.x eucalyptus repository (development rpms) |
| EUCALYPTUS_GLOBAL_IMAGE_BASE_URL |  | Base URL for testing artifacts and images |
| EUCALYPTUS_GLOBAL_NET_GATEWAY |  | Local network setting |
| EUCALYPTUS_GLOBAL_NET_NETMASK |  | Local network setting |
| EUCALYPTUS_GLOBAL_NET_SUBNET |  | Local network setting |
| EUCALYPTUS_GLOBAL_NODE_MAX_CORES |  | Max cores default |
| EUCALYPTUS_GLOBAL_NODE_NIC | en1 | Network interface for target hosts |
| EUCALYPTUS_GLOBAL_NTP_SERVER | 1.2.3.4 | FQDN or IP of the ntp server to use |
| EUCALYPTUS_GLOBAL_RPM_DIST | myrpms.el7 | Name to identify rpm distribution |

There are also secrets that must be configured for the deployment / host jobs:

| Name | Description |
| --- | --- |
| EUCALYPTUS_GLOBAL_SSH_KEY | The ssh private key to use for accessing target hosts |


## Jenkins job configuration
There are a couple of configuration jobs that must be run to configure local information such as the available hosts and storage.

* eucalyptus-44-qa-deploy-template-aliases
* eucalyptus-host-config

# Jobs

## eucalyptus-44-build-cloud-libs-rpm
Build a eucalyptus cloud libs 4.4.x rpm containing 3rd party dependencies.

The output of this job is used when building the main eucalyptus rpms.

## eucalyptus-44-build-release-rpms
Build all rpms for a eucalyptus cloud 4.4.x release. An informational label can be specified for the build, e.g.:

* snap : this is a snapshot build
* rc1 : a release candidate for testing

The output of this job is suitable for upload to an rpm repository.

## eucalyptus-44-build-rpms
Build the eucalyptus cloud 4.4.x rpms for the main eucalyptus github repository.

## eucalyptus-44-qa-deploy
Deploy a cloud with released or development versions of Eucalyptus from packages or source.

Templates are available or a custom environment can be specified.

## eucalyptus-44-qa-deploy-template-aliases
Build the template aliases that are used for deployments. This can include information on local infrastructure (i.e. ceph)

## eucalyptus-44-qa-fast
Run the N4J short test suite against a cloud.

This job is optionally run after deploying a cloud.

## eucalyptus-44-qa-nephoria
Run the full nephoria test suite against a cloud.

## eucalyptus-44-qa-suite
Run a selected N4J test suite against a cloud, some useful. There are suites for cloud initialization, a "nightly" suite and service specific suites.


