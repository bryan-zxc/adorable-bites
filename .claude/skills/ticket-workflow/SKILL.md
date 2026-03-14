---
name: ticket-workflow
description: End-to-end workflow for picking up and delivering a ticket. Use when the user says "pick up ticket", "work on ticket N", "start ticket", "grab the next ticket", or similar. Covers the full lifecycle from reading the ticket through to commit, push, and completing the ticket on the board.
---

# Ticket Workflow

Use `/github-board` for all ticket operations (status transitions, completing, editing descriptions).

## Workflow

### 1. Read and claim

- Fetch the ticket: `gh issue view <number> --repo bryan-zxc/adorable-bites`
- Transition to **In Progress** via `/github-board`

### 2. Explore and discuss

Explore the codebase as needed — read files, trace code paths, check existing patterns. Use internet research (web search, documentation fetches) when the ticket involves unfamiliar libraries, APIs, or external integrations. Do **not** enter plan mode or start writing code yet.

Present findings to the user in conversation form:
- Summarise what the ticket requires
- Describe the intended approach
- If the solution is not obvious, present options with pros and cons and ask the user to choose

Wait for the user's agreement before proceeding.

### 3. Plan and implement

Only after the user agrees with the approach:

1. Enter plan mode
2. Write the plan, exit for approval
3. On approval, **create a todo list** from the plan steps using TaskCreate — this lets the user track progress throughout implementation
4. Implement the changes, updating task status as you go

### 4. Art assets

If the ticket requires new or modified visual assets, use `/generate-art` to create them. Never generate images any other way.

### 5. Build and verify

Use `/build-and-preview` to build the app and take a simulator screenshot. Evaluate:
- **Primary:** Did the work land as intended?
- **Secondary:** Are there any visual issues (layout, alignment, missing assets)?

If issues are found, fix and rebuild until the screenshot looks correct.

### 6. Complete

1. Commit and push to the current branch
2. Update the ticket description to reflect what was delivered
3. Transition board status to **Done** via `/github-board`

### 7. Check for epic completion

After completing the ticket, check whether it belongs to a parent epic and whether that epic is now fully delivered.

**Find the parent epic (must use GraphQL — REST API does not expose the parent field):**

```bash
PARENT=$(gh api graphql -f query='
  query {
    repository(owner: "bryan-zxc", name: "adorable-bites") {
      issue(number: <TICKET_NUMBER>) {
        parent { number }
      }
    }
  }' --jq '.data.repository.issue.parent.number // empty')
```

If `PARENT` is empty, there is no parent epic — stop here.

**Check if all sub-issues of the epic are Done on the board:**

```bash
gh api graphql -f query='
  query {
    repository(owner: "bryan-zxc", name: "adorable-bites") {
      issue(number: <EPIC_NUMBER>) {
        subIssues(first: 50) {
          nodes {
            number
            title
            projectItems(first: 5) {
              nodes {
                fieldValueByName(name: "Status") {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }' --jq '.data.repository.issue.subIssues.nodes[] | select(.projectItems.nodes[0].fieldValueByName.name != "Done") | .number'
```

If the output is empty (all sub-issues have board status "Done"), transition the epic to **Done** via `/github-board`.
