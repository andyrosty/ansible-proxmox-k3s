# ansible-proxmox-k3s

Ansible playbooks to prepare Ubuntu VMs on Proxmox for a k3s cluster.

This repo does not install k3s yet. It gets the nodes ready first.

## Files

- `inventory/hosts.ini` — cluster inventory
- `playbooks/preflight.yml` — read-only host checks
- `playbooks/bootstrap.yml` — host prep for Kubernetes
- `requirements.yml` — required Ansible collection

## Requirements

- Ansible on your control machine
- SSH access to the Ubuntu nodes
- a remote user with `sudo`
- Python on the target hosts

Install the collection:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Setup

### 1. Update inventory

Edit `inventory/hosts.ini` with your control-plane and worker IPs.

### 2. Set the SSH user if needed

`ansible.cfg` defaults to:

```ini
remote_user = andrew
```

Change it if your SSH username is different.

### 3. Define `common_packages`

`playbooks/bootstrap.yml` expects a `common_packages` variable.

Create `inventory/group_vars/k3s_cluster.yml`:

```yaml
common_packages:
  - curl
  - git
  - vim
  - qemu-guest-agent
  - apt-transport-https
  - ca-certificates
```

## Usage

Test connectivity:

```bash
ansible k3s_cluster -m ping
```

Run preflight checks:

```bash
ansible-playbook playbooks/preflight.yml
```

Bootstrap the nodes:

```bash
ansible-playbook playbooks/bootstrap.yml
```

## What bootstrap does

- updates APT cache
- installs `common_packages`
- disables swap
- enables `overlay` and `br_netfilter`
- applies Kubernetes sysctl settings
- starts `qemu-guest-agent` if available

## License

MIT — see `LICENSE`.
