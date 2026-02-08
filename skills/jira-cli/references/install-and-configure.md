# jira-cli: Installation and Configuration

This reference covers how to install and configure [ankitpokhrel/jira-cli](https://github.com/ankitpokhrel/jira-cli). Installation options are from the [Installation wiki](https://github.com/ankitpokhrel/jira-cli/wiki/Installation); configuration is from the project README (Getting started).

---

## Installation

Binaries are available for Linux, macOS, and Windows from the [releases page](https://github.com/ankitpokhrel/jira-cli/releases).

### Docker

Run jira-cli in a container:

```sh
docker run -it --rm ghcr.io/ankitpokhrel/jira-cli:latest
```

### Homebrew (macOS)

```sh
brew tap ankitpokhrel/jira-cli
brew install jira-cli
```

### Scoop (Windows)

After [installing Scoop](https://scoop.sh/):

```sh
scoop bucket add extras
scoop install jira-cli
```

### FreeBSD

From ports:

```sh
cd /usr/ports/www/jira-cli/ && make install clean
```

Or from binary packages:

```sh
pkg install jira-cli
```

### NetBSD

From pkgsrc:

```sh
cd /usr/pkgsrc/www/jira-cli/ && make install clean
```

Or from binary packages:

```sh
pkgin install jira-cli
```

### Nix

Run without installing:

```sh
nix-shell -p jira-cli-go
```

Install imperatively:

```sh
nix-env -f '<nixpkgs>' -iA jira-cli-go
```

For NixOS or Home Manager, add `jira-cli-go` to `environment.systemPackages` or `home.packages` as appropriate.

### Manual (Go)

With Go 1.16+:

```sh
go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest
```

Ensure `$GOPATH/bin` (or `$HOME/go/bin`) is in your `PATH`.

---

## Configuration

After installing, run `jira init` to create the config file. The tool will prompt for host, email/username, and authentication. You can use an API token (recommended for Cloud), `.netrc`, or keychain; see the [auth discussion](https://github.com/ankitpokhrel/jira-cli/discussions/356) for details.

### Cloud (Jira Cloud / Atlassian Cloud)

1. Create a [Jira API token](https://id.atlassian.com/manage-profile/security/api-tokens).
2. Export it so the CLI can use it:
   ```sh
   export JIRA_API_TOKEN="your-api-token"
   ```
   Add this to your shell config (e.g. `~/.bashrc`, `~/.zshrc`) so it is always set.
3. Run:
   ```sh
   jira init
   ```
   Select installation type **Cloud** and enter your Jira host (e.g. `your-domain.atlassian.net`), email, and other prompts. The config file will be generated.

### On-premise (Jira Server / Data Center)

1. Set authentication:
   - **Basic auth (username + password):** Export your Jira password as `JIRA_API_TOKEN`.
   - **Personal Access Token (PAT):** Export the token as `JIRA_API_TOKEN` and set:
     ```sh
     export JIRA_AUTH_TYPE=bearer
     ```
   Add these to your shell config.
2. Run:
   ```sh
   jira init
   ```
   Select installation type **Local** and complete the prompts. For auth type, choose `basic` (username/password) or `bearer` (PAT). For client certificates use `mtls` and provide CA cert, client key, and client cert when prompted.

**IMPORTANT:** If your on-premise Jira uses a language other than English, issue/epic creation may fail due to API returning translated issue type names. In that case you may need to set `epic.name`, `epic.link`, and `issue.types.*.handle` manually in the generated config.

### Config file location

`jira init` creates a config file (e.g. `~/.jira-cli.json`). The exact path is shown after init. You can also use `.netrc` or keychain for the token instead of `JIRA_API_TOKEN`; see the [auth discussion](https://github.com/ankitpokhrel/jira-cli/discussions/356).

### Multiple projects / config files

To use a different config file for a run:

```sh
JIRA_CONFIG_FILE=./my_jira_config.yaml jira issue list
```

Or with the flag:

```sh
jira issue list -c ./my_jira_config.yaml
```

### Config management

After init, you can change settings with:

```sh
jira config <command>
```

Common subcommands:

- `host` — Update Jira host
- `username` — Update username
- `remove` — Remove config file
- `board --set` — Set default board

Run `jira config --help` for the full list.
