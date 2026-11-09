---
name: branch-review
description: Use when the user asks to review a branch, a pull request, or the work on the current branch before it merges. Triggers include "review my branch", "review this PR", "critique these changes", and "is this ready to merge".
---

# Branch review

Review the changes on a branch against the goal of the branch. Be critical and fair. Report the problems that matter. Do not invent problems to fill the report.

The review is read-only. Do not edit code until the user selects the findings to fix.

## 1. Find the scope

1. Find the base. If a PR exists, use its base branch: `gh pr view --json baseRefName,title,body,isCrossRepository,author`.
2. If no PR exists, use the merge base with the default branch: `git merge-base origin/<default> HEAD`.
3. Collect the commits with `git log --oneline <base>..HEAD`.
4. Collect the diff with `git diff <base>...HEAD`.
5. If the working tree has uncommitted changes, ask the user if they are in scope.
6. If the branch has no commits after the base, stop and tell the user.

## 2. Find the goal

Find the goal from the branch name, the commit messages, the PR text, any linked issue, and the diff. Find the problem that the branch must solve, not only what the code does now.

If you cannot find the goal with confidence, ask the user before you review. Ask one question at a time. Give your best guess in each question.

## 3. Read the context

- Read each changed file in full, not only the diff hunks.
- Read the callers and the callees of each changed function.
- Read the project rules: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING`, and any ADRs. A decision that these files record is not a finding.
- Run the type checker, the linter, and the tests if they are fast and do not change the working tree. Record the results.
- If `isCrossRepository` is true, or the user does not know the PR author, ask the user first. Ask before you run any command that executes the PR's code. This includes the tests, the build, hooks, and the dev shell. Reading files is always safe.

## 4. Review the four pillars

Review the pillars in this order. A wrong approach makes line-level findings useless, so start with architecture.

### Architecture

- Search the codebase for code that does a similar thing. If it exists, the branch must use the same pattern.
- If the work is new to the codebase, find the best approach. Compare it with at least one alternative.
- Do not accept a weaker approach because it is less risky. Recommend a change to the hot path, a larger diff, or a new API when the result is better. Give the cost and the benefit.
- If the better approach does not serve the goal of the branch, recommend a follow-up. Do not block the branch for it.

### Correctness

- Make sure that the branch meets its goal fully.
- Check type safety. This is most important in dynamic languages such as Python. Check annotations at function boundaries, `Any`, unchecked dictionary access, and `None` handling.
- For each new function call and API request, read its source or its documentation. Make sure that it does what the branch expects. Find side effects, error paths, and partial failures.
- Check edge cases: empty input, `None`, concurrent access, and failure in the middle of an operation.
- Make sure that tests cover the goal. A test that passes for the wrong reason is a finding.

### Performance

Work from the top down:

1. Structure: concurrency, caching, I/O, network round trips, and queries per request.
2. Algorithms: complexity inside loops, and work that the hot path repeats.
3. Local details: lock types, allocations, and copies. Report these only on a hot path.

Find the hot path before you report a cost. Give the scale for each performance finding, for example calls per request or rows per query.

### Simplicity

- Write for a junior or graduate developer. Code that only an expert can understand is a finding.
- Find complexity without a reason: extra indirection, an abstraction with one user, or clever code.
- Find duplicate code. Recommend one shared API.
- Find an abstraction that does not fit its users. Recommend a split.

## 5. Verify each finding

Before you report a finding, read the cited code again. Make sure the branch causes the problem. Tag a problem in old code that the branch touches as `pre-existing`. Do not block the branch for a pre-existing problem.

## 6. Write the report

Use this structure:

```
Goal: <one or two sentences>
Verdict: Approve | Approve with changes | Request changes. <one-sentence reason>

[blocker|should-fix|nit|question] [pillar] path/file.ext:line: <title>
  Problem: <what is wrong, with evidence>
  Fix: <the specific change>

Not reviewed: <files, checks, or tests that you did not cover>
```

Sort the findings by severity, most severe first. A `blocker` must be fixed before the merge.

## Large branches

If the diff is large, review each pillar in a separate subagent, in parallel. Give each subagent the goal, the base commit, the text of its pillar, and the finding format. Subagents report too many findings. Do step 5 yourself for each subagent finding.
