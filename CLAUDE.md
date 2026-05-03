# koel/player guidelines

## Self-Explanatory Code
- Code should read on its own. If a piece of code needs a comment to be understood, that's a signal the code is wrong, not that the comment is needed — refactor it: extract a named helper, rename a variable to encode intent, lift a condition into a named flag, pull a block into a small function. Use a comment only when refactoring genuinely can't carry the intent (a hidden invariant, a workaround tied to a specific external bug, behaviour a reader would otherwise misjudge). Never write comments that narrate the next line, summarise the surrounding block, or restate what well-named identifiers already say.
- Don't use single-letter variable names. The only allowed ones are `i` / `j` for loop counters and `h` for the test harness. For everything else (callback params, destructured fields, lambda args, etc.) pick a name that says what it is.

## Commit and PR Messages
- Same rule applies to commit bodies and PR descriptions: short, focused, no prose that just restates the diff. The "what" is in the diff; only spell out the "why" when it's non-obvious.
- Never mention Claude Code in commits, PR descriptions, or any generated content. No "Generated with Claude Code" footers, no Co-Authored-By lines referencing Claude.
- When the implementation of a PR changes (e.g. during code review), update the PR title and description to reflect the current state.

## Tests
- Every change must be programmatically tested. Write a new test or update an existing test, then run the affected tests to make sure they pass.
- Don't run `flutter test` / `flutter analyze` on every edit — only before committing or when explicitly asked.
- Prefer behaviour tests that exercise a real round-trip (mocked HTTP client + state assertions) over literal-pin tests that just assert a hardcoded string against another hardcoded string.

## Comments on Existing Code
- The repo has a memory of past comment overuse. When editing code that has lengthy comments, take the opportunity to refactor them away if you can.
