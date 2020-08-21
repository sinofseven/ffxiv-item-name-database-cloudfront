SHELL = /usr/bin/env bash -xeuo pipefail

stack_name:=ffxiv-item-name-database-cloudfront

describe:
	poetry run aws cloudformation describe-stacks \
		--stack-name $(stack_name) \
		--query Stacks[0].Outputs

deploy:
	poetry run aws cloudformation deploy \
		--stack-name $(stack_name) \
		--template-file template.yml \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--role-arn $$CLOUDFORMATION_DEPLOY_ROLE_ARN \
		--no-fail-on-empty-changeset
	poetry run aws cloudformation describe-stacks \
		--stack-name $(stack_name) \
		--query Stacks[0].Outputs

destroy:
	poetry run aws cloudformation delete-stack --stack-name $(stack_name)
	poetry run aws cloudformation wait stack-delete-complete --stack-name $(stack_name)

.PHONY: \
	describe \
	deploy \
	destroy 
