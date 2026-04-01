#!/bin/bash
#
# Regenerate README.md files for all skills
# Run this after adding new skills or updating SKILL.md frontmatter
#
# Usage: bash scripts/generate-readmes.sh [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$SCRIPT_DIR")/skills"

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo "Generating README.md files for all skills..."
echo ""

count=0
for skill_dir in "$SKILLS_DIR"/*/; do
    [[ ! -d "$skill_dir" ]] && continue
    
    skill_md="$skill_dir/SKILL.md"
    readme_md="$skill_dir/README.md"
    skill_name=$(basename "$skill_dir")
    
    if [[ ! -f "$skill_md" ]]; then
        echo "⚠ Skipping $skill_name: No SKILL.md found"
        continue
    fi
    
    # Extract frontmatter values
    name=$(grep "^name:" "$skill_md" | head -1 | cut -d: -f2- | xargs)
    description=$(grep "^description:" "$skill_md" | head -1 | cut -d: -f2- | xargs)
    category=$(grep "^  category:" "$skill_md" | head -1 | cut -d: -f2- | xargs)
    
    # Use name or skill_name as fallback
    display_name="${name:-$skill_name}"
    
    # Generate README content
    if [[ "$DRY_RUN" == true ]]; then
        echo "Would create: $readme_md"
    else
        cat > "$readme_md" << EOF
# $display_name

${description:-A skill for the OpenCode agent framework.}

## Overview

Category: **${category:-General}**

## When to Use

See [SKILL.md](./SKILL.md) for the full documentation including:
- Detailed usage instructions
- Examples and patterns  
- Integration with other skills

## Installation

\`\`\`bash
npx skills add wojons/skills --skill $skill_name
\`\`\`

## License

MIT

## Related Skills

See the [skills repository](https://github.com/wojons/skills) for all available skills.
EOF
        echo "✓ Created: $skill_name/README.md"
        ((count++))
    fi
done

echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run complete. Would generate README.md files."
else
    echo "Generated $count README.md files"
fi