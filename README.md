## Build Instructions

- To build with the default options, simply run `docker buildx bake`.
- To build a specific target, use `docker buildx bake <target>`.
- To specify the platform, use `docker buildx bake <target> --set <target>.platform=linux/amd64`.

Example:

```bash
docker buildx bake 240-py311-cuda1241-devel-ubuntu2204 --set 240-py311-cuda1241-devel-ubuntu2204.platform=linux/amd64
```

## Exposed Ports

- 22/tcp (SSH)
- 8888/tcp (Jupyter Lab)

## Jupyter Lab Auto-Shutdown

This container includes an automatic shutdown feature for Jupyter Lab:

- Jupyter Lab will automatically shut down after a period of inactivity (default: 60 minutes)
- When Jupyter Lab shuts down, the container will also terminate
- You can customize the idle timeout by setting the `JUPYTER_IDLE_TIMEOUT` environment variable (in minutes)

Example:

```bash
# Run with a 30-minute idle timeout
docker run -e JUPYTER_IDLE_TIMEOUT=30 -e JUPYTER_PASSWORD=yourpassword your-image-name
```

This feature helps save resources by automatically stopping containers that are no longer in use.