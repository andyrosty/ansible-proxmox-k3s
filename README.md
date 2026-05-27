# ansible-proxmox-k3s

Ansible playbooks to prepare Ubuntu VMs on Proxmox for k3s, install the cluster, and deploy a small smoke test workload.

## What's inside

- `Makefile` — shortcuts for the most common Ansible commands
- `inventory/hosts.ini` — cluster inventory
- `inventory/group_vars/` — place for shared variables such as `common_packages`
- `playbooks/preflight.yml` — read-only host checks
- `playbooks/bootstrap.yml` — host prep for Kubernetes
- `playbooks/install-k3s.yml` — installs the control plane and workers
- `playbooks/cluster-status.yml` — quick cluster health snapshot
- `playbooks/deploy-smoke-test.yml` / `playbooks/delete-smoke-test.yml` — manage the demo app
- `kubernetes/smoke-test/` — Kubernetes manifests used by the smoke test
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

## Running the playbooks

The `Makefile` wraps the common commands so you do not have to remember each playbook path.

| Target | Description |
| --- | --- |
| `make ping` | `ansible all -m ping` for a quick reachability test |
| `make inventory` | Graphs the inventory to verify host grouping |
| `make preflight` | Runs `playbooks/preflight.yml` to gather read-only health info |
| `make bootstrap` | Runs `playbooks/bootstrap.yml` to prep every node for k3s |
| `make install-k3s` | Runs `playbooks/install-k3s.yml` to install the control plane and workers |
| `make status` | Runs `playbooks/cluster-status.yml` for node/pod/service snapshots |
| `make deploy-smoke` | Applies the manifests in `kubernetes/smoke-test` via `playbooks/deploy-smoke-test.yml` |
| `make delete-smoke` | Cleans up the smoke test namespace with `playbooks/delete-smoke-test.yml` |

A typical workflow after populating the inventory is:

```bash
make ping
make preflight
make bootstrap
make install-k3s
make status
make deploy-smoke # optional validation app
```

All targets simply wrap `ansible` or `ansible-playbook`, so you can still invoke the commands directly if preferred.

## Smoke test manifests

`kubernetes/smoke-test/` holds a minimal namespace, deployment, and service that deploy an NGINX pod set labelled for homelab testing. The deploy/delete playbooks copy these files to the control plane and run `k3s kubectl apply/ delete`. Modify the manifests to fit your own validation workload if desired.

## What bootstrap does

- updates APT cache
- installs `common_packages`
- disables swap
- enables `overlay` and `br_netfilter`
- applies Kubernetes sysctl settings
- starts `qemu-guest-agent` if available

## License

MIT — see `LICENSE`.
