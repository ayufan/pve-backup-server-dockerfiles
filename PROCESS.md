# Upgrade to new release

## My own release procedure

```bash
# Fork the build
make fork-version NEW_VERSION=2.3.2 NEW_SHA=e6120a8f6ff36f627a4da3a1a51a1e47231f5cc8

# Try to naively apply patches
# Fix patches until it succeeds
make tmp-env
make tmp-env-client

# Try to naively compile first
cd tmp/v2.3.2/proxmox-backup
cargo build

# Try to run dev build first
make dev-run

# Try to compile first locally
make amd64-docker-build
make amd64-client

# Create release package
make github-pre-release

# Mark the current version as latest
make github-latest-release
```

## Build on your own

Refer to [PROESS.md](PROCESS.md).

```bash
make dev-build
```

It builds on any platform, which can be: `amd64`, `arm32v7`, `arm64v8`,
etc. Wait a around 1-3h to compile.

Then you can push to your registry:

```bash
make dev-push
```

Or run locally:

```bash
make dev-shell
make dev-run
```

You might as well pull the `*.deb` from within the image
and install on Debian Bullseye.
