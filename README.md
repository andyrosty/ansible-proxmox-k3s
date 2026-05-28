# ansible-proxmox-k3s

End‑to‑end Ansible automation to prepare Ubuntu VMs on Proxmox, install a multi‑node k3s cluster, and bootstrap FluxCD GitOps from a GitHub repository.

---

## Repository layout

- `Makefile` — shortcuts for the most common Ansible commands
- `inventory/hosts.ini` — cluster inventory (control plane + workers)
- `inventory/group_vars/all.yml` — global settings, SSH user, common packages, timezone
- `inventory/group_vars/flux.yml` — FluxCD / GitHub bootstrap settings
- `playbooks/site.yml` — end‑to‑end run: preflight → bootstrap → k3s → Flux → checks
- `playbooks/preflight.yml` — read‑only host checks
- `playbooks/bootstrap.yml` — host prep for Kubernetes
- `playbooks/install-k3s.yml` — installs the k3s control plane and workers
- `playbooks/cluster-status.yml` — quick cluster health snapshot
- `playbooks/storage-status.yml` — storage / PVC overview
- `playbooks/install-flux.yml` — installs Flux CLI and bootstraps Flux against GitHub
- `playbooks/deploy-smoke-test.yml` / `playbooks/delete-smoke-test.yml` — manage the demo app
- `kubernetes/smoke-test/` — Kubernetes manifests used by the smoke test
- `requirements.yml` — required Ansible collection(s)

---

## Requirements

- Ansible on your control machine
- SSH access to the Ubuntu nodes from the control machine
- A remote user with `sudo` access
- Python 3 on the target hosts
- A GitHub account and a GitHub Personal Access Token (PAT) with permissions for the Flux bootstrap repo

Install the Ansible collection(s):

```bash
ansible-galaxy collection install -r requirements.yml
```

---

## Inventory and variables

### 1. Inventory: hosts and groups

Edit `inventory/hosts.ini` with your actual hostnames/IPs:

```ini
[k3s_control]
k3s-control-01 ansible_host=192.168.50.147

[k3s_workers]
k3s-worker-01 ansible_host=192.168.50.132
k3s-worker-02 ansible_host=192.168.50.110

[k3s_cluster:children]
k3s_control
k3s_workers
```

You can rename hosts or add more workers as needed; just keep the `k3s_control` and `k3s_workers` groups intact.

### 2. Global settings (`inventory/group_vars/all.yml`)

`all.yml` defines the SSH user, Python interpreter, timezone, and the baseline packages that will be installed on every node:

```yaml
ansible_user: andrew
ansible_python_interpreter: /usr/bin/python3

timezone: America/New_York

common_packages:
  - curl
  - vim
  - git
  - ca-certificates
  - gnupg
  - lsb-release
  - qemu-guest-agent
  - net-tools
  - htop
  - unzip
```

Update `ansible_user`, `timezone`, and the package list to match your environment.

### 3. Flux / GitHub settings (`inventory/group_vars/flux.yml`)

Flux bootstrap is configured via `inventory/group_vars/flux.yml`:

```yaml
flux_github_owner: "andyrosty"        # GitHub user or org
flux_github_repository: "homelab-services"
flux_github_branch: "main"
flux_cluster_path: "clusters/homelab" # path inside the repo for this cluster
flux_personal_repo: true               # true if this is a user repo instead of org
flux_token_auth: true                  # use token auth (recommended)
```

Change these values to point to your own GitHub owner/repo/branch and desired cluster path.

---

## GitHub token for Flux

Flux bootstrapping requires a GitHub Personal Access Token (PAT). The playbooks assume you will provide it via an Ansible extra var called `github_token` and usually set it via an environment variable `GITHUB_TOKEN`.

### 1. Create a GitHub PAT

In GitHub:

1. Go to **Settings → Developer settings → Personal access tokens**.
2. Create a **fine‑grained** or **classic** token.
3. Grant it access to the repository defined in `flux.yml` (owner + repo).
4. As a minimum, ensure it has permissions to:
   - Read/write **Contents**
   - Read/write **Metadata** / **Administration** of that repo (depending on the token type)
5. Copy the generated token.

On your local machine, export it as an environment variable (so it does not end up in your shell history):

```bash
export GITHUB_TOKEN="<your-token-here>"
```

Make sure you do not commit this value into version control.

---

## Running the playbooks

The `Makefile` wraps the most common operations so you do not have to remember the full `ansible-playbook` commands.

### Make targets

| Target | Command | Description |
| --- | --- | --- |
| `make configure-cert-manager-secrets` | `ansible-playbook playbooks/configure-cert-manager-secrets.yml -e cloudflare_api_token="$(CLOUDFLARE_API_TOKEN)"` | Create/update Cloudflare API token secret for cert-manager |
| `make ping` | `ansible all -m ping` | Quick reachability test |
| `make inventory` | `ansible-inventory --graph` | Verify inventory and groups |
| `make preflight` | `ansible-playbook playbooks/preflight.yml` | Read‑only health checks on all nodes |
| `make bootstrap` | `ansible-playbook playbooks/bootstrap.yml` | OS prep for k3s (packages, kernel settings, swap off, etc.) |
| `make install-k3s` | `ansible-playbook playbooks/install-k3s.yml` | Install k3s control plane and workers |
| `make status` | `ansible-playbook playbooks/cluster-status.yml` | Node/pod/service snapshot |
| `make storage-status` | `ansible-playbook playbooks/storage-status.yml` | Cluster storage / PVC status |
| `make deploy-smoke` | `ansible-playbook playbooks/deploy-smoke-test.yml` | Deploy the NGINX smoke‑test app |
| `make delete-smoke` | `ansible-playbook playbooks/delete-smoke-test.yml` | Remove the smoke‑test app |
| `make install-flux` | `ansible-playbook playbooks/install-flux.yml -e github_token="$(GITHUB_TOKEN)"` | Install Flux CLI and bootstrap Flux against GitHub |
| `make site` | `ansible-playbook playbooks/site.yml -e github_token="$(GITHUB_TOKEN)" -e cloudflare_api_token="$(CLOUDFLARE_API_TOKEN)"` | End‑to‑end run: preflight → bootstrap → k3s → cert-manager secret → Flux → checks |

All targets simply wrap `ansible` or `ansible-playbook`, so you can always run the equivalent commands manually.

### Running the full site playbook

After inventory and variables are in place and both `GITHUB_TOKEN` and `CLOUDFLARE_API_TOKEN` are exported, you can run an end‑to‑end cluster + Flux install with:

```bash
make site
```

or equivalently:

```bash
ansible-playbook playbooks/site.yml -e github_token="$GITHUB_TOKEN" -e cloudflare_api_token="$CLOUDFLARE_API_TOKEN"
```

This runs, in order:

1. `preflight.yml`
2. `bootstrap.yml`
3. `install-k3s.yml`
4. `cluster-status.yml`
5. `configure-cert-manager-secrets.yml`
6. `install-flux.yml`
7. `cluster-status.yml` (post‑Flux)
8. `storage-status.yml`

Before running any playbooks that interact with GitHub or Cloudflare, export the required tokens on your control machine:

```bash
export GITHUB_TOKEN="<your-github-token>"
export CLOUDFLARE_API_TOKEN="<your-cloudflare-token>"
```

### Installing Flux only

If k3s is already installed and working and you only want to (re)bootstrap Flux:

```bash
ansible-playbook playbooks/install-flux.yml -e github_token="$GITHUB_TOKEN"
```

or via Make:

```bash
make install-flux
```

---

## Smoke test manifests

`kubernetes/smoke-test/` holds a minimal namespace, deployment, and service that deploy an NGINX pod set labeled for homelab testing. The deploy/delete playbooks copy these files to the control plane and run `k3s kubectl apply` / `k3s kubectl delete` against the cluster.

Use the smoke test to validate that basic scheduling, service routing, and your storage setup behave as expected after a fresh install.

---

## What bootstrap does

`playbooks/bootstrap.yml` is responsible for preparing each Ubuntu node for k3s. At a high level it:

- Updates APT cache
- Installs `common_packages`
- Configures the system timezone
- Disables swap
- Enables the `overlay` and `br_netfilter` kernel modules
- Applies Kubernetes‑recommended sysctl settings
- Ensures `qemu-guest-agent` is installed and started (when applicable)

---

## License

MIT — see `LICENSE`.

