# S3 Plugin (MinIO / S3 via aioboto3)

Native-async S3 / MinIO integration using a shared long-lived **aioboto3** client, named buckets in YAML, and bucket-scoped FastAPI DI.

## When to use

Use the S3 plugin when:

- Talking to MinIO or any S3-compatible endpoint from a FastAPI app.
- Declaring multiple logical buckets and injecting a bucket-scoped client via `Depends`.
- Needing STORAGE health / readiness status for object storage.

## S3Plugin

### YAML configuration

```yaml
s3:
  endpoint_url: "${S3_ENDPOINT_URL}"
  access_key_id: "${S3_ACCESS_KEY_ID}"
  secret_access_key: "${S3_SECRET_ACCESS_KEY}"
  region: "${S3_REGION:us-east-1}"
  tls_verify: true
  ca_bundle: null
  buckets:
    media: "${S3_BUCKET_MEDIA}"
    thumbnails: "${S3_BUCKET_THUMBNAILS}"
```

Logical keys under `buckets` are what DI uses; values are physical bucket names. Buckets must already exist (the plugin does not create them). Startup hard-fails if a declared bucket is missing.

Production defaults: `region=us-east-1`, `tls_verify=true`, botocore `signature_version=s3v4`, path-style addressing, connect timeout 5s, read timeout 60s, standard retries (`max_attempts=5`).

### Application setup

```python
from fastapi_factory_utilities.core.plugins.s3_plugin import S3Plugin

S3Plugin()                             # all buckets from YAML
S3Plugin(keys=["media", "thumbnails"]) # subset only
```

Register via `ApplicationGenericBuilder.add_plugin_to_activate()` or your builder's `get_default_plugins()`.

## Dependency injection

```python
from fastapi import Depends
from fastapi_factory_utilities.core.plugins.s3_plugin import (
    S3BucketDepends,
    S3BucketResource,
    depends_s3_client,
)

async def upload(
    media: S3BucketResource = Depends(S3BucketDepends("media")),
) -> None:
    await media.client.put_object(
        Bucket=media.bucket_name,
        Key="object.txt",
        Body=b"payload",
    )

async def list_all(client=Depends(depends_s3_client)) -> None:
    await client.list_buckets()
```

`S3BucketResource` exposes:

- `key` — logical name from YAML
- `bucket_name` — physical bucket name
- `client` — shared async aiobotocore S3 client (do not open a per-request client)

## Lifecycle

- `on_load` — parse / validate YAML (or injected `S3Config`); no network
- `on_startup` — enter shared client via `AsyncExitStack`, soft-fail warm `list_buckets`, hard-fail `head_bucket` per declared bucket, register STORAGE status
- `on_shutdown` — close the exit stack (client)

## Source

- `src/fastapi_factory_utilities/core/plugins/s3_plugin/`
