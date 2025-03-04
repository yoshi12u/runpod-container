## Build Instructions

- To build with the default options, simply run `docker buildx bake`.
- To build a specific target, use `docker buildx bake <target>`.
- To specify the platform, use `docker buildx bake <target> --set <target>.platform=linux/amd64`.

## Google Cloud Authentication

This container includes Google Cloud SDK for accessing Google Cloud services. To authenticate with Google Cloud, you can use one of the following methods:

### Using Application Default Credentials

Set the `GOOGLE_APPLICATION_CREDENTIALS_JSON` environment variable with the contents of your application default credentials JSON file:

```bash
# When running the container locally
docker run -e GOOGLE_APPLICATION_CREDENTIALS_JSON="$(cat /path/to/your/credentials.json)" ...

# When using RunPod
# Add GOOGLE_APPLICATION_CREDENTIALS_JSON as a Secret in the RunPod UI
```

### Using Service Account Key

Set the `GOOGLE_SERVICE_ACCOUNT_KEY_JSON` environment variable with the contents of your service account key JSON file:

```bash
# When running the container locally
docker run -e GOOGLE_SERVICE_ACCOUNT_KEY_JSON="$(cat /path/to/your/service-account-key.json)" ...

# When using RunPod
# Add GOOGLE_SERVICE_ACCOUNT_KEY_JSON as a Secret in the RunPod UI
```

### Setting Project ID

You can also set the Google Cloud project ID:

```bash
# When running the container locally
docker run -e GOOGLE_PROJECT_ID="your-project-id" ...

# When using RunPod
# Add GOOGLE_PROJECT_ID as a Secret in the RunPod UI
```

After the container starts, the Google Cloud SDK will be automatically configured with your credentials.
