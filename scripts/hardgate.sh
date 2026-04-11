#!/usr/bin/env bash
# HARD-GATE: theory-check layer on top of Claude Code's permission system.
#
# Tiered pattern matching:
#   Tier 1: Secrets exposure (reading/staging secret files)
#   Tier 2: Data destruction (rm -rf, git reset --hard, etc.)
#   Tier 3: Irreversible publishing (npm publish, docker push, etc.)
#   Tier 4: Soft warning (chmod, curl|bash, etc.)
#
# Exit 0 + additionalContext = allow but inject theory-check requirement.
# Exit 0 with no output = allow silently (safe operation).

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).tool_name||''))")
TOOL_INPUT=$(echo "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.stringify(JSON.parse(d).tool_input||{})))")

# Only gate these tools
case "$TOOL_NAME" in
    Bash|Write|Edit|MultiEdit|NotebookEdit|Read) ;;
    *) exit 0 ;;
esac

# Helper: emit a theory-check injection and exit
theory_check() {
    local OPERATION="$1"
    local CONSEQUENCE="$2"
    cat <<EOJSON
{"additionalContext": "<system-reminder>THEORY-CHECK REQUIRED: You are about to perform: ${OPERATION}. Before proceeding, the user must explain IN THEIR OWN WORDS what this does and its consequences. A one-word answer is NOT sufficient. ${CONSEQUENCE}</system-reminder>"}
EOJSON
    exit 0
}

# Helper: emit a secrets warning and exit
secrets_warning() {
    cat <<EOJSON
{"additionalContext": "<system-reminder>SECRETS WARNING: This file likely contains secrets. Reading it will send its contents through the API. You don't need to read secret values to write code that uses them — load them at runtime via environment variable injection (os.environ in Python, process.env in Node). If you need to know which variables are available, read a .env.example or list variable names without values.</system-reminder>"}
EOJSON
    exit 0
}

# ============================================================
# TIER 1: Secrets Exposure
# ============================================================

# Read tool targeting secret files
if [ "$TOOL_NAME" = "Read" ]; then
    if echo "$TOOL_INPUT" | grep -qiE '\.env|credentials|\.key|\.pem|\.secret'; then
        secrets_warning
    fi
fi

# Bash: reading secret files
if echo "$TOOL_INPUT" | grep -qiE '(cat|less|more|head|tail|source)\s+.*\.(env|key|pem|secret)'; then
    secrets_warning
fi
if echo "$TOOL_INPUT" | grep -qiE '(cat|less|more|head|tail)\s+.*credentials'; then
    secrets_warning
fi

# Bash: dumping environment variables
if echo "$TOOL_INPUT" | grep -qiE '\bprintenv\b|\benv\b\s*$|echo\s+\$[A-Z_]*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)'; then
    secrets_warning
fi

# Bash: blanket git staging (may sweep in .env, credentials, etc.)
if echo "$TOOL_INPUT" | grep -qiE 'git\s+add\s+\.\s*$|git\s+add\s+-A|git\s+add\s+--all'; then
    theory_check "blanket git staging (git add . / -A / --all)" \
        "This stages everything including potentially .env, credentials, and other secret files. Use selective staging instead."
fi

# Write/Edit targeting secret files
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "MultiEdit" ]; then
    if echo "$TOOL_INPUT" | grep -qiE '\.env|credentials|secrets'; then
        theory_check "writing to secrets/credentials file" \
            "Secrets files may be committed to git or exposed in logs. Verify .gitignore coverage."
    fi
fi

# ============================================================
# TIER 2: Data Destruction
# ============================================================

if echo "$TOOL_INPUT" | grep -qiE 'rm\s+(-rf|--recursive|--force)'; then
    theory_check "recursive/force delete" \
        "Permanently removes files/directories. No undo. Check what's in the target path."
fi

if echo "$TOOL_INPUT" | grep -qiE 'git\s+push\s+(--force|-f\b)'; then
    theory_check "git force push" \
        "Overwrites remote history. Collaborators' work may be lost."
fi

if echo "$TOOL_INPUT" | grep -qiE 'git\s+reset\s+--hard|git\s+clean\s+-f'; then
    theory_check "destructive git reset/clean" \
        "Discards uncommitted changes permanently."
fi

if echo "$TOOL_INPUT" | grep -qiE 'git\s+branch\s+-D'; then
    theory_check "force delete git branch" \
        "Deletes branch regardless of merge status. Unmerged work will be lost."
fi

if echo "$TOOL_INPUT" | grep -qiE 'git\s+stash\s+(drop|clear)'; then
    theory_check "discard stashed work" \
        "Stash entries are permanently deleted. This cannot be undone."
fi

if echo "$TOOL_INPUT" | grep -qiE 'find\s+.*-delete'; then
    theory_check "find and delete" \
        "Deletes files matching the find pattern. Verify the pattern first."
fi

if echo "$TOOL_INPUT" | grep -qiE 'truncate\s+'; then
    theory_check "truncate file" \
        "Reduces file to zero bytes or specified size. Contents are lost."
fi

if echo "$TOOL_INPUT" | grep -qiE 'DROP\s+TABLE|DELETE\s+FROM|TRUNCATE\s+TABLE'; then
    theory_check "destructive database operation" \
        "Data deletion may be irreversible. Check which table/rows and whether backups exist."
fi

if echo "$TOOL_INPUT" | grep -qiE 'docker\s+system\s+prune|docker\s+volume\s+rm'; then
    theory_check "docker data destruction" \
        "Removes containers, images, or volumes. Data in volumes may be permanently lost."
fi

# ============================================================
# TIER 3: Irreversible Publishing
# ============================================================

if echo "$TOOL_INPUT" | grep -qiE 'npm\s+publish|pip\s+upload|twine\s+upload|cargo\s+publish'; then
    theory_check "package publishing" \
        "Publishes to a public registry. Version numbers may be permanently consumed."
fi

if echo "$TOOL_INPUT" | grep -qiE 'docker\s+push'; then
    theory_check "docker image publishing" \
        "Pushes image to a registry. May be publicly accessible."
fi

if echo "$TOOL_INPUT" | grep -qiE 'gh\s+release\s+create'; then
    theory_check "GitHub release creation" \
        "Creates a public release. Visible to anyone with repo access."
fi

if echo "$TOOL_INPUT" | grep -qiE 'terraform\s+(apply|destroy)'; then
    theory_check "infrastructure change (terraform)" \
        "Modifies live infrastructure. May affect production systems."
fi

# ============================================================
# TIER 4: Soft Warning
# ============================================================

if echo "$TOOL_INPUT" | grep -qiE 'chmod\s+(-R|777)'; then
    theory_check "permission change" \
        "chmod 777 makes files world-writable. -R applies recursively."
fi

if echo "$TOOL_INPUT" | grep -qiE 'chown\s+-R'; then
    theory_check "recursive ownership change" \
        "Changes file ownership recursively. May break application access."
fi

if echo "$TOOL_INPUT" | grep -qiE 'curl.*\|\s*(ba)?sh|wget.*\|\s*(ba)?sh'; then
    theory_check "piped remote execution" \
        "Downloads and executes unreviewed code with your permissions."
fi

if echo "$TOOL_INPUT" | grep -qiE '\bngrok\b|\blocaltunnel\b'; then
    theory_check "public tunnel to local service" \
        "Exposes local services to the internet. Anyone with the URL can connect."
fi

if echo "$TOOL_INPUT" | grep -qiE '0\.0\.0\.0'; then
    theory_check "binding to all interfaces" \
        "Listens on all network interfaces including public-facing ones."
fi

exit 0
