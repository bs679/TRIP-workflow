# Projects Folder Setup — One Home for Everything

A single `~/Projects` folder, one subfolder per thing you're building, with Claude Code and Codex both able to operate across all of it. Designed so that "where was I?" always has a 10-second answer.

## The Layout

```
~/Projects/
├── CLAUDE.md                  # root context for Claude Code (index + house rules)
├── AGENTS.md                  # same content for Codex CLI
├── DASHBOARD.md               # one line per project: status + next action
├── .claude/skills/            # cross-project skills only (TRIP-status works great here)
├── TRIP-workflow/             # this repo — the MASTER copy of the skills
├── my-webapp/                 # each project = its own git repo
│   ├── CLAUDE.md              # project-specific context (references docs/ARCHI.md)
│   ├── AGENTS.md              # same for Codex
│   ├── .claude/skills/        # TRIP skills, customized by /TRIP-init for THIS project
│   └── docs/
│       ├── NOW.md             # "where was I?" breadcrumb (5 lines, always current)
│       └── ARCHI.md           # the project's long-term memory
├── my-cli-tool/
│   └── ...same shape...
├── _inbox/                    # ideas parking lot — one .md per idea, zero structure
└── _archive/                  # dormant projects, moved out of sight
```

Rules that make it work:

1. **Each project is its own git repo.** Never make `~/Projects` itself a git repo — nested repos confuse both agents and you.
2. **Every project gets the same skeleton** (CLAUDE.md, AGENTS.md, docs/NOW.md, docs/ARCHI.md). Sameness is the feature: any project you open, muscle memory works.
3. **The underscore folders are load-bearing.** `_inbox/` catches shiny new ideas so they don't hijack the current feature (write the idea down, close the file, go back). `_archive/` keeps the active list short enough to scan in one glance — an ADHD list with 15 items is a list with 0 items.

## Root CLAUDE.md / AGENTS.md

Keep the root files **thin** — they load into every root session, so every line costs tokens. Identical content in both files (Claude Code reads `CLAUDE.md`, Codex reads `AGENTS.md`):

```markdown
# Projects Root

## Index
- `my-webapp/` — [one line: what it is, stack]
- `my-cli-tool/` — [one line]
- `TRIP-workflow/` — master copy of the TRIP skills (don't edit per-project copies here)

## House Rules
- Each subfolder is an independent git repo. Always `cd` into a project before git operations.
- Every project follows the TRIP workflow — read `<project>/docs/ARCHI.md` before touching its code.
- Check `<project>/docs/NOW.md` for in-flight state before starting anything.
- New ideas go to `_inbox/` as a note, not into code.
- Update `DASHBOARD.md` when a project's status changes.
```

## Where TRIP Lives

- **Master copy**: `~/Projects/TRIP-workflow/` (this repo). Pull updates here.
- **Per-project copies**: `/TRIP-init` copies `skills/` into each project's `.claude/skills/` and fills the placeholders (test commands, version file, week anchor). The copies **diverge on purpose** — that's the customization. Upgrade them with `/TRIP-upgrade`, never by re-copying.
- **Codex sees the same skills**: Codex CLI supports the same `SKILL.md` open standard — point it at the project's skills folder (or symlink) per its docs. Both agents then speak the same workflow.

## Running Claude Code and Codex Together

**Default: launch in the project folder, not the root.** `cd ~/Projects/my-webapp && claude` (or `codex`). You get exactly one project's context, one repo's git state, and the customized skills. This is the right call 90% of the time — a root session carrying context for six projects is token soup and invites edits to the wrong repo.

**Root sessions are for cross-project work**: "update the dashboard", "which projects still use library X?", "apply this fix to all three apps". Both tools discover the nested per-project context files when they descend into a subfolder, so a root session still picks up project rules as it works.

**Two agents at once — collision rules:**

- ✅ Claude on `my-webapp`, Codex on `my-cli-tool` — different repos, zero conflict. This is the sweet spot of the shared folder.
- ✅ Both on the same repo *the TRIP way* — Claude orchestrates, Codex is invoked as reviewer/implementer through the `codex-*` skills. That's coordinated: one writer at a time, by design.
- ❌ Two independent interactive sessions writing to the same repo simultaneously. Don't. If you genuinely need it, give each a [git worktree](https://git-scm.com/docs/git-worktree) (`git worktree add ../my-webapp-codex feat/other-thing`) so they write to separate checkouts of separate branches.

## The ADHD Layer

The folder structure above already externalizes memory; these habits close the loop:

- **DASHBOARD.md is your morning page.** One table, one row per active project: name, current phase (from its NOW.md), next action. When you sit down with no idea what to do, you read one file, pick one row, `cd`, run `/TRIP-status`, and you're moving inside two minutes. Agents update it; you just read it.
- **One feature in flight per project.** TRIP already enforces this (one branch, one plan, ff-merge). Resist parallel plans.
- **Ideas are captured, not acted on.** Mid-implementation shiny idea → 3 lines in `_inbox/`, back to the batch. The idea survives; the focus survives.
- **Archive aggressively.** Untouched for a month → `_archive/`. Moving it back out costs one `mv`; the daily cost of seeing it is higher than you think.
- **Every stopping point is safe.** TRIP stages each reviewed batch and updates NOW.md, so walking away mid-feature loses nothing. You never need to "hold it in your head until it's done" — the repo holds it.

## Bootstrap

```bash
mkdir -p ~/Projects/{_inbox,_archive} ~/Projects/.claude/skills
cd ~/Projects
git clone https://github.com/bs679/trip-workflow TRIP-workflow
cp -r TRIP-workflow/skills/TRIP-status ~/Projects/.claude/skills/   # status works from the root too
printf '# Projects Root\n\n## Index\n\n## House Rules\n' | tee CLAUDE.md > AGENTS.md
printf '# Dashboard\n\n| Project | Phase | Next action |\n| --- | --- | --- |\n' > DASHBOARD.md
```

Then per project: `cd <project>`, copy `TRIP-workflow/skills/` into `.claude/skills/`, run `/TRIP-init <ProjectName>`, and let it interview you.
