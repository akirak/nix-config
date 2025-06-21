# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Structure

I am currently migrating this configuration to a `flake-parts`-based setup to
[denix](https://yunfachi.github.io/denix/getting_started/introduction)-based.

### Old configuration (with flake-parts)

This is a NixOS homelab configuration repository using flake-parts for modular
organization. The repository manages multiple machines, home-manager
configurations, and shared NixOS profiles.

#### Key Directories

- `flake-parts/` - Modular flake configuration split by functionality (nixos,
  home-manager, deploy, etc.)
- `machines/` - Per-host configurations with dedicated flake-modules
- `nixos/` - Shared NixOS configurations organized into profiles, suites, and models
- `homes/` - Home-manager configurations with modules for user environments
- `secrets/` - Age-encrypted secrets managed with agenix-rekey
- `templates/` - Flake templates for new configurations

#### Architecture Overview

The configuration uses a layered architecture:
1. **Flake-parts modules** (`flake-parts/*.nix`) provide top-level organization
2. **Machine modules** (`machines/*/flake-module.nix`) define individual hosts
3. **NixOS suites** (`nixos/suites/`) bundle common profile sets (base, desktop, server, etc.)
4. **NixOS profiles** (`nixos/profiles/`) provide specific service configurations
5. **Home configurations** (`homes/*.nix`) manage user environments with modular imports

Machines are defined in `machines/metadata.toml` with network topology, SSH keys, and service identifiers.

### New configuration (with denix)

The denix configuration is kept under `denix/` directory.
`denix/flake-module.nix` is a flake-parts module that integrates NixOS and
home-manager configuration into the `flake.nix` of the repository.

- `denix/`: The new denix-based configurations
  - `flake-module.nix`: A flake-parts module that exports the configurations
  - `hosts/`: Denix hosts
  - `modules/`: Denix modules

This repository contains no rice.

## Common Commands

### Building and Deployment

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.yang.config.system.build.toplevel

# Deploy to remote host (available hosts: yang, wang, li, shu, hui, zheng)
nix run .#deploy-yang -- switch
nix run .#deploy-yang -- test  # test without activation

# Deploy with custom target IP
nix run .#deploy-yang -- --target-host 192.168.10.10 switch
```

### Development Environment

```bash
# Enter default development shell (includes age, age-plugin-yubikey, agenix-rekey)
nix develop

# Enter caddy development shell (for certificate management)
nix develop .#caddy
```

### Code Quality and Formatting

```bash
# Run all formatters and linters
nix fmt

# Check for dead code
nix run nixpkgs#deadnix

# Format shell scripts
nix run nixpkgs#shellcheck
```

### Secret Management

```bash
# Rekey all secrets (requires yubikey)
agenix rekey

# Edit a secret
agenix edit secrets/example.age

# Add new secret for host
agenix rekey -a secrets/newsecret.age -p yang
```

### Home Manager

Home manager configurations are integrated into NixOS hosts via the `hmProfile` module. Individual home configurations can be built with:

```bash
# Build home configuration
nix build .#homeConfigurations.username.activationPackage
```

## Host Information

Hosts are managed through `machines/metadata.toml`:
- **zheng** (192.168.10.1) - Router with DHCP and DNS services
- **yang** (192.168.10.10) - Main server with reverse proxy, Docker, and development services
- **wang** (192.168.10.11) - Desktop workstation
- **li** (192.168.10.60) - Storage server with Syncthing
- **shu**, **hui** - Additional hosts

I am currently trying to migrate the hosts to denix. `denix/hosts/denix-sandbox`
is a minimal NixOS virtual machine defined as a denix host.

## Key Configuration Patterns

### Adding New Hosts

### Adding NixOS Profiles

### Adding Home Manager Modules

## Virtual machines

Unless specifically noted, MicroVM hosts should run on cloud-hypervisor.

## Security Notes

- Secrets are managed with agenix-rekey and stored in `secrets/rekeyed/`
- Master identity is a Yubikey (`secrets/yubikey.pub`)
- SSH host keys are extracted from `machines/metadata.toml`
- Age encryption targets both host keys and backup keys
