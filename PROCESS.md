# Upgrade to new release

## My own release procedure

```bash
# Update repos to latest version
# Find the sha from the https://git.proxmox.com/?p=proxmox-backup.git;a=summary
scripts/update-version.bash v3.2.7 cb3d41e838dec0e1002aaf5ee4c0e6cd28284c74

# Try to run dev build first
./env.bash

# And then
scripts/make-all.bash

# You can then try to compile image
./release.bash build-deb
./release.bash build-tgz
./release.bash client-tgz
```
