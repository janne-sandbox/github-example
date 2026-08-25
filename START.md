
This is exactly the sort of persistent repository context OpenAI recommends putting in `AGENTS.md`: build/test commands, conventions, architecture hints, quirks, etc. :contentReference[oaicite:1]{index=1}

I would **not** turn `AGENTS.md` into a 1,000-line manual. OpenAI's more recent guidance is actually to keep `AGENTS.md` relatively short and use it as a map to deeper documentation. :contentReference[oaicite:2]{index=2}

So your `START.md` can describe **how an agent starts a task**:

```md
# Agent Start Procedure

Before modifying code:

1. Read AGENTS.md.
2. Read MEMORY.md.
3. Inspect git status.
4. Read relevant architecture documentation.
5. Inspect existing implementation before proposing changes.
6. Identify the Maven module being modified.

Before declaring completion:

1. Run:

   ./mvnw clean verify

2. Fix compilation errors.
3. Fix test failures caused by the change.
4. Review:

   git diff

5. Summarize:
   - files changed
   - implementation decisions
   - tests executed
   - remaining issues

Never state "done", "complete", or "working" unless verification succeeded.
