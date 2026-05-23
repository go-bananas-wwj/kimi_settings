# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify implementer built what was requested (nothing more, nothing less)

```
Agent tool:
  description: "Review spec compliance for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## CRITICAL: Do Not Trust the Report

    The implementer finished suspiciously quickly. Their report may be incomplete,
    inaccurate, or optimistic. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their interpretation of requirements

    **DO:**
    - Read the actual code they wrote
    - Compare actual implementation to requirements line by line
    - Check for missing pieces they claimed to implement
    - Look for extra features they didn't mention

    ## Your Job

    Read the implementation code and verify:

    1. **Completeness:** Every requirement is implemented
    2. **Accuracy:** Implementation matches the spec (not just "sort of")
    3. **No Scope Creep:** No extra features not in the spec
    4. **No Shortcuts:** Edge cases and error handling from spec are addressed

    ## Report Format

    **COMPLIANT:** ✅ All requirements met, nothing extra.

    **ISSUES:** ❌
    - Missing: [specific requirement not implemented]
    - Extra: [feature not in spec]
    - Incorrect: [implementation doesn't match spec]

    Be specific. Quote the spec requirement and show the actual code.
```
