## My own release procedure

```bash
# The current version
make amd64-build amd64-push
DOCKER_CONTEXT=oracle-arm64 make arm64v8-build arm64v8-push
make all-manifest

# Create release package
make all-release

# Mark the current version as latest
make all-latest
```