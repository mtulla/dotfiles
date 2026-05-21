---
name: stacked-pr-descriptions
description: Format or update GitHub pull request descriptions for stacked PRs using a Teddy-style numbered stack section. Use when Codex is writing, editing, opening, or refreshing stacked PR descriptions, especially when the user asks for stacked PR links, Teddy style, PR stack formatting, or marking the current PR in a stack.
---

# Stacked PR Descriptions

## Workflow

Use this when a PR is part of a stack or when updating multiple stacked PR descriptions.

1. Identify the full stack in order from bottom to top.
   - Use `gh pr view <branch-or-number> --json number,title,url,baseRefName,headRefName,body` for known PRs.
   - Follow `baseRefName` / `headRefName` relationships to find adjacent PRs.
   - Confirm the stack order before editing: PR #1 targets the non-stack base, PR #2 targets PR #1's head branch, and so on.
2. Preserve each PR's existing substantive sections.
   - Keep summary, changes, testing, impact, validation, and RFC links unless the user asks to rewrite them.
   - Remove older standalone lines like `Stacked on #...` if the new stack block supersedes them.
3. Insert a stack paragraph and stack links near the top.
   - Put it after the PR's opening summary/what section and before deeper details.
   - Match this exact style:

```markdown
This PR is PR #<index> of a <N>-stack change for <topic>.


### <N>-Stack PR Links

1. <Short Label>: <PR URL>
2. <Short Label> (this PR): <PR URL> <- **Current PR**
3. <Short Label>: <PR URL>


---
```

4. Update every PR in the stack.
   - The numbered list should be identical across all PRs except for `(this PR)` and `<- **Current PR**`.
   - Use concise labels that describe each layer, not necessarily the exact PR title.
   - Keep the total count in both `This PR is...` and `### <N>-Stack PR Links` consistent.
5. Apply updates with `gh pr edit <number> --body-file <file>` or an equivalent GitHub tool.
6. Verify each updated body with `gh pr view <number> --json body --jq '.body'`.

## Style Rules

- Use `3-Stack`, `4-Stack`, etc. with this capitalization.
- Use numbered links, not bullets.
- Include `(this PR)` before the colon on the current PR's line.
- Put `<- **Current PR**` at the end of the current PR's line.
- Include a horizontal rule (`---`) after the stack list.
- Prefer the user's or repository's existing section headings for the rest of the body.
