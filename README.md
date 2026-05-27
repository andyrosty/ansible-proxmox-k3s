# ansible-proxmox-k3s

Simple Ansible playbooks for preparing Ubuntu virtual machines on Proxmox for a k3s cluster.

This repository currently helps you:

- define your k3s nodes in one inventory
- run basic preflight checks against all nodes
- bootstrap Ubuntu hosts with the settings Kubernetes usually needs

It does **not** install k3s yet. It prepares the machines so they are ready for the next step.

## What is in this repo

```text
.
├── ansible.cfg              # Ansible configuration for this project
├── inventory/hosts.ini      # Your control-plane and worker nodes
├── playbooks/
│   ├── preflight.yml        # Read-only checks
│   └── bootstrap.yml        # Host preparation tasks
└── requirements.yml         # Required Ansible collections
```

## What the playbooks do

### `playbooks/preflight.yml`

Runs checks on every host in `k3s_cluster` and prints useful information such as:

- hostname
- Ubuntu version
- kernel version
- CPU and memory
- network routes
- swap status
- presence of common tools
- Kubernetes-related kernel modules
- Kubernetes-related sysctl values

Use this first to confirm the machines are reachable and look healthy.

### `playbooks/bootstrap.yml`

Prepares every host in `k3s_cluster` by:

- updating the APT cache
- installing base packages from `common_packages`
- disabling swap now and on reboot
- loading `overlay` and `br_netfilter`
- persisting those kernel modules
- applying Kubernetes networking sysctl settings
- starting `qemu-guest-agent` if it is installed

## Requirements

Before running the playbooks, make sure you have:

- Ansible installed on your control machine
- SSH access to all target Ubuntu nodes
- a remote user that can use `sudo`
- Python available on the Ubuntu hosts

This project also uses the `community.general` Ansible collection.

Install it with:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Inventory

The inventory lives in `inventory/hosts.ini`.

Current example:

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

You can replace these hostnames and IP addresses with your own.

## Ansible configuration

The project is already configured to:

- use `inventory/hosts.ini`
- connect as the `andrew` user by default
- use `ansible/roles` and `ansible/collections`
- cache facts in `.ansible/facts`
- write logs to `.ansible/logs/ansible.log`

If your SSH username is different, update this line in `ansible.cfg`:

```ini
remote_user = andrew
```

## Important note about `common_packages`

`playbooks/bootstrap.yml` installs packages from a variable named `common_packages`:

```yaml
name: "{{ common_packages }}"
```

That variable is not defined in this repository yet, so you should define it before running the bootstrap playbook.

One easy option is to create `inventory/group_vars/k3s_cluster.yml` with content like:

```yaml
common_packages:
  - curl
  - git
  - vim
  - qemu-guest-agent
  - apt-transport-https
  - ca-certificates
```

## Quick start

### 1. Install the collection

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Update the inventory

Edit `inventory/hosts.ini` and replace the sample IP addresses with your own node addresses.

### 3. Set the SSH user if needed

If you do not log in as `andrew`, update `ansible.cfg`.

### 4. Define `common_packages`

Create `inventory/group_vars/k3s_cluster.yml` and add your package list.

### 5. Test connectivity

```bash
ansible k3s_cluster -m ping
```

### 6. Run preflight checks

```bash
ansible-playbook playbooks/preflight.yml
```

### 7. Bootstrap the nodes

```bash
ansible-playbook playbooks/bootstrap.yml
```

## Example workflow

```bash
ansible-galaxy collection install -r requirements.yml
ansible k3s_cluster -m ping
ansible-playbook playbooks/preflight.yml
ansible-playbook playbooks/bootstrap.yml
```

## Troubleshooting

### SSH fails

Check:

- the IP addresses in `inventory/hosts.ini`
- your SSH key access
- that the remote user exists
- that the remote user has sudo permissions

### Bootstrap fails on `common_packages`

Make sure you created `inventory/group_vars/k3s_cluster.yml` and defined the variable.

### `qemu-guest-agent` task reports issues

The playbook is written to avoid failing if the service is unavailable, which is useful when the package is not installed yet.

## Next steps

After these hosts are prepared, the next logical step is to add playbooks for:

- installing k3s on the control-plane node
- joining worker nodes to the cluster
- copying kubeconfig for local access
- deploying common add-ons such as MetalLB, ingress, or cert-manager

## License

This project is licensed under the MIT License. See `LICENSE` for details.