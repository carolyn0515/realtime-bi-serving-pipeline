# ADR-0001: Use A Publish Gate Before BI Serving

## Status

Proposed

## Context

Realtime window aggregation can produce numbers quickly, but fast numbers are not always trustworthy. Late events, malformed payloads, stale metadata, or broken upstream jobs can make a dashboard misleading.

## Decision

BI queries will read only from published mart tables. A window is copied from staging to published only after passing DQ audit checks.

## Consequences

- BI users get a stable trust boundary.
- Failed windows are visible in audit tables but hidden from published BI metrics.
- The pipeline needs explicit publish and refresh logic.
