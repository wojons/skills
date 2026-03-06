#!/bin/bash
set -e

# validate-todo.sh
# Check a TODO.md file for items that are too vague or missing success criteria.
# Flags items the build agent could not complete without asking a question.
#
# Usage: bash validate-todo.sh TODO.md

TODO_FILE="${1:-TODO.md}"

if [ ! -f "$TODO_FILE" ]; then
    echo "Error: File not found: $TODO_FILE" >&2
    exit 1
fi

echo "Validating TODO items in $TODO_FILE" >&2
echo "" >&2

warnings=0
items=0
vague_words="implement add create build fix update improve refactor handle"

while IFS= read -r line; do
    # Only check unchecked items
    if echo "$line" | grep -qE "^\s*- \[ \]"; then
        items=$((items + 1))
        item_text=$(echo "$line" | sed 's/^\s*- \[ \] //')

        # Check for success condition keywords
        has_success=0
        for kw in "success:" "done when" "passes" "returns" "outputs" "all tests"; do
            if echo "$item_text" | grep -qi "$kw"; then
                has_success=1
                break
            fi
        done

        # Check for spec reference
        has_spec_ref=0
        if echo "$item_text" | grep -qi "spec\|section\|per "; then
            has_spec_ref=1
        fi

        # Check for vague single-verb items (short items with no detail)
        word_count=$(echo "$item_text" | wc -w | tr -d ' ')
        is_too_short=0
        if [ "$word_count" -lt 8 ]; then
            is_too_short=1
        fi

        # Check for vague standalone verbs
        is_vague=0
        first_word=$(echo "$item_text" | awk '{print tolower($1)}')
        for vague in $vague_words; do
            if [ "$first_word" = "$vague" ] && [ "$is_too_short" -eq 1 ]; then
                is_vague=1
                break
            fi
        done

        # Report issues
        item_issues=""
        if [ $has_success -eq 0 ]; then
            item_issues="$item_issues [no success condition]"
        fi
        if [ $has_spec_ref -eq 0 ]; then
            item_issues="$item_issues [no spec reference]"
        fi
        if [ $is_vague -eq 1 ]; then
            item_issues="$item_issues [too vague - add detail]"
        fi

        if [ -n "$item_issues" ]; then
            warnings=$((warnings + 1))
            echo "  WARN item $items:$item_issues" >&2
            echo "       $item_text" | head -c 120 >&2
            echo "" >&2
        fi
    fi
done < "$TODO_FILE"

pending=$(grep -cE "^\s*- \[ \]" "$TODO_FILE" 2>/dev/null || echo 0)
done_count=$(grep -cE "^\s*- \[x\]" "$TODO_FILE" 2>/dev/null || echo 0)

echo "" >&2
echo "Summary:" >&2
echo "  Pending tasks:  $pending" >&2
echo "  Completed:      $done_count" >&2
echo "  Warnings:       $warnings" >&2

if [ "$warnings" -gt 0 ]; then
    echo "" >&2
    echo "Fix warnings before running the Ralph loop." >&2
    echo "Agents will stall on vague items with no success condition." >&2
fi

echo "{\"pending\": $pending, \"done\": $done_count, \"warnings\": $warnings}"

# Exit non-zero if there are warnings so CI can fail on bad TODOs
if [ "$warnings" -gt 0 ]; then
    exit 1
fi
