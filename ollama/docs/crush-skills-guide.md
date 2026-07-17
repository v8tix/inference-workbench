# Crush — Skills Configuration

> Reference config: `ollama/crush/crush.json`  
> Live config: `~/.config/crush/crush.json`

---

## What are Crush skills

Crush supports the [Agent Skills](https://agentskills.io) open standard — folders containing a `SKILL.md` file with reusable instructions the agent can discover and activate on demand. Same format Claude Code uses.

## Default discovery paths

Crush looks for skills in these locations automatically, no config needed:

- `$CRUSH_SKILLS_DIR`
- `~/.config/agents/skills/`
- `~/.config/crush/skills/`
- `~/.agents/skills/`
- `~/.claude/skills/`
- Project-local: `.agents/skills`, `.crush/skills`

## Why this setup uses `skills_paths`

Our real skills don't live in any of those default paths — they're installed as **Claude Code plugins**, cached under versioned directories:

```
~/.claude/plugins/cache/caveman/caveman/<commit>/skills/
~/.claude/plugins/cache/cpgs-marketplace/cpgs-clg-ai/<version>/skills/
```

To expose them to Crush, `crush.json` sets `options.skills_paths` pointing directly at those cache directories:

```json
{
  "options": {
    "skills_paths": [
      "/Users/vrock/.claude/plugins/cache/caveman/caveman/c2ed24b3e5d4/skills",
      "/Users/vrock/.claude/plugins/cache/cpgs-marketplace/cpgs-clg-ai/1.7.1/skills"
    ]
  }
}
```

## Skills currently exposed

| Source plugin | Skills |
|---|---|
| `caveman` | caveman, caveman-help, caveman-commit, compress, caveman-review |
| `cpgs-clg-ai` | cpgs-clg-core-endpoints, golang-cpgs, migrate, redash-datasources, cpgs-clg-core-testing-plan, open-orders-post-deploy, token-efficiency, pr-description-generator |

## The version-pinning caveat

These paths are **pinned to a specific plugin version/commit**:

- `caveman/caveman/c2ed24b3e5d4` — a commit hash
- `cpgs-clg-ai/1.7.1` — a version number

When Claude Code updates either plugin, the cache directory changes and the old path stops existing. Crush won't error loudly — it just silently stops finding those skills.

**Fix when this happens:**

```bash
find ~/.claude/plugins/cache/caveman -maxdepth 4 -iname SKILL.md
find ~/.claude/plugins/cache/cpgs-marketplace -maxdepth 4 -iname SKILL.md
```

Update the paths in `crush.json` to match the new version directory.

## Verifying skills loaded

```bash
crush --debug run --quiet "hi" 2>&1
crush logs --tail 50 | grep -i skill
```

Look for lines like:

```
DEBU Successfully loaded skill name=caveman path=.../skills/caveman/SKILL.md
```

## Alternative: symlink instead of skills_paths

A less brittle option (not used here, but worth knowing): symlink each skill folder into `~/.config/crush/skills/`. Same effect, but the symlink target still breaks on a plugin version bump unless it points at a version-agnostic path. Since plugin caches are always versioned, `skills_paths` with a periodic path check is effectively equivalent — just less indirection.
