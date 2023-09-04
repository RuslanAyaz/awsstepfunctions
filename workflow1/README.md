# workflow1

This project contains source code and supporting files for a serverless application that can be deployed with the SAM CLI. It includes the following files and folders:

- docs - The workflow diagram.
- functions - Code for the application's Lambda functions.
- statemachines - Definition for the state machine that orchestrates the workflow.
- template.yaml - A template that defines the application's AWS resources.

This application creates a AWS Step Functions workflow which runs on a pre-defined schedule.

The application uses several AWS resources, including Step Functions state machines, Lambda functions and an EventBridge rule trigger. These resources are defined in the `template.yaml` file in this project.

## Build and deploy

The Serverless Application Model Command Line Interface (SAM CLI) is an extension of the AWS CLI that adds functionality for building and testing Lambda applications.

To use the SAM CLI, you need the following tools:

* SAM CLI - [Install the SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
* Ruby - [Install Ruby 2.7](https://www.ruby-lang.org/en/documentation/installation/)

To build and deploy your application for the first time, run the following in your shell:

```bash
workflow1$ sam build
workflow1$ sam deploy --guided
```

The first command will build the source of the application. The second command will package and deploy your application to AWS, with a series of prompts.

## Cleanup

To delete the sample application that is created, use the SAM CLI. Assuming that the project name is used for the stack name, the following could be run:

```bash
workflow1$ sam delete --stack-name workflow1
```
