# canonical-ubuntu-advanced Helm Chart

## Installation

```shell
helm -n portal install voyager oci://cr.virtomat.io/virtomat/portal/helm/voyager
```

## Secret Management

### Keycloak/OIDC Client Secret

By default, the chart uses a plaintext `proxy.CLIENT_SECRET` value. To reference a Kubernetes Secret instead, set `proxy.keycloak.secret_name` and `proxy.keycloak.client_secret_key`:

```yaml
proxy:
  keycloak:
    secret_name: my-keycloak-secret
    client_secret_key: client-secret
```

### Cookie Secret

By default, the chart uses a plaintext `proxy.COOKIE_SECRET` value. To reference a Kubernetes Secret instead, set `proxy.cookie.secret_name` and `proxy.cookie.secret_key`:

```yaml
proxy:
  cookie:
    secret_name: my-cookie-secret
    secret_key: cookie-secret
```

### Upgrade Safety

When `secret_name` is configured for a credential, the chart renders an explicit empty `value` alongside `valueFrom`. This ensures upgrades from legacy inline credentials are safe under Kubernetes strategic merge — the old inline value is cleared rather than lingering.

### Redis Session Store

Two independent controls govern Redis:

| Value | Purpose | Default |
|---|---|---|
| `redis.enabled` | Deploys the Bitnami Redis subchart | `false` |
| `proxy.redis.enabled` | Renders Redis session-store env vars in the oauth2-proxy container | `true` |

**Typical deployment with external Redis (e.g. Valkey):**

```yaml
redis:
  enabled: false          # no Bitnami resources created
proxy:
  redis:
    enabled: true         # oauth2-proxy still gets Redis env vars
    connection_url: redis://valkey-external:6379
    secret_name: external-valkey-secret
    secret_key: password
```

**Disable Redis session store entirely:**

```yaml
proxy:
  redis:
    enabled: false
```

### Example: Plaintext Fallback (Deprecated)

```yaml
proxy:
  CLIENT_SECRET: "plaintext-client-secret"
  COOKIE_SECRET: "plaintext-cookie-secret"
  keycloak:
    secret_name: ""
  cookie:
    secret_name: ""
```

**Note**: Plaintext fields are deprecated. Configure `secret_name` for deployment. Never commit real secrets to version control. Use Kubernetes Secrets or external secret management solutions.