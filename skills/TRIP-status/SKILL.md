---
name: TRIP-status
description: "Where was I?" — reconstruct the current TRIP state and give the single next action
argument-hint: "(no arguments needed)"
---

# Status Mode

You are the user's externalized working memory. They may have been away five minutes or five weeks — assume they remember nothing about where the work stands. Reconstruct the state and tell them **exactly one next action**.

## Step 1: Read the breadcrumb

Read `docs/NOW.md` if it exists. Treat it as a claim, not the truth — it may be stale. Verify it in Step 2.

## Step 2: Verify against reality

Gather evidence:

```bash
git branch --show-current
git status -s
git log --oneline -5
ls -t docs/1-plans/*.plan.md 2>/dev/null | head -3
ls -lt .claude/skills/codex-implement/state/ \
       .claude/skills/codex-plan-review/state/ \
       .claude/skills/codex-code-review/state/ 2>/dev/null
```

How to read the signals:

- On a `feat/*` or `fix/*` branch with staged/unstaged changes → mid `TRIP-2-implement`.
- A `codex-implement/state/*.thread` newer than the last commit → an open delegation thread; the latest report is in the matching `.review.txt`.
- Latest plan file has unchecked to-dos → implementation incomplete.
- A `codex-code-review` thread exists but the changelog has no matching entry → between review and release.
- Version file bumped but changelog/tag missing (or vice versa) → mid `TRIP-3-release`.
- Clean main branch, no open to-dos → idle.

If `docs/NOW.md` disagrees with the evidence, **trust the evidence** and rewrite NOW.md in Step 4.

## Step 3: Report — short, then stop

Output exactly this shape and nothing more:

```
📍 You are here
Feature:    <name, or "none in flight">
Phase:      <plan | implement (batch N) | testing gate | codex review | release | idle>
Last safe checkpoint: <what is already staged/committed>
Loose ends: <1 line, only if any>

▶ Next action: <ONE command or ONE sentence>
```

Rules:

- **ONE next action.** Never a menu of options. If genuinely blocked between paths, use `AskUserQuestion` with 2-3 concrete options instead of prose.
- No recap of the whole workflow, no "you could also...". The whole point is zero decision overhead on re-entry.
- If idle: the next action is either resuming the most recent plan with open to-dos, or `/TRIP-1-plan <idea>` — pick the one the evidence supports.

## Step 4: Refresh the breadcrumb

Rewrite `docs/NOW.md` with the verified state, in this exact 5-line format (used by all TRIP skills):

```markdown
# NOW
- **Feature**: F_x.y.z_feature-name (or "idle")
- **Phase**: <phase, incl. batch number if mid-implement>
- **Checkpoint**: <last safe state — staged batch N / plan approved / released vx.y.z>
- **Next**: <the one next action>
```

No timestamps needed — git provides them. Keep it to these 5 lines forever.
