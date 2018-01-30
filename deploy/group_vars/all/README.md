All secret variables in `./vault` should be referenced in `vars` so they're
easy to find and replaced.

Edit the `./vault` file with

```
ansible-vault --vault-password-file=~/.conch_vault_pass edit group_vars/all/vault
```
