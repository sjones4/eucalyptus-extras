# QA on AWS
CloudFormation and other templates for Eucalyptus cloud development and
testing using AWS.

AWS Region
----------
Releases, test builds, and test assets are in the `us-west-1` region so
that should be used for testing and development.

AWS Setup
---------
Tests use ECR for n4j and nephoria container images:

* `ecr-repositories-template.yaml`
* `policy.json`

The policy can be used when configuring a user to run the tests.

Azure DevOps
------------
Piplines for testing and development that use these templates are in
the [project](https://dev.azure.com/corymbia/eucalyptus/):

* `eucalyptus-qa-devel` : Manual test/development template, manually released!
* `eucalyptus-qa-test-n4j-short` : QA short pre-merge test
* `eucalyptus-qa-test-ciab-ceph-n4j` : Release QA pipeline for CIAB/Ceph n4j testing
* `eucalyptus-qa-test-ciab-ceph-nephoria` : Release QA pipeline for CIAB/Ceph nephoria testing
* `eucalyptus-qa-test-ciab-overlay-n4j` : Release QA pipeline for CIAB/Overlay/Walrus n4j testing
* `eucalyptus-qa-test-mzmn-n4j` : Release QA pipeline for MZMN/Ceph n4j testing
* `eucalyptus-qa-test-mzmn-nephoria` : Release QA pipeline for MZMN/Ceph nephoria testing

`CIAB` is a single (metal) host for cloud-in-a-box testing.

`MZMN` is for multiple zones each with multiple nodes allowing all tests to be run.
