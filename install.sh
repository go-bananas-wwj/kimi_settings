#!/bin/bash
set -euo pipefail

# =============================================================================
# Kimi Settings Installer
# Installs shared Kimi Code CLI config, hooks, and skills via symlinks.
# =============================================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
KIMI_DIR="${HOME}/.kimi"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d_%H%M%S)"

echo "=== Kimi Settings Installer ==="
echo "Repo dir: $REPO_DIR"
echo "Target:   $KIMI_DIR"
echo ""

# Ensure ~/.kimi exists
mkdir -p "$KIMI_DIR"

# -----------------------------------------------------------------------------
# 1. config.toml
# -----------------------------------------------------------------------------
if [[ -e "$KIMI_DIR/config.toml" && ! -L "$KIMI_DIR/config.toml" ]]; then
    echo "Backing up existing config.toml..."
    mv "$KIMI_DIR/config.toml" "$KIMI_DIR/config.toml$BACKUP_SUFFIX"
fi

if [[ -L "$KIMI_DIR/config.toml" ]]; then
    echo "Removing old symlink for config.toml..."
    rm "$KIMI_DIR/config.toml"
fi

echo "Linking config.toml..."
ln -s "$REPO_DIR/config.toml" "$KIMI_DIR/config.toml"

# -----------------------------------------------------------------------------
# 2. hooks/
# -----------------------------------------------------------------------------
if [[ -e "$KIMI_DIR/hooks" && ! -L "$KIMI_DIR/hooks" ]]; then
    echo "Backing up existing hooks/ directory..."
    mv "$KIMI_DIR/hooks" "$KIMI_DIR/hooks$BACKUP_SUFFIX"
fi

if [[ -L "$KIMI_DIR/hooks" ]]; then
    echo "Removing old symlink for hooks/..."
    rm "$KIMI_DIR/hooks"
fi

echo "Linking hooks/..."
ln -s "$REPO_DIR/hooks" "$KIMI_DIR/hooks"

# -----------------------------------------------------------------------------
# 3. skills/
# -----------------------------------------------------------------------------
if [[ -e "$KIMI_DIR/skills" && ! -L "$KIMI_DIR/skills" ]]; then
    echo "Backing up existing skills/ directory..."
    mv "$KIMI_DIR/skills" "$KIMI_DIR/skills$BACKUP_SUFFIX"
fi

if [[ -L "$KIMI_DIR/skills" ]]; then
    echo "Removing old symlink for skills/..."
    rm "$KIMI_DIR/skills"
fi

echo "Linking skills/..."
ln -s "$REPO_DIR/skills" "$KIMI_DIR/skills"

# -----------------------------------------------------------------------------
# 4. prompts/
# -----------------------------------------------------------------------------
if [[ -e "$KIMI_DIR/prompts" && ! -L "$KIMI_DIR/prompts" ]]; then
    echo "Backing up existing prompts/ directory..."
    mv "$KIMI_DIR/prompts" "$KIMI_DIR/prompts$BACKUP_SUFFIX"
fi

if [[ -L "$KIMI_DIR/prompts" ]]; then
    echo "Removing old symlink for prompts/..."
    rm "$KIMI_DIR/prompts"
fi

echo "Linking prompts/..."
ln -s "$REPO_DIR/prompts" "$KIMI_DIR/prompts"

# -----------------------------------------------------------------------------
# 5. Ensure runtime directories exist locally (not symlinked)
# -----------------------------------------------------------------------------
for subdir in sessions logs plans user-history credentials telemetry; do
    mkdir -p "$KIMI_DIR/$subdir"
done

# -----------------------------------------------------------------------------
# 6. Environment check
# -----------------------------------------------------------------------------
echo ""
echo "Skills count: $(ls -1 "$KIMI_DIR/skills" 2>/dev/null | wc -l)"
echo "Prompts dir:  $(ls -1 "$KIMI_DIR/prompts" 2>/dev/null | wc -l) file(s)"
echo ""
echo "=== Post-install checks ==="

if [[ -z "${SERVERCHAN_SENDKEY:-}" ]]; then
    echo "⚠️  WARNING: SERVERCHAN_SENDKEY is not set."
    echo "   The ServerChan notification hook will fail until you set it:"
    echo "   export SERVERCHAN_SENDKEY='your-sendkey'"
else
    echo "✅ SERVERCHAN_SENDKEY is set."
fi

echo ""
echo "=== Installation complete ==="
echo "Static configs are symlinked from: $REPO_DIR"
echo "Runtime data stays local in:       $KIMI_DIR"
echo ""
echo "Next steps:"
echo "  1. If this is a new machine, run 'kimi' and use /login to authenticate."
echo "  2. To add/update skills, edit files under $REPO_DIR/skills/ and git push."
echo "  3. On other machines, run 'git pull' in $REPO_DIR to sync updates."
echo ""
