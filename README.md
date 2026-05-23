# Kimi Settings

Shared Kimi Code CLI configuration synced across multiple remote servers.

## What's Synced

| Item | Location in Repo | Symlink Target |
|------|------------------|----------------|
| Config | `config.toml` | `~/.kimi/config.toml` |
| Hooks | `hooks/` | `~/.kimi/hooks/` |
| Skills | `skills/` | `~/.kimi/skills/` |

**Not synced** (machine-local runtime data):
- `sessions/`, `logs/`, `plans/`, `user-history/`
- `credentials/`, `kimi.json`, `mcp.json`

## Quick Start (New Machine)

```bash
git clone https://github.com/go-bananas-wwj/kimi_settings.git ~/.kimi-config
cd ~/.kimi-config
bash install.sh

# Set your ServerChan key for notifications
export SERVERCHAN_SENDKEY="your-sendkey"

# Login to Kimi
kimi
/login
```

## Add a New Skill

```bash
# Create the skill (edits go into the repo because of symlink)
mkdir ~/.kimi/skills/my-skill
vim ~/.kimi/skills/my-skill/SKILL.md

# Commit and push
cd ~/.kimi-config
git add skills/my-skill/
git commit -m "feat: add my-skill"
git push

# On other machines
cd ~/.kimi-config && git pull
```

## Update Config

Edit `config.toml` directly in the repo, commit and push. All machines pull to stay in sync.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `SERVERCHAN_SENDKEY` | ServerChan notification key for hooks |
