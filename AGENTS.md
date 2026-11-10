# Dotfiles project conventions

## Scripts

- Test changes with `./test-setup.sh --no-cache` (Docker-based).
- Don't assume tools like `add-apt-repository` exist on minimal systems.

# Review code and pull requests

- When I ask to "review and QA" a web-ui pull request, browser QA is mandatory.
  Prepare the review in parallel, but submit it only after QA is complete as
  `frontend-qa` defines it.
- When I ask for a pull request review, submit an actual GitHub review: batch
  all inline findings into it, with an overall body summarizing the findings
  and the QA performed.
- Submit a Comment review when there are actionable findings and an Approve
  review when there are none. Never submit Request changes unless I ask.

# Browser testing (web-ui)

**Every web-ui change must be verified in a real browser before I report back or
open a PR.** Tests passing is not sufficient — render the affected page and look
at it. When a change touches a page shared with another product, open both
surfaces and compare them.

**Always include screenshots** — in the PR description, and when reporting back
in chat. Before/after when fixing a visual or data defect.

## Use frontend-qa

- Browser-QA every web-ui change that can change what renders.
- For any Datadog UI browser work, load the `frontend-qa` skill and follow it,
  instead of a repository's browser-use.md. `configure-browser` is the only
  way to sign in: never drive a sign-in page or ask me to log in.
- On my laptop, run its session headed, so I can use the same browser. On a
  Datadog Workspace (`IN_WORKSPACE=1`) there is no display: follow its
  `references/workspace.md`.
- One exception to `frontend-qa`: for Datadog Feature Flags, use the
  `dd_set_flag_<flag>` URL param or the `dd.dd_flag.overrides` localStorage key
  (see **Feature flags** below). `frontend-qa`'s `config_<flag>` param doesn't
  reach the Feature Flags SDK.

## Manual setup (laptop fallback)

Use this only on my laptop, and only when `frontend-qa` isn't available or I ask
for it.

One-time installs:

```bash
dogbrew install configure-browser   # or: dogbrew update configure-browser
brew install agent-browser && agent-browser install
```

`configure-browser` copies the Datadog session cookies out of the normal Chrome
profile, so there is **no login step** — never type credentials into a Datadog
login page. `agent-browser install` also provides Chrome for Testing, which
`configure-browser` prefers.

### Launch Chrome yourself, then attach configure-browser

Do **not** use `agent-browser --session` + `--args` for web-ui devlocal work.
`agent-browser` rewrites `--disable-features`, so the
`--disable-features=LocalNetworkAccessChecks` flag that the configure-browser
Confluence page recommends is silently dropped. Without that flag the page loads
but stays blank: `app-dev-local.datadoghq.com` resolves to **public** IPs while
the bundle is served from `https://localhost:8443`, and Chrome 156+ blocks that
public → loopback request (`LocalNetworkAccessPermissionDenied`).

Launch Chrome directly with the flag, then attach over CDP:

```bash
# 1. Dev server (keep running)
cd <web-ui> && yarn dev

# 2. Headed Chrome for Testing with local-network checks off, on its own CDP port
CHROME="$HOME/.agent-browser/browsers/chrome-"*/Google\ Chrome\ for\ Testing.app/Contents/MacOS/Google\ Chrome\ for\ Testing
nohup "$CHROME" --remote-debugging-port=9224 --user-data-dir=/tmp/qa-chrome \
  --disable-features=LocalNetworkAccessChecks,PaintHolding,Translate \
  --disable-backgrounding-occluded-windows --disable-renderer-backgrounding \
  --disable-background-timer-throttling \
  --no-first-run --no-default-browser-check about:blank &

# 3. Inject the session (keep running; re-applies config on navigation)
nohup configure-browser --cdp-url http://localhost:9224 --json \
  --url https://app-dev-local.datadoghq.com/<path> &
```

**The three `--disable-*background*` flags are required, not optional.** The
browser window is shared and usually sits behind other windows. Without them
Chrome treats a covered window as hidden (`document.visibilityState ===
'hidden'`) and stops firing `requestAnimationFrame`. Modals then stall half-open:
`react-modal` sets `aria-hidden` on `#react-app` but never reaches its open state,
so the overlay stays invisible and blocks clicks. That looks exactly like a
product bug, and it isn't one. Before blaming the code for a stuck modal or
animation, check:

```bash
agent-browser --cdp 9224 eval "document.visibilityState"   # must be 'visible'
```

Expect `{"event":"attached","authenticated":true,...}`. Port 9222 is often
already taken — pick another and leave the existing browser alone.

Drive it with `agent-browser --cdp 9224 <command>`:

```bash
agent-browser --cdp 9224 open <url>
agent-browser --cdp 9224 screenshot out.png
agent-browser --cdp 9224 eval "document.title"
agent-browser --cdp 9224 snapshot          # a11y tree with refs
agent-browser --cdp 9224 network requests  # verify API query params
```

Pages take 1-3 minutes to build on first load; that is not a failure. Check
`performance.getEntriesByType('resource')` to confirm requests carry the query
params you expect — that is how scoping/filtering bugs surface.

Tear down with `kill <chrome-pid> <configure-browser-pid>`, and tell Miguel what
is still running if leaving it up for him.

## Feature flags: two different clients

web-ui has **two** feature-flag systems, with different storage keys and
different value shapes. Using the wrong one fails silently — the flag simply
reads as its default.

**`configure-browser --experiment name=true` only sets Mosaic flags.** It is not
broken when a Datadog Feature Flag fails to apply; it is the wrong client.

| | Mosaic | Datadog Feature Flags |
|---|---|---|
| Read via | Mosaic feature-flags-provider | `useBooleanFeatureFlag` from `@feature-flags-lib/sdk/hooks` |
| localStorage key | `mosaic.feature-flag-overrides` | `dd.dd_flag.overrides` |
| Value shape | bare boolean: `{"my-flag": true}` | typed: `{"my-flag": {"type":"BOOLEAN","value":true}}` |
| URL params | `mosaic_ff_<flag>` (transient), `mosaic_set_ff_<flag>` (persisted) | `dd_flag_<flag>` (transient), `dd_set_flag_<flag>` (persisted) |
| `--experiment` | ✅ works | ❌ no effect |

To set Datadog Feature Flags, prefer the URL param — it writes the typed override
for you. Use it in PR description preview links too, so reviewers land on the page
with the flag on:

```
https://app-<hash>.datadoghq.com/llm/online-experiments?dd_set_flag_llm-obs-embedded-online-experiments=true
```

Or write the override directly, then reload — the SDK caches overrides at startup:

```bash
agent-browser --cdp 9224 eval "(()=>{const o={};for(const f of ['flag-a','flag-b'])o[f]={type:'BOOLEAN',value:true};localStorage.setItem('dd.dd_flag.overrides',JSON.stringify(o))})()"
agent-browser --cdp 9224 open <url>
```

The typed shape is required. A bare boolean is parsed as malformed and ignored,
which is exactly how this looks like "the flag didn't work".

Org-scoped flags — `useBooleanFeatureFlag(FLAG, false, 'org')` — are **not**
satisfied by the server's active-flag list for the org; the local override is
what makes a gated route render. Check
`/api/ui/feature-flags/get-active-feature-flags` to see what the org actually
has enabled, and expect a `Page Not Found` from the route's feature gate when a
gated flag is off.
