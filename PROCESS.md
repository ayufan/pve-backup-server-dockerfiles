# Upgrade to new release

## My own release procedure

```bash
# Update repos to latest version
# Find the sha from the https://git.proxmox.com/?p=proxmox-backup.git;a=summary
scripts/update-version.bash v3.2.7 cb3d41e838dec0e1002aaf5ee4c0e6cd28284c74

# Try to naively apply patches
# Fix patches until it succeeds
make tmp-env
make tmp-env-client
make tmp-docker-shell

# Try to naively compile first
cd tmp/v3.2.7/proxmox-backup
cargo build

# Try to run dev build first
make dev-run
make dev-shell

# Compile and push
make amd64-docker-build
make amd64-client
make github-pre-release
make github-latest-release
```

Replace `amd64` with `arm32v7` (unlikely to work) and `arm64v8`.
