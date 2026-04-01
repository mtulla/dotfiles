---
name: write-pr-description
description: Generate a PR description matching Miguel's established style with setext headers, motivation, and scaled QA sections.
---

You are going to write a PR description for the current branch. Follow Miguel's PR description style exactly.

# Step 1: Gather Context

Run the following commands to understand the changes:

```
git log main..HEAD --oneline
```

```
git diff main...HEAD --stat
```

```
git diff main...HEAD
```

Read the key changed files to understand the full context of the changes.

# Step 2: Determine PR Complexity

Based on the diff, classify the PR:
- **Trivial**: Config change, typo fix, single-line change, boilerplate
- **Small**: Bug fix, small refactor, single feature addition
- **Medium**: New feature, new endpoint, multi-file refactor
- **Large**: Migration, new service, architectural change

# Step 3: Write the Description

Use **setext-style headers** (underlined with `------`), NOT `##` headers. This is critical.

## Section Template

Use these sections in this order. Include or skip sections based on complexity:

### Always include:

**"What does this PR do?"** (setext header)
- 1-5 sentences summarizing the change
- For trivial PRs, this can be a single paragraph with no header at all

**"QA"** (setext header)
- Scale with complexity (see QA rules below)

### Include for small+ PRs:

**"Motivation"** (setext header)
- Why the change is needed
- Link to Jira tickets, Slack threads, customer issues, RFCs if you know them
- Business context, not just technical context

### Include when needed:

**"Changes"** — Technical details when they don't fit in the summary
**"Note" / "Important Details"** — Caveats, out-of-scope items, follow-up work
**"Review"** — For large PRs, guide reviewers through the diff step-by-step
**"Metrics Added"** — Table of new metrics when the PR adds telemetry

## QA Section Rules

Scale the QA section based on PR complexity:

| Complexity | QA Style |
|------------|----------|
| Trivial | "Doesn't do anything" or "Passes local tests `//path/to:test`" |
| Small | 1-2 sentences + numbered steps of what to verify |
| Medium | Staging links + curl commands + expected results |
| Large | Full curl commands in `<details>` blocks, setup instructions, action tables |

For API endpoint PRs, use this pattern for each test case:
```
<details>
<summary>N. Test case name</summary>

### Command

\`\`\`bash
curl ...
\`\`\`

### Expected Result

\`\`\`json
{ ... }
\`\`\`

</details>
```

When you don't know specific staging URLs, test drive names, or screenshots, leave clear `[TODO: ...]` placeholders.

## Formatting Rules

- Use setext headers (underline with `------`), NEVER `##`
- Use markdown tables for structured data (metrics, endpoints, test matrices)
- Use `<details>` blocks for long QA sections with multiple curl commands
- Use code blocks for commands
- Conversational but professional tone
- Explain "why" not just "what"
- Explicitly call out out-of-scope / follow-up items
- Reference related PRs, Slack threads, Jira tickets when relevant

# Examples from Miguel's Best PRs

## Example 1: Feature PR with Metrics Table (PR #364971)

```
What does this PR do?
------------
This PR emits audit logs and metrics on LLM Obs Annotations CRUD actions.

Motivation
-----------
Audit logs are a requirement for the feature to go GA.

Metrics will let us track adoption as well as let us triage any issues.

QA
----------
[Example metric.](https://ddstaging.datadoghq.com/metric/explorer?...)

[Example audit logs.](https://dd.datad0g.com/audit-trail?...)

Changes are in staging. To QA, use the LLM Obs Annotations feature in staging and confirm that the right metrics and audit logs are being emitted. The new metrics are listed below.

Metrics Added
-----------

| Metric | Description |
|---|---|
| `dd.llm_obs_api.annotation.add_or_modify_annotations` | Incremented once per `AddOrModifyAnnotations` call |
| `dd.llm_obs_api.annotation.annotations_created` | Count of annotations successfully created in a single call |

All metrics are tagged with `org_id` and `state`.
```

## Example 2: Performance PR (PR #362389)

```
What this PR does
----------
Speeds up the `/api/ui/llm-obs/unstable/queue/{queueId}/annotation` endpoint so that it takes ~1/30 of the time to load.

Changes
-----------
Now that AIP has created their `ListTaskAnnotationsPaginates` RPC method, we don't have to go through all the interactions in a queue and one-by-one request their annotations. Since AIP now does the joining on their end, we can avoid many round trips.

QA
-----

Test Drive with Changes (Fast):
https://dd.datad0g.com/llm/annotations/queues/...?config_test_drive=peugeot-im
[Traces](https://ddstaging.datadoghq.com/apm/entity/...) (<200ms latency):

Staging (Slow):
https://dd.datad0g.com/llm/annotations/queues/...
[Traces](https://ddstaging.datadoghq.com/apm/entity/...) (>6s latency)
```

## Example 3: Small Clean PR (PR #342378)

```
What does this PR do?
------------------------
Queues' names were being validated to make sure they were unique across an entire Org. This PR changes that so instead we validate that Queue names are unique within individual LLM Obs Projects.

QA
-------------------------
Changes are up in staging. QAed by doing the following.

1. Created a queue with a name that already exists in that project (failed).
2. Created a queue with a name that does not already exist in that project (worked).
3. Edited a queue so that it has the same name as another queue in the project (failed).
4. Edited a queue to move it to a project where its new name would clash (failed).
```

## Example 4: Large Migration PR (PR #351321)

```
What does this PR do?
-----------------------
This PR migrated all of the LLM Obs Annotation handlers from AIP's `annotation` service to our own `llm-obs` HTTP service.

`llm-obs` executes actions on the underlying AIP project, tasks, and annotations via the `annotation-grpc`. So requests and responses now follow the following pattern
...

QA
-----------------------
The changes are up in staging. Go to
https://dd.datad0g.com/llm/annotations/queues?project=Annotations-QA
and QA the annotations product. Try the following actions.

| Action                              | Endpoint                                      |
|-------------------------------------|-----------------------------------------------|
| Create queue                        | `/queue`                                      |
| Delete queue                        | `/queue/:queueId`                             |
| Add interactions to queue           | `/queue/:queueId/interactions`               |
| Delete interactions from a queue    | `/queue/:queueId/interactions?:interactionIds` |

Review
-----------------------
You should review the PR in multiple "steps"

- [Step 1: Moving files and renaming dependencies.](link)
- [Step 2: Splitting up logic into domain, service, ports, and adapters.](link)
- [Step 3: Moving over tests and wiring dependencies.](link)
```

## Example 5: API Endpoint PR with Details Blocks (PR #356450)

```
What does this PR do?
--------------
This PR allow users to submit automation configs of type `queue_add` that will flag spans for manual review.

**Out of scope (follow-up PR):**
 - Cleanup-on-queue-deletion
 - Updating FABRIC context based on new `queue_add` automations
 - Actually running the automations

QA
---------------
Apart from the new tests, the following QA was performed using the `jaguar-glc` Test Drive.

**Note:** Run
\`\`\`bash
export DOGWEB_COOKIE=<YOUR-DOGWEB-COOKIE>
export X_CSRF_TOKEN=<YOUR-X-CSRF-TOKEN>
\`\`\`

<details>
<summary>1. Create a queue_add automation (happy path)</summary>

### Command
\`\`\`bash
curl -L -s -X POST "https://dd.datad0g.com/api/unstable/llm-obs/v1/automations" \
  -H "Content-Type: application/json" \
  -H "Cookie: dogweb=${DOGWEB_COOKIE}" \
  -d '{ ... }'
\`\`\`

### Expected Result
HTTP 200 with the automation created.

</details>

<details>
<summary>2. Create queue_add automation -- invalid queue_id</summary>
...
</details>
```

# Step 4: Output

Output the final PR description in a single markdown code block so it can be easily copied. Ask me if I want to make any changes.
