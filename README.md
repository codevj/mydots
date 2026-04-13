# mydots

Personal productivity hacks, desktop tweaks, and automation scripts.

This repository is my central place for practical setup files that make daily Linux usage faster and smoother.

## What this repo contains

- Linux desktop setup scripts
- Device and input customization
- Window/workflow automation
- Tool installation helpers

## Current structure

- `linux/` - Linux-specific configs and setup scripts
  - `install.sh` - Install core productivity tools (logiops, Kando, Tactile)
  - `logid.cfg` - Logitech device button/gesture mappings for `logid`
  - `save-restart.sh` - Deploy `logid.cfg` and restart `logid`
  - `README.md` - Linux setup and troubleshooting notes

## Quick start

From the repository root:

```bash
cd linux
./install.sh
```

To install only one component:

```bash
./install.sh logiops
./install.sh kando
./install.sh tactile
```

## Goal

Keep all personal productivity tweaks versioned, reproducible, and easy to reapply on a fresh system.
