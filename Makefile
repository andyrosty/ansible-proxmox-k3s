.PHONY: ping inventory preflight bootstrap install-k3s install-flux status storage-status deploy-smoke delete-smoke reset-k3s

ping:
	ansible all -m ping

inventory:
	ansible-inventory --graph

preflight:
	ansible-playbook playbooks/preflight.yml

bootstrap:
	ansible-playbook playbooks/bootstrap.yml

install-k3s:
	ansible-playbook playbooks/install-k3s.yml

status:
	ansible-playbook playbooks/cluster-status.yml

deploy-smoke:
	ansible-playbook playbooks/deploy-smoke-test.yml

delete-smoke:
	ansible-playbook playbooks/delete-smoke-test.yml

reset-k3s:
	ansible-playbook playbooks/reset-k3s.yml

site:
	ansible-playbook playbooks/site.yml \
    	-e github_token="$(GITHUB_TOKEN)" \
		-e cloudflare_api_token="$(CLOUDFLARE_API_TOKEN)"

configure-cert-manager-secrets:
	ansible-playbook playbooks/configure-cert-manager-secrets.yml \
		-e cloudflare_api_token="$(CLOUDFLARE_API_TOKEN)"

install-flux:
	ansible-playbook playbooks/install-flux.yml -e github_token="$(GITHUB_TOKEN)"

storage-status:
	ansible-playbook playbooks/storage-status.yml
