---
name: query-evp-directly
description: Query Datadog Events Platform (EVP) data directly from Codex with dd-curl/dd-auth, especially llmobs event list and count queries. Use when the user asks to verify events in EVP, query llmobs, check feedback/eval-metric events, translate an eventsPlatform.eventList or eventsPlatform.scalar React hook into curl, or run direct staging/prod event list/count checks.
---

# Query EVP Directly

Use this skill to query Event Platform data without the browser UI. Prefer staging (`dd.datad0g.com`) unless the user explicitly asks for prod.

## Authentication

Use the Datadog auth curl wrapper when `dd-curl` is not available in the non-interactive shell:

```bash
/home/bits/.codex/plugins/cache/datadog-claude-plugins/dd/local/skills/live-test-api/scripts/dd-auth-curl.sh \
  --domain dd.datad0g.com -- \
  "https://dd.datad0g.com/<path>" \
  -sS -w "\nHTTP_STATUS:%{http_code}\n" \
  -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
  --data-binary "@/tmp/payload.json"
```

If using the user's `dd-curl` shell function, load it from an interactive zsh shell. Note that API/app-key auth works for the logs analytics endpoints below, but browser/user-auth routes like `/api/unstable/llm-obs-query-rewriter/list` can return `401`.

## LLM Observability List Query

For `eventsPlatform.eventList` requests with `query.data_source: "llm_observability_stream"`, query the downstream list endpoint directly:

```text
POST https://dd.datad0g.com/api/v1/logs-analytics/list?type=llmobs
```

Payload shape:

```json
{
  "list": {
    "columns": [],
    "limit": 10,
    "time": {
      "from": 1779376593792,
      "to": 1779377493792
    },
    "search": {
      "query": "@event_type:eval-metric @event_kind:feedback"
    },
    "includeEvents": true,
    "computeCount": false,
    "indexes": ["llmobs"],
    "executionInfo": {
      "includeAttachments": false
    }
  }
}
```

This is the direct equivalent of the React hook:

```ts
useDataSources([
  {
    source: 'eventsPlatform.eventList',
    request: {
      response_format: 'event_list',
      columns: [],
      query: {
        data_source: 'llm_observability_stream',
        indexes: ['llmobs'],
        query_string: '@event_type:eval-metric @event_kind:feedback',
        storage: 'hot',
      },
    },
    timeFrame: { start, end, paused: false },
    limit: 10,
    track: 'llmobs',
    includeAttachments: false,
  },
]);
```

Use `computeCount: false` for event retrieval. Inspect `result.events[*].event.custom` for fields such as `event_type`, `event_kind`, `eval_scope`, `span_id`, `id`, `submitter`, and `text_value`.

## LLM Observability Count Query

For count-only checks, use the aggregate endpoint:

```text
POST https://dd.datad0g.com/api/v1/logs-analytics/aggregate?type=llmobs
```

Payload shape:

```json
{
  "aggregate": {
    "compute": [
      {
        "total": {
          "metric": "count",
          "output": "count:count",
          "aggregation": "count"
        }
      }
    ],
    "groupBy": [],
    "time": {
      "from": 1779376593792,
      "to": 1779377493792
    },
    "search": {
      "query": "@event_type:eval-metric @event_kind:feedback"
    },
    "indexes": ["llmobs"],
    "executionInfo": {}
  }
}
```

This corresponds to the React hook:

```ts
useDataSources([
  {
    source: 'eventsPlatform.scalar',
    request: {
      request_type: 'events_ui',
      response_format: 'scalar',
      query: {
        data_source: 'llm_observability',
        name: 'llmobs_count',
        search: { query: '@event_type:eval-metric @event_kind:feedback' },
        compute: [{ aggregation: 'count', name: 'compute' }],
        indexes: ['llmobs'],
        storage: 'hot',
      },
    },
    timeFrame: { start, end, paused: false },
  },
]);
```

If the aggregate response is unclear, return the raw response summary and the `requestId`; do not pretend a count is present without locating it in the response.

## Query Rules

- Prefix custom fields with `@` in query strings, for example `@event_type`, `@event_kind`, `@span_id`, `@id`, `@ml_app`.
- Use top-level tags without `@` only when querying tags rather than custom event fields.
- Start broad, then narrow. For feedback smoke tests, first use `@event_type:eval-metric @event_kind:feedback`; after confirming the returned shape, narrow with fields like `@span_id:<id>` or `@id:<metric_id>`.
- Use epoch milliseconds for fixed `time.from`/`time.to`. Use the exact window from the UI when the user provides one.
- For llmobs, set `indexes: ["llmobs"]` and `type=llmobs`.
- The public `/api/v2/events/search` API may not match the llmobs UI data-source path. Prefer the logs analytics list/aggregate endpoints above for these checks.
