deploy-staging:
	ansible-playbook \
		--inventory=staging \
		--vault-password-file=.vault_pass \
		--tags deploy \
		site.yml

# made a point to capitalize PRODUCTION to help prevent accidents
deploy-PRODUCTION:
	ansible-playbook \
		--inventory=production \
		--vault-password-file=.vault_pass \
		--tags deploy \
		site.yml

provision-staging:
	ansible-playbook \
		--inventory=staging \
		--vault-password-file=.vault_pass \
		site.yml

provision-PRODUCTION:
	ansible-playbook \
		--inventory=production \
		--vault-password-file=.vault_pass \
		site.yml
