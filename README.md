## Infrastructure automation with AWS Step Functions

These projects serve as examples for building workflows in AWS and are available for use by anyone.

### workflow1

Description: Restore the prod RDS Cluster snapshot into the staging RDS cluster and redeploy the application environment. This process is repeated every day to ensure that the staging environment has fresh data. Old staging RDS resources are deleted after restoration. [Workflow diagram](./workflow1/docs/workflow_graph.svg)

  - Application environment: Laravel Vapor
  - Lambda functions runtime: ruby2.7

Notes:
  - cost is optimized to use free Step Functions Wait state instead of being charged for Lambda function usage time.
  - some of the infrastructure parameters are hardcoded in the [statemachine file](./workflow1/statemachine/statemachine.asl.json). For example, instance type, DB engines, etc.