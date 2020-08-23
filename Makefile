SHELL = /usr/bin/env bash -xeuo pipefail

stack_name:=ffxiv-item-name-database-cloudfront
template_path:=dist/template.yml

build:
	rm -rf dist; \
	name="rust_build"; \
	docker image build -t $$name .; \
	docker container run --name $$name $$name; \
	docker container cp $$name:/code/target/lambda/release/ build; \
	docker container rm $$name; \
	docker image rm $$name; \
	mkdir dist; \
	cp build/*.zip dist/; \
	rm -rf build;

package:
	poetry run aws cloudformation package --s3-bucket $$SAM_ARTIFACT_BUCKET --output-template-file $(template_path) --template-file sam.yml

deploy: package
	poetry run aws cloudformation deploy \
		--stack-name $(stack_name) \
		--template-file $(template_path) \
		--capabilities CAPABILITY_IAM \
		--role-arn $$CLOUDFORMATION_DEPLOY_ROLE_ARN \
		--no-fail-on-empty-changeset
	poetry run aws cloudformation describe-stacks \
		--stack-name $(stack_name) \
		--query Stacks[0].Outputs
