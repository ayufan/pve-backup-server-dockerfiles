## My own release procedure

```bash
# Fork the build
make fork-version NEW_VERSION=2.3.2 NEW_SHA=e6120a8f6ff36f627a4da3a1a51a1e47231f5cc8

# Try to naively apply patches
make tmp-env
make tmp-env-client

# Try to naively compile first
cd tmp/v2.3.2/proxmox-backup
cargo build

# Try to compile first locally 
make amd64-docker-build
make amd64-client

# Create release package
make github-pre-release

# Mark the current version as latest
make github-latest-release
```