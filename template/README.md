# Claude Agent Team

A Claude Code agent team for mobile app monorepos with a shared `core/`, a Kotlin `android/` app, and a Swift `ios/` app. One request goes in. You get a plan, asset work, a PR per platform, and QA verdicts on each PR. You merge.

Install it into any git repo with one script.

## The team

| Agent | Model | Effort | Job |
|---|---|---|---|
| manager (main session) | Your choice | Your choice | Runs the workflow, passes work between agents, reports to you |
| architect | `opus` (Opus 5.5) | X-High | Writes the plan and the planned change record |
| asset-designer | `sonnet` (Sonnet 5.5) | High | Style guide, sprite manifest, generated art, integration spec |
| core | `sonnet` (Sonnet 5.5) | Medium | Shared APIs, models, logic, schema, contracts |
| android | `sonnet` (Sonnet 5.5) | Medium | Kotlin app |
| ios | `sonnet` (Sonnet 5.5) | Medium | Swift app |
| core-qa-tester | `sonnet` (Sonnet 5.5) | High | Reviews and verifies the core PR |
| android-qa-tester | `sonnet` (Sonnet 5.5) | High | Reviews and verifies the android PR |
| ios-qa-tester | `sonnet` (Sonnet 5.5) | High | Reviews and verifies the ios PR |
| librarian | `haiku` (Haiku 5.5) | High | Updates README, CHANGELOG, and PRODUCT after you merge |
| audit | `opus` (Opus 5.5) | X-High | Full repo review, only when you ask |

Agent files use the aliases `opus`, `sonnet`, and `haiku`. Check which versions your Claude Code install maps them to. Effort isn't set in any file, so set it by hand.

The developer agents write the smallest complete change. The QA testers and the audit review like the engineer who gets paged when it breaks: correct, safe, holds under load, tested, fast, lean.

## Requirements

- Claude Code
- git and bash
- GitHub CLI (`gh`), logged in. Check with `gh auth status`.
- fal.ai MCP server configured in Claude Code. Only the asset-designer needs it.
- Branch protection on `main`. Agents are told never to push to main, but only branch protection enforces it.

## Install

1. Clone this repo once: `git clone <repo-url> ~/claude-agent-team`
2. From your project root, run: `~/claude-agent-team/install.sh .`
3. If the script prints `skip` for any file, that file already existed. Merge it by hand. A skipped `CLAUDE.md` means the manager instructions won't load.
4. Open `CLAUDE.md` and fill in Product, Stack, and the build, test, and lint table. Agents report `unknown` commands as not run. They never guess.
5. Set each agent's effort by hand.
6. Optional: in Claude Code, ask "run the librarian in Bootstrap mode" to fill in README, CHANGELOG, and PRODUCT from your code.

The installer never overwrites files, so running it again is safe.

## Use it

### Build a feature

```
/build-feature add magic link login
```

1. The architect writes `docs/plans/<slug>.md` on `plan/<slug>` and opens a `[plan]` PR. Open questions stop the run.
2. If the plan has Asset tasks, the asset-designer runs. On the first run it generates one style anchor and stops for your approval.
3. core builds, then core-qa-tester must return PASS before the apps start.
4. android builds, then android-qa-tester reviews.
5. ios builds after android, then ios-qa-tester reviews.
6. The manager lists every PR with its verdict. Merge in this order: plan, core, android, ios.

Platforms the plan doesn't touch are skipped. A FAIL goes back to the developer for up to 2 fix rounds. If it still fails, the run stops and nothing gets documented.

### Update the docs after you merge

```
/update-docs <slug>
```

The librarian updates PRODUCT.md, CHANGELOG.md (under Unreleased), and README.md on `docs/<slug>`, then opens a `[docs]` PR. It never sets a version or date unless you give both.

### Audit the whole repo

```
/audit-repo
/audit-repo security
```

The manager first asks which build, test, lint, or scanner commands the audit may run. The audit writes `docs/audits/<project>-full-repo.md` (or `<project>-<your-slug>.md`) on `audit/<slug>` and opens an `[audit]` PR. Critical and high findings show up in chat right away. Each remediation group is sized to paste into `/build-feature`.

## How it works

Subagents can't start other subagents, and each one sees only the files it reads. So every handoff is a file in the repo.

| File | Written by | Read by |
|---|---|---|
| `docs/plans/<slug>.md` | architect | everyone in the run |
| `docs/changes/<slug>.md` | architect | librarian |
| `docs/plans/<slug>-assets.md` | asset-designer | android, ios |
| `docs/plans/<slug>-<platform>.md` | core, android, ios | that platform's QA tester |
| `docs/changes/<slug>.<platform>.md` | that platform's QA tester | librarian |
| `docs/audits/<slug>.md` | audit | you |

**Slugs.** The manager reads the project folder name and builds the slug as `<project>-<feature>`. Folder `My App` with request "add magic link login" becomes `my-app-magic-link-login`.

**Branches.** `plan/<slug>` starts from main and also holds the assets. `core/<slug>` starts from the plan branch. `android/<slug>` and `ios/<slug>` start from core, or from the plan branch if there's no core work. Each PR targets the branch it was built from. Retarget it to main after its base merges.

**The run stops and asks you when:**
- The architect has open questions, or the asset-designer needs anchor approval
- A fix loop hits 2 rounds, or any agent reports a blocker
- The work needs a schema migration, a new dependency, or changes to auth, payments, or encryption
- A change is breaking or needs a major version bump
- A step would change anything outside the plan, delete data, or touch production config

## What gets installed

```
CLAUDE.md                  manager instructions, team, workflow, rules
README.md, CHANGELOG.md, PRODUCT.md   project doc skeletons
.claude/settings.json      git and gh permissions; force push and merge denied
.claude/agents/            11 agent files
.claude/commands/          build-feature, update-docs, audit-repo
design/asset-playbook.md   full asset generation playbook
docs/plans/ changes/ contracts/ audits/
```

## Customize

- **Approver name.** The files call the human approver "John". Find every mention with `grep -rl John template/` and replace it with your name.
- **Models.** Change the `model` field in each agent's frontmatter, then update the team table in `CLAUDE.md` to match.
- **Kotlin Multiplatform.** The ownership rules assume core doesn't share a language with the apps. If core is KMP, rewrite the "Never edit" sections in `core.md`, `android.md`, and `ios.md`.
- **New agent.** Keep the body under 120 lines. Write a description with concrete triggers, because Claude uses it to pick agents. Add the agent to the team table, handoff table, and workflow in `CLAUDE.md`.

## Update a project that already has the template

The installer skips existing files, so template changes don't reach installed projects on their own.

1. `cd ~/claude-agent-team && git pull`
2. In the project, delete the files you want refreshed.
3. Run `~/claude-agent-team/install.sh .` again.
4. Re-apply any project edits, such as the commands table in `CLAUDE.md`.

## Known limits

- Path ownership ("android never edits core/") is a written instruction. Tool settings can't enforce it. Branch protection on main is the real safeguard.
- Each asset generation costs money. The only spend guard is a cap of 3 attempts per sprite.
- QA reviews layout code and states. It doesn't record the playbook's layer screenshots or scroll video.
- `android.md` and `audit.md` are close to the 120-line limit.
