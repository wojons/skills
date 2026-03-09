---
name: context-pack
description: Pack codebases, folders, or ZIP archives into LLM-friendly context format with smart filtering, file selection, and markdown structure
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: workflow
---

# Context Pack

Pack any codebase, folder, or ZIP archive into a single, well-formatted text block perfect for LLM context windows. Smart filtering, interactive selection, and clean markdown output.

## When to use me

Use this skill when you need to:
- Send an entire codebase to an LLM for analysis or modification
- Share a project with another AI agent for collaboration
- Create context for code review or debugging
- Package documentation and code together for AI consumption
- Convert legacy projects into LLM-ready format

## What I do

### 1. Smart File Discovery
- Automatically finds all files in a directory or ZIP
- Respects `.gitignore` patterns
- Filters out common noise (node_modules, .git, build artifacts)
- Handles nested directory structures

### 2. File Type Detection
- **Text files**: Included as-is (code, docs, config)
- **Binary files**: Optional Base64 encoding (images, executables, binaries)
- **Unknown files**: Smart detection with fallback to binary

### 3. Interactive Selection
- Preview file tree before packing
- Select/deselect specific files or directories
- Filter by file type, size, or pattern
- See statistics (total size, file count, token estimate)

### 4. Smart Formatting

**Output format:**
```markdown
# Context Pack: project-name

## Summary
- Source: /path/to/project
- Files: 42
- Size: 156 KB
- Token estimate: ~50,000

## File Tree
```
src/
├── index.ts
├── utils/
│   └── helpers.ts
└── components/
    └── Button.tsx
```

## Files

### src/index.ts
```typescript
// File content here...
```

### src/utils/helpers.ts
```typescript
// File content here...
```

### src/components/Button.tsx
```typescript
// File content here...
```
```

### 5. Binary Handling
```markdown
## Binary Files (Base64 Encoded)

### assets/logo.png
```base64
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1I
g1AcxV/TaqVVHuwQxCFDdwURXQQXU8QII0M9k9q0QhGzBjOjog7WFpaCujgEC/pBj6Bg56KOqI4K7gN+
...
```
```

## Examples

### Pack a folder
```bash
# Pack current directory
bash scripts/pack.sh .

# Pack specific directory
bash scripts/pack.sh /path/to/myproject

# Pack with binary files included
bash scripts/pack.sh . --include-binary

# Pack with specific file limit
bash scripts/pack.sh . --max-files 50 --max-size 1MB
```

### Pack a ZIP archive
```bash
bash scripts/pack.sh project.zip

# Extract and pack
bash scripts/pack.sh archive.zip --extract-to ./temp
```

### Filter files
```bash
# Only include TypeScript files
bash scripts/pack.sh . --include "*.ts" --include "*.tsx"

# Exclude tests
bash scripts/pack.sh . --exclude "*test*" --exclude "*spec*"

# Include only src directory
bash scripts/pack.sh . --include-dir "src"
```

### Interactive selection
```bash
# Preview and select interactively
bash scripts/pack.sh . --interactive

# This shows a file tree where you can:
# - [x] Select files/folders with checkboxes
# - See file sizes and types
# - Toggle binary inclusion
# - Preview before generating
```

### Output options
```bash
# Output to file
bash scripts/pack.sh . --output project-context.md

# Copy to clipboard (if available)
bash scripts/pack.sh . --clipboard

# JSON output for programmatic use
bash scripts/pack.sh . --format json
```

## File Type Support

### Text Files (Included by default)
- **Code**: `.js`, `.ts`, `.jsx`, `.tsx`, `.py`, `.java`, `.c`, `.cpp`, `.go`, `.rs`, `.php`, `.rb`
- **Web**: `.html`, `.htm`, `.css`, `.scss`, `.sass`, `.less`
- **Config**: `.json`, `.xml`, `.yml`, `.yaml`, `.toml`, `.ini`, `.conf`, `.env`
- **Docs**: `.md`, `.txt`, `.csv`, `.tsv`, `.log`
- **Scripts**: `.sh`, `.bash`, `.zsh`, `.ps1`, `.bat`

### Binary Files (Optional Base64)
- **Images**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.ico`, `.webp`, `.bmp`
- **Executables**: `.exe`, `.bin`, `.app`, `.dll`, `.so`, `.dylib`
- **Archives**: `.zip`, `.tar`, `.gz`, `.rar`, `.7z`
- **Documents**: `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`
- **Other**: `.mp3`, `.mp4`, `.wav`, `.avi`, `.mov`, `.ttf`, `.otf`, `.woff`

## Scripts

### `scripts/pack.sh`
Main packing script with options for filtering and output.

```bash
bash scripts/pack.sh [OPTIONS] <path>

Options:
  -i, --include PATTERN      Include files matching pattern
  -e, --exclude PATTERN      Exclude files matching pattern
  -d, --include-dir DIR      Include only this directory
  --include-binary            Include binary files as Base64
  --max-files N              Maximum number of files
  --max-size SIZE            Maximum total size (e.g., 10MB, 1GB)
  --max-tokens N             Maximum token estimate
  -o, --output FILE          Output file (default: stdout)
  --format FORMAT            Output format: markdown, json, plain
  --clipboard                Copy output to clipboard
  --interactive              Interactive file selection
  -v, --verbose              Verbose output
  -h, --help                 Show help
```

### `scripts/pack-web.sh`
Launch web-based interactive interface for file selection.

```bash
# Launch web UI
bash scripts/pack-web.sh [path]

# Opens browser with:
# - File tree browser with checkboxes
# - Size statistics
# - Token count estimates
# - Preview before packing
```

### `scripts/unpack.sh`
Extract a context pack back into files.

```bash
bash scripts/unpack.sh <context-file> [output-dir]

# Extracts files from markdown format
# Reconstructs directory structure
# Decodes Base64 binary files
```

## Output Format

### Markdown (Default)
```markdown
# Context Pack: my-project

## Summary
- **Source**: /path/to/my-project
- **Packed**: 2024-03-08T10:30:15Z
- **Files**: 42 (38 text, 4 binary)
- **Size**: 156 KB
- **Token Estimate**: ~52,000 tokens

## File Tree
```
my-project/
├── src/
│   ├── index.ts
│   ├── utils/
│   │   └── helpers.ts
│   └── components/
│       └── Button.tsx
├── package.json
└── README.md
```

## Files

### package.json
```json
{
  "name": "my-project",
  "version": "1.0.0",
  "type": "module"
}
```

### src/index.ts
```typescript
import { Button } from './components/Button';

export function init() {
  const button = new Button('Click me');
  button.render();
}
```

### src/utils/helpers.ts
```typescript
export function formatDate(date: Date): string {
  return date.toISOString().split('T')[0];
}
```

## Binary Files (Base64 Encoded)

### assets/logo.png
```base64
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAA...
```

---
*Packed with Context Pack skill*
```

### JSON Format
```json
{
  "pack": {
    "name": "my-project",
    "source": "/path/to/my-project",
    "packed_at": "2024-03-08T10:30:15Z",
    "stats": {
      "files": 42,
      "text_files": 38,
      "binary_files": 4,
      "size_bytes": 156432,
      "estimated_tokens": 52000
    },
    "file_tree": {
      "name": "my-project",
      "type": "directory",
      "children": [...]
    }
  },
  "files": [
    {
      "path": "package.json",
      "type": "text",
      "size": 234,
      "content": "{...}"
    },
    {
      "path": "src/index.ts",
      "type": "text",
      "size": 567,
      "content": "import..."
    },
    {
      "path": "assets/logo.png",
      "type": "binary",
      "size": 12345,
      "encoding": "base64",
      "content": "iVBORw0KGgo..."
    }
  ]
}
```

## Token Estimation

Rough token counts for LLM context windows:

| File Type | Approximate Tokens |
|-----------|-------------------|
| English text | ~4 chars per token |
| Code | ~3 chars per token |
| JSON | ~2 chars per token |
| Base64 binary | ~1 char per token |

**Quick estimates:**
- 1 KB of code ≈ 300 tokens
- 1 KB of text ≈ 250 tokens
- 1 KB Base64 ≈ 1000 tokens (avoid large binaries)

**Context window limits:**
- GPT-4: ~8K-32K tokens
- Claude: ~100K-200K tokens
- Gemini: ~1M tokens

## Interactive Mode

When using `--interactive`, you get a TUI (Text User Interface) for file selection:

```
Context Pack - Interactive Mode
================================

File Tree (use arrows to navigate, space to select)
[✓] my-project/
  [✓] src/
    [✓] index.ts                                      567 B
    [✓] utils/
      [✓] helpers.ts                                 1.2 KB
    [✓] components/
      [✓] Button.tsx                                  890 B
  [✓] package.json                                  234 B
  [ ] node_modules/                                 [skip]
  [ ] .git/                                         [skip]

Statistics:
  Selected: 5 files, 2.9 KB
  Skipped: 847 files (node_modules, .git)
  Est. tokens: ~9,500

Commands:
  [SPACE] Toggle selection  [A] Select all  [N] None
  [E] Exclude pattern       [I] Include pattern
  [B] Toggle binary files   [P] Preview
  [ENTER] Generate pack     [Q] Quit
```

## Notes

- **Privacy**: All processing is local - no files are uploaded
- **Large codebases**: Use `--max-files` and `--max-tokens` to stay within limits
- **Binary files**: Large binaries bloat context - consider excluding them
- **Token counts**: Estimates are approximate - actual counts vary by model
- **Markdown preferred**: LLMs parse markdown structure well
- **File order**: Files are sorted by path for consistent output
- **Deduplication**: Identical files are only included once
- **Circular references**: Symlinks are resolved and handled
