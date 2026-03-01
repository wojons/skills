#!/bin/bash
set -e

echo "Dogfooding: Continuous Validation Setup" >&2
echo "========================================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --platform PLATFORM    CI/CD platform: github, gitlab, circleci, local (default: github)" >&2
    echo "  --frequency FREQ       Validation frequency: hourly, daily, weekly, push, pr (default: push)" >&2
    echo "  --output-dir DIR       Output directory for configuration files (default: .)" >&2
    echo "  --notify TYPE          Notification type: slack, email, webhook (comma-separated)" >&2
    echo "  --cron SCHEDULE        Custom cron schedule (overrides frequency)" >&2
    echo "  --verbose              Enable verbose output" >&2
    echo "  --help                 Show this help message" >&2
    exit 1
}

PLATFORM="github"
FREQUENCY="push"
OUTPUT_DIR="."
NOTIFY=""
CRON=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --frequency)
            FREQUENCY="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --notify)
            NOTIFY="$2"
            shift 2
            ;;
        --cron)
            CRON="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
    esac
done

# Validate platform
case "$PLATFORM" in
    github|gitlab|circleci|local)
        ;;
    *)
        echo "Error: Invalid platform '$PLATFORM'. Must be: github, gitlab, circleci, local" >&2
        exit 1
        ;;
esac

# Validate frequency
case "$FREQUENCY" in
    hourly|daily|weekly|push|pr)
        ;;
    *)
        echo "Error: Invalid frequency '$FREQUENCY'. Must be: hourly, daily, weekly, push, pr" >&2
        exit 1
        ;;
esac

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Creating output directory: $OUTPUT_DIR" >&2
    mkdir -p "$OUTPUT_DIR"
fi

echo "Setting up continuous dogfooding for $PLATFORM platform..." >&2
echo "Validation frequency: $FREQUENCY" >&2
echo "Output directory: $OUTPUT_DIR" >&2
if [ -n "$NOTIFY" ]; then
    echo "Notifications: $NOTIFY" >&2
fi
if [ -n "$CRON" ]; then
    echo "Custom cron: $CRON" >&2
fi
echo "" >&2

# Determine cron schedule
case "$FREQUENCY" in
    hourly)
        CRON_SCHEDULE="0 */6 * * *"
        ;;
    daily)
        CRON_SCHEDULE="0 0 * * *"
        ;;
    weekly)
        CRON_SCHEDULE="0 0 * * 0"
        ;;
    push)
        CRON_SCHEDULE=""
        ;;
    pr)
        CRON_SCHEDULE=""
        ;;
esac

if [ -n "$CRON" ]; then
    CRON_SCHEDULE="$CRON"
fi

# Generate platform-specific configuration
case "$PLATFORM" in
    github)
        GITHUB_DIR="$OUTPUT_DIR/.github/workflows"
        mkdir -p "$GITHUB_DIR"
        
        WORKFLOW_FILE="$GITHUB_DIR/dogfooding-validation.yml"
        
        cat << EOF > "$WORKFLOW_FILE"
name: Dogfooding Validation

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
$(if [ -n "$CRON_SCHEDULE" ]; then
    echo "  schedule:"
    echo "    - cron: '$CRON_SCHEDULE'"
fi)

jobs:
  validate-skills:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: |
          npm ci
          # Install skills CLI globally for validation
          npm install -g @vercel/skills
      
      - name: Setup skills symlinks
        run: npm run setup-symlinks
      
      - name: Validate all skills
        run: |
          echo "Starting comprehensive dogfooding validation..."
          ./skills/dogfooding/scripts/validate-dogfooding.sh \
            --scope all \
            --output dogfooding-validation-\$(date +%Y%m%d-%H%M%S).json \
            --verbose
      
      - name: Run installation tests on core skills
        run: |
          echo "Testing installation of core skills..."
          CORE_SKILLS="git-release react-review vercel-deploy skill-builder hypercognitive-skill-compiler"
          for skill in \$CORE_SKILLS; do
            echo "Testing skill: \$skill"
            if ./skills/dogfooding/scripts/test-skill-installation.sh --skill \$skill --dry-run; then
              echo "✅ \$skill passed dry-run installation test"
            else
              echo "❌ \$skill failed dry-run installation test"
              # Continue testing other skills even if one fails
            fi
          done
      
      - name: Generate validation report
        run: |
          echo "Generating dogfooding report..."
          # Find all validation JSON files
          find . -name "dogfooding-validation-*.json" -type f | head -5 > validation-files.txt
          
          if [ -s validation-files.txt ]; then
            ./skills/dogfooding/scripts/generate-dogfooding-report.sh \
              --input "\$(paste -s -d, validation-files.txt)" \
              --format markdown \
              --output dogfooding-report.md
          else
            echo "No validation files found, creating placeholder report"
            echo "# Dogfooding Validation Report" > dogfooding-report.md
            echo "No validation files were generated during this run." >> dogfooding-report.md
          fi
      
      - name: Upload validation report
        uses: actions/upload-artifact@v4
        with:
          name: dogfooding-report
          path: |
            dogfooding-report.md
            dogfooding-validation-*.json
      
      - name: Check for critical failures
        run: |
          # Simple check: if any core skill installation failed, mark as warning
          echo "Checking for critical failures..."
          # This would be expanded in a real implementation
          echo "No critical failure detection implemented yet"
EOF

        # Add notification steps if requested
        if [ -n "$NOTIFY" ]; then
            IFS=',' read -ra NOTIFY_TYPES <<< "$NOTIFY"
            for notify_type in "${NOTIFY_TYPES[@]}"; do
                case "$notify_type" in
                    slack)
                        cat << EOF >> "$WORKFLOW_FILE"

      - name: Notify Slack on failure
        if: failure()
        uses: slackapi/slack-github-action@v2
        with:
          channel-id: '\${{ secrets.SLACK_CHANNEL }}'
          slack-message: "Dogfooding validation failed for \${{ github.repository }}. See \${{ github.server_url }}/\${{ github.repository }}/actions/runs/\${{ github.run_id }}"
        env:
          SLACK_BOT_TOKEN: \${{ secrets.SLACK_BOT_TOKEN }}
EOF
                        ;;
                    webhook)
                        cat << EOF >> "$WORKFLOW_FILE"

      - name: Notify via Webhook on failure
        if: failure()
        run: |
          curl -X POST \
            -H "Content-Type: application/json" \
            -d '{"repository": "\${{ github.repository }}", "run_id": "\${{ github.run_id }}", "status": "failure", "message": "Dogfooding validation failed"}' \
            \${{ secrets.WEBHOOK_URL }}
EOF
                        ;;
                esac
            done
        fi
        
        echo "✅ GitHub Actions workflow created: $WORKFLOW_FILE" >&2
        
        # Create README for GitHub setup
        README_FILE="$OUTPUT_DIR/CONTINUOUS-DOGFOODING.md"
        cat << EOF > "$README_FILE"
# Continuous Dogfooding Setup

This repository has been configured for continuous dogfooding validation using GitHub Actions.

## What This Does

1. **Automatic validation** on every push and pull request to main/master branches
$(if [ -n "$CRON_SCHEDULE" ]; then
    echo "2. **Scheduled validation** every $FREQUENCY ($CRON_SCHEDULE)"
else
    echo "2. **Trigger-based validation** on push/PR events only"
fi)
3. **Skill installation testing** for all core skills
4. **Validation report generation** in multiple formats
5. **Artifact upload** of validation reports for review

## Generated Files

- \`.github/workflows/dogfooding-validation.yml\` - GitHub Actions workflow
- This documentation file

## How It Works

The dogfooding validation process:

1. **Checkout & Setup**: Repository is checked out and Node.js environment is set up
2. **Dependency Installation**: Skills CLI and project dependencies are installed
3. **Skill Symlinks**: Symlinks are created for OpenCode discovery
4. **Validation Execution**: All skills are validated using dogfooding scripts
5. **Installation Testing**: Core skills are tested for installability
6. **Report Generation**: Aggregated validation report is generated
7. **Artifact Upload**: Reports are uploaded as workflow artifacts

## Manual Trigger

You can manually trigger dogfooding validation:

\`\`\`bash
# Run comprehensive validation
./skills/dogfooding/scripts/validate-dogfooding.sh --scope all --verbose

# Test specific skill installation
./skills/dogfooding/scripts/test-skill-installation.sh --skill git-release --dry-run

# Generate aggregated report
./skills/dogfooding/scripts/generate-dogfooding-report.sh --directory . --format markdown
\`\`\`

## Customization

### Validation Frequency
Edit \`.github/workflows/dogfooding-validation.yml\` to change the schedule:

\`\`\`yaml
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
\`\`\`

### Skills to Test
Modify the \`CORE_SKILLS\` list in the workflow to test different skill categories.

### Notifications
Configure Slack or webhook notifications by adding secrets to your repository:
- \`SLACK_BOT_TOKEN\` and \`SLACK_CHANNEL\` for Slack notifications
- \`WEBHOOK_URL\` for custom webhook notifications

## Troubleshooting

### Workflow Fails on Skill Installation
1. Check if skills CLI is properly installed
2. Verify skill symlinks are created correctly
3. Ensure skill structure follows Agent Skills specification

### No Validation Reports Generated
1. Check workflow logs for script execution errors
2. Verify validation scripts have execute permissions
3. Ensure JSON report files are being created

### Performance Issues
For large skill repositories, consider:
1. Validating skills in parallel jobs
2. Caching node_modules between runs
3. Limiting validation to changed skills only

## Next Steps

1. Review the generated workflow file
2. Commit and push changes to trigger first validation
3. Monitor workflow results in GitHub Actions tab
4. Adjust validation based on initial results
5. Expand validation to include more skill categories over time

## Related Skills

- \`dogfooding\` - This skill, for continuous validation practices
- \`skill-builder\` - For skill structure validation patterns
- \`testing-ecosystem\` - For comprehensive testing methodology
- \`workflow-orchestrator\` - For workflow design and optimization
EOF
        
        echo "✅ Documentation created: $README_FILE" >&2
        ;;
        
    gitlab)
        GITLAB_FILE="$OUTPUT_DIR/.gitlab-ci.yml"
        echo "⚠️  GitLab CI configuration is not yet implemented" >&2
        echo "Creating placeholder GitLab CI configuration..." >&2
        
        cat << EOF > "$GITLAB_FILE"
# GitLab CI configuration for dogfooding validation
# This is a basic template - customize for your needs

variables:
  NODE_VERSION: "20"

stages:
  - validate

dogfooding-validation:
  stage: validate
  image: node:\$NODE_VERSION
  script:
    - npm ci
    - npm install -g @vercel/skills
    - npm run setup-symlinks
    - ./skills/dogfooding/scripts/validate-dogfooding.sh --scope all --output dogfooding-validation.json
  artifacts:
    paths:
      - dogfooding-validation.json
    expire_in: 1 week
  rules:
    - if: '\$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '\$CI_COMMIT_BRANCH == "\$CI_DEFAULT_BRANCH"'
EOF
        
        echo "✅ GitLab CI configuration created: $GITLAB_FILE" >&2
        ;;
        
    circleci)
        CIRCLECI_DIR="$OUTPUT_DIR/.circleci"
        mkdir -p "$CIRCLECI_DIR"
        
        CIRCLE_FILE="$CIRCLECI_DIR/config.yml"
        echo "⚠️  CircleCI configuration is not yet implemented" >&2
        echo "Creating placeholder CircleCI configuration..." >&2
        
        cat << EOF > "$CIRCLE_FILE"
version: 2.1

jobs:
  dogfooding-validation:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: |
            npm ci
            npm install -g @vercel/skills
      - run:
          name: Setup skills symlinks
          command: npm run setup-symlinks
      - run:
          name: Validate skills
          command: |
            ./skills/dogfooding/scripts/validate-dogfooding.sh \
              --scope all \
              --output dogfooding-validation.json
      - store_artifacts:
          path: dogfooding-validation.json

workflows:
  version: 2
  dogfooding:
    jobs:
      - dogfooding-validation:
          filters:
            branches:
              only: main
EOF
        
        echo "✅ CircleCI configuration created: $CIRCLE_FILE" >&2
        ;;
        
    local)
        LOCAL_SCRIPT="$OUTPUT_DIR/run-dogfooding-local.sh"
        
        cat << EOF > "$LOCAL_SCRIPT"
#!/bin/bash
set -e

echo "Local Dogfooding Validation Runner"
echo "===================================="

TIMESTAMP=\$(date +%Y%m%d-%H%M%S)
VALIDATION_DIR="dogfooding-validation-\$TIMESTAMP"
mkdir -p "\$VALIDATION_DIR"

echo "Validation output directory: \$VALIDATION_DIR"
echo ""

# Install dependencies if needed
if ! command -v skills > /dev/null 2>&1; then
    echo "Installing skills CLI..."
    npm install -g @vercel/skills
fi

# Run validation
echo "Running comprehensive dogfooding validation..."
./skills/dogfooding/scripts/validate-dogfooding.sh \
  --scope all \
  --output "\$VALIDATION_DIR/validation-\$TIMESTAMP.json" \
  --verbose

# Test core skills
echo ""
echo "Testing core skill installation..."
CORE_SKILLS="git-release react-review vercel-deploy skill-builder hypercognitive-skill-compiler"
for skill in \$CORE_SKILLS; do
    echo "Testing skill: \$skill"
    if ./skills/dogfooding/scripts/test-skill-installation.sh --skill \$skill --dry-run; then
        echo "✅ \$skill passed dry-run installation test"
    else
        echo "❌ \$skill failed dry-run installation test"
    fi
done

# Generate report
echo ""
echo "Generating aggregated report..."
./skills/dogfooding/scripts/generate-dogfooding-report.sh \
  --directory "\$VALIDATION_DIR" \
  --format markdown \
  --output "\$VALIDATION_DIR/dogfooding-report.md"

echo ""
echo "✅ Validation complete!"
echo "📊 Reports available in: \$VALIDATION_DIR"
echo "📄 Main report: \$VALIDATION_DIR/dogfooding-report.md"
EOF
        
        chmod +x "$LOCAL_SCRIPT"
        echo "✅ Local validation script created: $LOCAL_SCRIPT" >&2
        
        # Create cron job setup if frequency is scheduled
        if [ -n "$CRON_SCHEDULE" ]; then
            CRON_SCRIPT="$OUTPUT_DIR/setup-cron-job.sh"
            cat << EOF > "$CRON_SCRIPT"
#!/bin/bash
set -e

echo "Setting up cron job for dogfooding validation"
echo "Schedule: $CRON_SCHEDULE"
echo ""

CRON_JOB="$CRON_SCHEDULE cd $(pwd) && ./$LOCAL_SCRIPT > dogfooding-cron-\$(date +\%Y\%m\%d-\%H\%M\%S).log 2>&1"

echo "Adding cron job..."
(crontab -l 2>/dev/null | grep -v "$LOCAL_SCRIPT"; echo "\$CRON_JOB") | crontab -

echo "✅ Cron job added successfully!"
echo ""
echo "Current crontab:"
crontab -l
EOF
            
            chmod +x "$CRON_SCRIPT"
            echo "✅ Cron job setup script created: $CRON_SCRIPT" >&2
        fi
        ;;
esac

echo "" >&2
echo "Continuous dogfooding setup complete!" >&2
echo "" >&2
echo "Next steps:" >&2
echo "1. Review the generated configuration files" >&2
echo "2. Commit and push changes to trigger validation" >&2
echo "3. Monitor validation results and fix any issues" >&2
echo "4. Expand validation coverage over time" >&2
echo "" >&2
echo "Remember: Dogfooding is most valuable when done continuously!" >&2