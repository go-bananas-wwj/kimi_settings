# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Agent tool:
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Commit your work
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    ## Constraints

    - Don't change code outside the task scope
    - Follow existing patterns in the codebase
    - If you find pre-existing issues, note them but don't fix unless task says to

    ## Self-Review Checklist

    Before reporting back, verify:
    - [ ] All requirements from task description are met
    - [ ] Tests pass
    - [ ] No accidental changes outside scope
    - [ ] Code follows project conventions

    ## Report Format

    Report one of these statuses:

    **DONE:** Task complete, all requirements met, tests pass.

    **DONE_WITH_CONCERNS:** Task complete but I have observations:
    - [concern 1]
    - [concern 2]

    **NEEDS_CONTEXT:** I need clarification on:
    - [question 1]
    - [question 2]

    **BLOCKED:** Cannot complete because:
    - [blocker description]

    Include:
    - What you implemented
    - Test results
    - Any files changed/created
```
