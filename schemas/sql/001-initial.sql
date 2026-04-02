-- DCM PostgreSQL Schema — Initial
-- Spec ref: DCM data model doc 49, doc 51 (Infrastructure Optimization)
-- Implements: STI-001 (mandatory tenant_uuid predicate), STI-002 (RLS)
--
-- This schema implements ALL FOUR DCM data domains in a single database:
--   Intent Domain     — append-only consumer declarations
--   Requested Domain  — append-only assembled/validated payloads
--   Realized Domain   — versioned provider-confirmed state
--   Discovered Domain — ephemeral discovery snapshots
-- Plus: audit records (hash chain), operations (LRO), pipeline events, subscriptions

\connect dcm

-- ─── Extensions ──────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Tenants ──────────────────────────────────────────────────────────────────

CREATE TABLE tenants (
    tenant_uuid         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle              VARCHAR(64) UNIQUE NOT NULL,
    display_name        VARCHAR(256) NOT NULL,
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE'
                            CHECK (status IN ('ACTIVE', 'SUSPENDED', 'DECOMMISSIONED')),
    profile             VARCHAR(32) NOT NULL DEFAULT 'dev'
                            CHECK (profile IN ('minimal', 'dev', 'standard', 'prod', 'fsi', 'sovereign')),
    data_classifications_permitted  JSONB NOT NULL DEFAULT '["internal"]',
    sovereignty_zones   JSONB NOT NULL DEFAULT '[]',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Actors (users and service accounts) ──────────────────────────────────────

CREATE TABLE actors (
    actor_uuid          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_uuid         UUID NOT NULL REFERENCES tenants(tenant_uuid),
    actor_type          VARCHAR(32) NOT NULL
                            CHECK (actor_type IN ('human', 'service_account', 'system_component', 'provider')),
    handle              VARCHAR(256) NOT NULL,
    display_name        VARCHAR(256) NOT NULL,
    external_id         VARCHAR(512),           -- IDP subject claim
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_uuid, handle)
);

-- ─── Entities (Realized State) ────────────────────────────────────────────────
-- Spec ref: DCM data model doc 01 (Entity Types), doc 02 (Four States)
-- This table is the Snapshot Store — one row per realized entity per version.

CREATE TABLE realized_entities (
    realized_uuid       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_uuid         UUID NOT NULL,           -- Stable identifier across versions
    tenant_uuid         UUID NOT NULL REFERENCES tenants(tenant_uuid),
    resource_type       VARCHAR(256) NOT NULL,   -- FQN e.g. Compute.VirtualMachine
    resource_type_uuid  UUID,
    entity_type         VARCHAR(64) NOT NULL
                            CHECK (entity_type IN ('infrastructure_resource', 'composite_resource',
                                                   'process_resource', 'shared_resource', 'allocatable_pool')),
    lifecycle_state     VARCHAR(32) NOT NULL
                            CHECK (lifecycle_state IN ('PROVISIONING', 'OPERATIONAL', 'DEGRADED',
                                                       'SUSPENDED', 'FAILED', 'DECOMMISSIONED',
                                                       'INGESTED', 'INGESTION_PENDING')),
    request_uuid        UUID,                    -- The request that created/updated this
    provider_uuid       UUID,                    -- Which provider owns this entity
    realized_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    realized_by         UUID REFERENCES actors(actor_uuid),
    fields              JSONB NOT NULL DEFAULT '{}',  -- Full realized field set
    provenance          JSONB NOT NULL DEFAULT '{}',  -- Field-level provenance map
    provider_metadata   JSONB NOT NULL DEFAULT '{}',  -- Provider-supplied metadata
    sovereignty_zones   JSONB NOT NULL DEFAULT '[]',
    tags                JSONB NOT NULL DEFAULT '{}',
    version_major       INTEGER NOT NULL DEFAULT 1,
    version_minor       INTEGER NOT NULL DEFAULT 0,
    version_revision    INTEGER NOT NULL DEFAULT 0,
    is_current          BOOLEAN NOT NULL DEFAULT TRUE  -- Only one current per entity_uuid
);

CREATE INDEX idx_realized_tenant ON realized_entities(tenant_uuid);
CREATE INDEX idx_realized_entity ON realized_entities(entity_uuid);
CREATE INDEX idx_realized_lifecycle ON realized_entities(tenant_uuid, lifecycle_state);
CREATE INDEX idx_realized_resource_type ON realized_entities(tenant_uuid, resource_type);
CREATE INDEX idx_realized_current ON realized_entities(entity_uuid, is_current) WHERE is_current = TRUE;

-- ─── Operations (LRO tracking) ────────────────────────────────────────────────
-- Spec ref: doc 25 §2 (Request Orchestrator), doc 49 §7.1 (operation_uuid issuer)
-- operation_uuid == request_uuid, issued by API Gateway at ingress.

CREATE TABLE operations (
    operation_uuid      UUID PRIMARY KEY,        -- == request_uuid, issued by API Gateway
    tenant_uuid         UUID NOT NULL REFERENCES tenants(tenant_uuid),
    resource_uuid       UUID,                    -- AEP convention: the resource this operation acts on
    operation_type      VARCHAR(64) NOT NULL,    -- e.g. create_request, rehydration, discovery
    status              VARCHAR(32) NOT NULL DEFAULT 'INITIATED'
                            CHECK (status IN ('INITIATED', 'ASSEMBLING', 'POLICY_EVALUATION',
                                              'PLACEMENT', 'DISPATCHED', 'PROVISIONING',
                                              'OPERATIONAL', 'FAILED', 'CANCELLED')),
    actor_uuid          UUID REFERENCES actors(actor_uuid),
    catalog_item_uuid   UUID,
    resource_type       VARCHAR(256),
    metadata            JSONB NOT NULL DEFAULT '{}',
    score               NUMERIC(5,2),
    selected_provider_uuid UUID,
    error_code          VARCHAR(128),
    error_message       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ
);

CREATE INDEX idx_operations_tenant ON operations(tenant_uuid);
CREATE INDEX idx_operations_status ON operations(tenant_uuid, status);
CREATE INDEX idx_operations_resource ON operations(resource_uuid);

-- ─── Audit Records ────────────────────────────────────────────────────────────
-- Spec ref: DCM data model doc 16 (Universal Audit), doc 49 §3 (Hash Chain)
-- Implements: Tamper-evident hash chain with SHA-256

CREATE TABLE audit_records (
    record_uuid         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    record_timestamp    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    entity_uuid         UUID,                    -- Subject entity (if applicable)
    entity_type         VARCHAR(64),
    tenant_uuid         UUID REFERENCES tenants(tenant_uuid),
    action              VARCHAR(128) NOT NULL,   -- Closed vocabulary
    -- WHO
    immediate_actor_uuid UUID,
    immediate_actor_type VARCHAR(32),
    authorized_by_uuid   UUID,
    session_uuid         UUID,
    -- WHAT
    subject_handle      VARCHAR(512),
    before_state        JSONB,
    after_state         JSONB,
    -- HASH CHAIN (doc 49 §3)
    chain_sequence      BIGINT NOT NULL,         -- Monotonically increasing per entity
    record_hash         VARCHAR(64) NOT NULL,    -- SHA-256 of record content
    previous_record_hash VARCHAR(64),            -- Hash of sequence N-1; 'GENESIS-HASH' for first
    -- METADATA
    dcm_version         VARCHAR(32),
    request_uuid        UUID,
    policy_uuid         UUID,
    provider_uuid       UUID
);

CREATE INDEX idx_audit_entity ON audit_records(entity_uuid, chain_sequence);
CREATE INDEX idx_audit_tenant ON audit_records(tenant_uuid, record_timestamp);
CREATE INDEX idx_audit_action ON audit_records(action, record_timestamp);

-- Audit table is append-only — enforce via policy
REVOKE UPDATE, DELETE ON audit_records FROM dcm_app;
GRANT INSERT, SELECT ON audit_records TO dcm_app;
GRANT INSERT, SELECT ON audit_records TO dcm_audit;

-- ─── Providers ────────────────────────────────────────────────────────────────

CREATE TABLE providers (
    provider_uuid       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle              VARCHAR(128) UNIQUE NOT NULL,
    display_name        VARCHAR(256) NOT NULL,
    provider_type       VARCHAR(64) NOT NULL
                            CHECK (provider_type IN ('service_provider', 'information_provider',
                                                     'meta_provider', 'auth_provider',
                                                     'peer_dcm', 'process_provider')),
    status              VARCHAR(32) NOT NULL DEFAULT 'PENDING'
                            CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'DEREGISTERED', 'SANDBOX')),
    endpoint            VARCHAR(512) NOT NULL,   -- mTLS endpoint URL
    public_key_pem      TEXT,
    capabilities        JSONB NOT NULL DEFAULT '{}',
    supported_resource_types JSONB NOT NULL DEFAULT '[]',
    sovereignty_declarations JSONB NOT NULL DEFAULT '[]',
    registered_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_health_check   TIMESTAMPTZ,
    health_status       VARCHAR(32) DEFAULT 'UNKNOWN'
);

CREATE INDEX idx_providers_status ON providers(status);
CREATE INDEX idx_providers_type ON providers(provider_type, status);

-- ─── Service Catalog ──────────────────────────────────────────────────────────

CREATE TABLE catalog_items (
    catalog_item_uuid   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle              VARCHAR(128) UNIQUE NOT NULL,
    display_name        VARCHAR(256) NOT NULL,
    description         TEXT,
    resource_type       VARCHAR(256) NOT NULL,
    provider_uuid       UUID REFERENCES providers(provider_uuid),
    field_schema        JSONB NOT NULL DEFAULT '{}',  -- JSON Schema for request fields
    cost_estimate       JSONB,
    visibility_policy   JSONB NOT NULL DEFAULT '{}',  -- RBAC / group visibility rules
    status              VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    version_major       INTEGER NOT NULL DEFAULT 1,
    version_minor       INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_catalog_status ON catalog_items(status);
CREATE INDEX idx_catalog_resource_type ON catalog_items(resource_type);

-- ─── Row-Level Security (STI-001, STI-002) ────────────────────────────────────
-- Enforce tenant isolation at storage layer.
-- dcm_app cannot query across tenant boundaries.
-- dcm_admin bypasses RLS for platform admin operations (separately audited).

ALTER TABLE realized_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_realized
    ON realized_entities
    FOR ALL
    TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);

CREATE POLICY tenant_isolation_operations
    ON operations
    FOR ALL
    TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);

CREATE POLICY tenant_isolation_audit
    ON audit_records
    FOR SELECT
    TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);

-- dcm_admin bypasses RLS (explicit grant)
ALTER TABLE realized_entities FORCE ROW LEVEL SECURITY;
ALTER TABLE operations FORCE ROW LEVEL SECURITY;
GRANT ALL ON ALL TABLES IN SCHEMA public TO dcm_admin;
ALTER ROLE dcm_admin BYPASSRLS;

-- ─── Triggers ────────────────────────────────────────────────────────────────

-- Auto-set updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER operations_updated_at
    BEFORE UPDATE ON operations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Enforce append-only on audit (belt-and-suspenders beyond REVOKE)
CREATE OR REPLACE FUNCTION prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit records are immutable. Record UUID: %', OLD.record_uuid;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_immutable
    BEFORE UPDATE OR DELETE ON audit_records
    FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();

-- ─── Intent Domain (doc 51 §2.3) ────────────────────────────────────────────
-- Append-only. Raw consumer declarations. Never modified after write.

CREATE TABLE intent_records (
    intent_uuid         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_uuid         UUID NOT NULL,
    tenant_uuid         UUID NOT NULL REFERENCES tenants(tenant_uuid),
    catalog_item_uuid   UUID NOT NULL,
    submitted_by        UUID NOT NULL,
    submitted_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_via       VARCHAR(32) NOT NULL
                            CHECK (submitted_via IN ('api', 'gitops', 'cli', 'message_bus')),
    intent_version      INTEGER NOT NULL DEFAULT 1,
    fields              JSONB NOT NULL DEFAULT '{}',
    provenance          JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_intent_entity ON intent_records(entity_uuid, intent_version);
CREATE INDEX idx_intent_tenant ON intent_records(tenant_uuid, submitted_at);
REVOKE UPDATE, DELETE ON intent_records FROM dcm_app;

-- ─── Requested Domain (doc 51 §2.3) ─────────────────────────────────────────
-- Append-only. Assembled, policy-evaluated, placed payloads.

CREATE TABLE requested_records (
    requested_uuid      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_uuid         UUID NOT NULL,
    tenant_uuid         UUID NOT NULL REFERENCES tenants(tenant_uuid),
    operation_uuid      UUID NOT NULL REFERENCES operations(operation_uuid),
    intent_uuid         UUID NOT NULL REFERENCES intent_records(intent_uuid),
    resource_type       VARCHAR(256) NOT NULL,
    provider_uuid       UUID NOT NULL,
    assembled_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assembled_payload   JSONB NOT NULL DEFAULT '{}',
    layer_sources       JSONB NOT NULL DEFAULT '[]',
    policy_results      JSONB NOT NULL DEFAULT '{}',
    placement_result    JSONB NOT NULL DEFAULT '{}',
    provenance          JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_requested_entity ON requested_records(entity_uuid);
CREATE INDEX idx_requested_tenant ON requested_records(tenant_uuid);
CREATE INDEX idx_requested_operation ON requested_records(operation_uuid);
REVOKE UPDATE, DELETE ON requested_records FROM dcm_app;

-- ─── Discovered Domain (doc 51 §2.3) ────────────────────────────────────────
-- Ephemeral snapshots from provider discovery runs.

CREATE TABLE discovered_records (
    discovery_uuid      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_uuid         UUID,
    tenant_uuid         UUID REFERENCES tenants(tenant_uuid),
    provider_uuid       UUID NOT NULL,
    resource_type       VARCHAR(256) NOT NULL,
    discovered_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    discovery_run_uuid  UUID NOT NULL,
    discovered_fields   JSONB NOT NULL DEFAULT '{}',
    provider_native_id  VARCHAR(512),
    match_confidence    VARCHAR(16) DEFAULT 'exact'
                            CHECK (match_confidence IN ('exact', 'high', 'low', 'unmatched'))
);

CREATE INDEX idx_discovered_entity ON discovered_records(entity_uuid, discovered_at);
CREATE INDEX idx_discovered_run ON discovered_records(discovery_run_uuid);
CREATE INDEX idx_discovered_orphans ON discovered_records(entity_uuid) WHERE entity_uuid IS NULL;

-- ─── Pipeline Events (doc 51 §2.3) ──────────────────────────────────────────
-- Append-only event log. LISTEN/NOTIFY for real-time pipeline routing.

CREATE TABLE pipeline_events (
    event_uuid          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type          VARCHAR(128) NOT NULL,
    entity_uuid         UUID,
    request_uuid        UUID,
    tenant_uuid         UUID,
    actor_uuid          UUID,
    payload             JSONB NOT NULL DEFAULT '{}',
    published_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    consumed_by         JSONB NOT NULL DEFAULT '[]',
    consumed_at         TIMESTAMPTZ
);

CREATE INDEX idx_events_type ON pipeline_events(event_type, published_at);
CREATE INDEX idx_events_entity ON pipeline_events(entity_uuid, published_at);
CREATE INDEX idx_events_unconsumed ON pipeline_events(event_type, published_at)
    WHERE consumed_at IS NULL;
REVOKE UPDATE, DELETE ON pipeline_events FROM dcm_app;

-- Notify trigger for real-time pipeline routing
CREATE OR REPLACE FUNCTION notify_pipeline_event() RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('dcm_pipeline', json_build_object(
        'event_uuid', NEW.event_uuid,
        'event_type', NEW.event_type,
        'entity_uuid', NEW.entity_uuid
    )::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pipeline_event_notify
    AFTER INSERT ON pipeline_events
    FOR EACH ROW EXECUTE FUNCTION notify_pipeline_event();

-- ─── RLS on new tables ──────────────────────────────────────────────────────

ALTER TABLE intent_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE requested_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE discovered_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_intent ON intent_records
    FOR ALL TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);
CREATE POLICY tenant_isolation_requested ON requested_records
    FOR ALL TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);
CREATE POLICY tenant_isolation_discovered ON discovered_records
    FOR ALL TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);
CREATE POLICY tenant_isolation_events ON pipeline_events
    FOR SELECT TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);

-- ─── Subscriptions (doc 50) ──────────────────────────────────────────────────

CREATE TABLE subscriptions (
    subscription_uuid       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_uuid             UUID NOT NULL REFERENCES tenants(tenant_uuid),
    handle                  VARCHAR(256) NOT NULL,
    display_name            VARCHAR(256) NOT NULL,
    catalog_item_uuid       UUID NOT NULL,
    resource_type           VARCHAR(256) NOT NULL,
    provider_uuid           UUID NOT NULL,
    lifecycle_state         VARCHAR(32) NOT NULL DEFAULT 'PENDING'
                                CHECK (lifecycle_state IN (
                                    'PENDING', 'PROVISIONING', 'ACTIVE',
                                    'SUSPENDED', 'RENEWAL_PENDING', 'TIER_CHANGE_PENDING',
                                    'EXPIRED', 'CANCELLED', 'DECOMMISSIONING', 'DECOMMISSIONED'
                                )),
    terms                   JSONB NOT NULL DEFAULT '{}',
    entitlements            JSONB NOT NULL DEFAULT '{}',
    update_channels         JSONB NOT NULL DEFAULT '[]',
    terms_version           VARCHAR(32) NOT NULL DEFAULT '1.0.0',
    started_at              TIMESTAMPTZ,
    expires_at              TIMESTAMPTZ,
    grace_period            INTERVAL NOT NULL DEFAULT '30 days',
    auto_renew              BOOLEAN NOT NULL DEFAULT true,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_uuid, handle)
);

CREATE INDEX idx_subscriptions_tenant ON subscriptions(tenant_uuid, lifecycle_state);
CREATE INDEX idx_subscriptions_provider ON subscriptions(provider_uuid);
CREATE INDEX idx_subscriptions_expiry ON subscriptions(expires_at) WHERE lifecycle_state = 'ACTIVE';

CREATE TABLE subscription_entities (
    subscription_uuid       UUID NOT NULL REFERENCES subscriptions(subscription_uuid),
    entity_uuid             UUID NOT NULL,
    role                    VARCHAR(64) NOT NULL DEFAULT 'managed',
    bound_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (subscription_uuid, entity_uuid)
);

CREATE TABLE subscription_updates (
    update_uuid             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_uuid       UUID NOT NULL REFERENCES subscriptions(subscription_uuid),
    entity_uuid             UUID NOT NULL,
    provider_uuid           UUID NOT NULL,
    channel                 VARCHAR(64) NOT NULL,
    status                  VARCHAR(32) NOT NULL DEFAULT 'PENDING'
                                CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED',
                                                  'APPLIED', 'FAILED', 'EXPIRED')),
    update_payload          JSONB NOT NULL DEFAULT '{}',
    submitted_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    decided_at              TIMESTAMPTZ,
    decided_by              UUID,
    applied_at              TIMESTAMPTZ,
    auto_applied            BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_sub_updates_subscription ON subscription_updates(subscription_uuid, status);
CREATE INDEX idx_sub_updates_pending ON subscription_updates(status, submitted_at) WHERE status = 'PENDING';

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_subscriptions ON subscriptions
    FOR ALL TO dcm_app
    USING (tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid);
CREATE POLICY tenant_isolation_sub_entities ON subscription_entities
    FOR ALL TO dcm_app
    USING (subscription_uuid IN (
        SELECT subscription_uuid FROM subscriptions
        WHERE tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid
    ));
CREATE POLICY tenant_isolation_sub_updates ON subscription_updates
    FOR ALL TO dcm_app
    USING (subscription_uuid IN (
        SELECT subscription_uuid FROM subscriptions
        WHERE tenant_uuid = current_setting('dcm.current_tenant_uuid')::uuid
    ));
