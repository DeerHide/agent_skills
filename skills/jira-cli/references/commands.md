# jira-cli: Create, Update, Comment, Link, and List

This reference documents the main commands for working with Jira issues via [ankitpokhrel/jira-cli](https://github.com/ankitpokhrel/jira-cli): list, create, update (edit), comment, and link/unlink. For the full command set (epics, sprints, assign, move, etc.) see the [README Commands section](https://github.com/ankitpokhrel/jira-cli#commands).

**Table of contents**

- [List](#list)
- [Create](#create)
- [Update (edit)](#update-edit)
- [Comment](#comment)
- [Link and unlink](#link-and-unlink)

---

## List

List and search issues. By default the result is an interactive table; use `--plain` for script-friendly output.

### Issue list

```sh
jira issue list
```

Common flags:

| Flag | Short | Description |
|------|--------|-------------|
| `--status` | `-s` | Filter by status (e.g. `-s "To Do"`, `-s open`) |
| `--assignee` | `-a` | Filter by assignee (e.g. `-a $(jira me)`, `-a x` for unassigned) |
| `--priority` | `-y` | Filter by priority (e.g. `-y High`) |
| `--label` | `-l` | Filter by label (repeat for multiple, e.g. `-l backend -l urgent`) |
| `--created` | | Time range for creation (e.g. `--created week`, `--created -7d`, `--created month`) |
| `--project` | `-p` | Restrict to project key |
| `--jql` / `--query` | `-q` | Raw JQL (e.g. `-q "summary ~ cli"`) |
| `--plain` | | Plain output for scripts |
| `--csv` | | CSV output |
| `--raw` | | Raw JSON |
| `--order-by` | | Sort field (e.g. `rank`, `created`); use `--reverse` for ascending |

Examples:

```sh
# Recent issues in plain mode
jira issue list --plain

# Issues assigned to me, high priority, status "To Do"
jira issue list -a$(jira me) -yHigh -s"To Do"

# Issues created this month with a label
jira issue list --created month -lbackend

# Custom JQL in current project
jira issue list -q "summary ~ cli"
```

### Epic and sprint list

- **Epics:** `jira epic list` — same filter flags as `issue list`; use `jira epic list --table` for table view. To list issues in an epic: `jira epic list EPIC-KEY`.
- **Sprints:** `jira sprint list` — list sprints; use `--current`, `--prev`, `--next`, or a sprint ID to list issues. Use `--table` for table view.

For all epic/sprint flags see the [README](https://github.com/ankitpokhrel/jira-cli#epic).

---

## Create

Create a new issue (or epic). Interactive by default; use `--no-input` with required flags to skip prompts.

### Issue create

```sh
# Interactive
jira issue create

# Non-interactive: pass required fields and skip prompt
jira issue create -t Bug -s "Summary" -y High -l bug -l urgent -b "Description" --no-input
```

Common flags:

| Flag | Short | Description |
|------|--------|-------------|
| `--type` | `-t` | Issue type (Bug, Story, Task, etc.) |
| `--summary` | `-s` | Summary/title |
| `--body` | `-b` | Description (supports markdown) |
| `--priority` | `-y` | Priority |
| `--label` | `-l` | Label (repeat for multiple) |
| `--component` | `-C` | Component |
| `--parent` | `-P` | Parent epic key (e.g. `-P EPIC-42`) to attach to epic |
| `--fix-version` | | Fix version (e.g. `--fix-version v2.0`) |
| `--no-input` | | Skip interactive prompt for non-mandatory fields |
| `--template` | | Load description from file or stdin (`--template -`) |

Example with epic:

```sh
jira issue create -t Story -s "Story under epic" -P EPIC-42 --no-input
```

### Epic create

Same as issue create plus epic name:

```sh
jira epic create -n "Epic name" -s "Summary" -y High -l bug -b "Description"
```

---

## Update (edit)

Edit an existing issue by key.

```sh
jira issue edit ISSUE-KEY
```

With field flags (interactive for omitted fields):

```sh
jira issue edit ISSUE-1 -s "New summary" -y High -l bug -C Backend -b "Updated description" --no-input
```

Common flags: `-s` (summary), `-y` (priority), `-l` (labels), `-C` (component), `-b` (body), `--fix-version`.

To **remove** a label, component, or fix version, prefix with `-`:

```sh
jira issue edit ISSUE-1 --label -p2 --label p1 --component -FE --component BE --fix-version -v1.0 --fix-version v2.0 --no-input
```

Use `--no-input` to avoid being prompted for fields you did not pass.

---

## Comment

Add a comment to an issue.

```sh
# Interactive (prompts for issue and body)
jira issue comment add

# Non-interactive
jira issue comment add ISSUE-1 "Comment body"
```

Options:

- `--internal` — Add as internal (e.g. organization-only) comment if your Jira supports it.
- `--template` — Read body from file or stdin: `jira issue comment add ISSUE-1 --template /path/to/file` or `--template -` (e.g. pipe input).

Example with stdin:

```sh
echo "Comment from stdin" | jira issue comment add ISSUE-1
```

---

## Link and unlink

### Link two issues

```sh
# Interactive
jira issue link

# Non-interactive: issue1, issue2, link type name
jira issue link ISSUE-1 ISSUE-2 Blocks
```

Common link types include Blocks, Cloners, Duplicates, Relates to (exact names depend on your Jira).

### Remote (web) link

Add an external URL to an issue:

```sh
jira issue link remote ISSUE-1 https://example.com "Link text"
```

### Unlink

```sh
jira issue unlink ISSUE-1 ISSUE-2
```

Interactive: `jira issue unlink` (then select issues).
