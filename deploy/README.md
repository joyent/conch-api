All secret variables in `group_vars/all/vault` should be referenced in
`group_vars/all/vars` so they're easy to find and replaced.

Edit the `group_vars/all/vault` file with

```
ansible-vault --vault-password-file=~/.conch_vault_pass edit group_vars/all/vault
```
