# Environment Variables

All environment variables that need to be set for the app to run.

### Database

- term **DATABASE_HOST**: The database host.
- term **DATABASE_PORT**: The database port. *Optional*.
- term **POSTGRES_USER**: The postges username.
- term **POSTGRES_PASSWORD**: The postgres password. *Optional*.

    If no password is specified no password will be used to try an access the database.
- term **POSTGRES_DB**: The postgres database name.

### Redis

- term **REDIS_HOST**: The redis url.

### Elasticsearch

- term **ELASTIC_URL**: The elasticsearch url.

### MMDB

- term **MMDB_PATH**: The maxmind GeoLite2 db path inside the resources directory.

### E-Mail

- term **SMTP_USERNAME**: The email address used for sending mails.
- term **SEND_MAILS**: Wether or not the backend system should send emails. *Optional*.

    If this argument is not set, `true` will be assumed. 

### App

- term **APP_URL**: The user facing app url.
- term **APP_NAME**: The app name.
- term **SOFT_DELETED_LIFETIME**: The lifetime of soft deleted models in days. *Optional*.

    It is used to determine when to delete a soft deleted model in the cleanup job.

    If no value is set the soft deleted models won't be deleted.
- term **OLD_VERIFIED_LIFETIME**:The lifetime of old verified models in days. *Optional*.

    It is used to determine when to delete an old verified model in the cleanup job.

    An old verified model is a verified model, that is no longer in use since it was updated or patched.

    If no value is set the old verified models won't be deleted.
- term **DEFAULT_LOCATION_LATITUDE**: The latitude of the default location used when no other location is available.
- term **DEFAULT_LOCATION_LONGITUDE**: The longitude of the default location used when no other location is available.
