#!/bin/bash
set -e

# chunk-conversation.sh
# Split a saved AI conversation file into numbered chunks.
# Each chunk is one human message followed by one AI response.
#
# Usage: bash chunk-conversation.sh conversation.txt [output-dir]
#
# Conversation format expected:
#   Human: ...message...
#   ---
#   AI: ...response...
#   ---
#   Human: ...next message...
#   etc.
#
# Lines starting with "Human:" begin a new chunk.
# Lines "---" are treated as separators.

INPUT="${1:-}"
OUTPUT_DIR="${2:-chunks}"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <conversation.txt> [output-dir]" >&2
    echo "  conversation.txt  Saved AI conversation file" >&2
    echo "  output-dir        Where to write chunks (default: ./chunks)" >&2
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: File not found: $INPUT" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

chunk_num=0
chunk_file=""
in_chunk=0

echo "Splitting $INPUT into chunks in $OUTPUT_DIR/" >&2

while IFS= read -r line; do
    # New human message starts a new chunk
    if echo "$line" | grep -qE "^(Human|User|Me):"; then
        # Save previous chunk if exists
        if [ -n "$chunk_file" ] && [ -s "$chunk_file" ]; then
            echo "  Saved: $(basename "$chunk_file")" >&2
        fi
        chunk_num=$((chunk_num + 1))
        chunk_file="$OUTPUT_DIR/chunk-$(printf '%03d' "$chunk_num").txt"
        in_chunk=1
        echo "$line" > "$chunk_file"
    elif [ $in_chunk -eq 1 ] && [ -n "$chunk_file" ]; then
        echo "$line" >> "$chunk_file"
    fi
done < "$INPUT"

# Save last chunk
if [ -n "$chunk_file" ] && [ -s "$chunk_file" ]; then
    echo "  Saved: $(basename "$chunk_file")" >&2
fi

echo "" >&2
echo "Created $chunk_num chunks in $OUTPUT_DIR/" >&2
echo "" >&2
echo "Paste them into your code AI one at a time, in order." >&2
echo "After each chunk, ask: 'What context have you built so far?'" >&2

# Output summary as JSON
echo "{\"chunks\": $chunk_num, \"output_dir\": \"$OUTPUT_DIR\"}"
