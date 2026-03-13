#!/bin/bash
# skillhub CLI wrapper for agent skills management
# Usage: ./usage.sh '<json>'
# Example: ./usage.sh '{"action": "search", "query": "weather"}'

set -e

JSON_INPUT="$1"

if [ -z "$JSON_INPUT" ]; then
    echo "Usage: ./usage.sh '<json>'"
    echo ""
    echo "Actions:"
    echo "  search       Search skills in the store"
    echo "  install      Install a skill by slug"
    echo "  upgrade      Upgrade installed skills"
    echo "  list         List locally installed skills"
    echo "  self-upgrade Self-upgrade the skillhub CLI"
    echo ""
    echo "Examples:"
    echo "  ./usage.sh '{\"action\": \"search\", \"query\": \"weather\"}'"
    echo "  ./usage.sh '{\"action\": \"install\", \"slug\": \"weather\"}'"
    echo "  ./usage.sh '{\"action\": \"upgrade\"}'"
    echo "  ./usage.sh '{\"action\": \"list\"}'"
    exit 1
fi

# Validate JSON
if ! echo "$JSON_INPUT" | jq empty 2>/dev/null; then
    echo "Error: Invalid JSON input"
    exit 1
fi

# Extract action
ACTION=$(echo "$JSON_INPUT" | jq -r '.action // empty')

if [ -z "$ACTION" ]; then
    echo "Error: 'action' field is required (search, install, upgrade, list, self-upgrade)"
    exit 1
fi

# Build skillhub command based on action
case "$ACTION" in
    search)
        QUERY=$(echo "$JSON_INPUT" | jq -r '.query // empty')
        LIMIT=$(echo "$JSON_INPUT" | jq -r '.limit // 20')
        TIMEOUT=$(echo "$JSON_INPUT" | jq -r '.timeout // 6')
        JSON_OUTPUT=$(echo "$JSON_INPUT" | jq -r '.json // false')
        
        CMD="skillhub search"
        [ -n "$QUERY" ] && CMD="$CMD $QUERY"
        CMD="$CMD --search-limit $LIMIT"
        CMD="$CMD --search-timeout $TIMEOUT"
        [ "$JSON_OUTPUT" = "true" ] && CMD="$CMD --json"
        ;;
    
    install)
        SLUG=$(echo "$JSON_INPUT" | jq -r '.slug // empty')
        FORCE=$(echo "$JSON_INPUT" | jq -r '.force // false')
        
        if [ -z "$SLUG" ]; then
            echo "Error: 'slug' is required for install action"
            exit 1
        fi
        
        CMD="skillhub install"
        [ "$FORCE" = "true" ] && CMD="$CMD --force"
        CMD="$CMD $SLUG"
        ;;
    
    upgrade)
        SLUG=$(echo "$JSON_INPUT" | jq -r '.slug // empty')
        CHECK_ONLY=$(echo "$JSON_INPUT" | jq -r '.check_only // false')
        TIMEOUT=$(echo "$JSON_INPUT" | jq -r '.timeout // 20')
        
        CMD="skillhub upgrade"
        [ "$CHECK_ONLY" = "true" ] && CMD="$CMD --check-only"
        CMD="$CMD --timeout $TIMEOUT"
        [ -n "$SLUG" ] && CMD="$CMD $SLUG"
        ;;
    
    list)
        CMD="skillhub list"
        ;;
    
    self-upgrade)
        CHECK_ONLY=$(echo "$JSON_INPUT" | jq -r '.check_only // false')
        CURRENT_VERSION=$(echo "$JSON_INPUT" | jq -r '.current_version // empty')
        TIMEOUT=$(echo "$JSON_INPUT" | jq -r '.timeout // 20')
        
        CMD="skillhub self-upgrade"
        [ "$CHECK_ONLY" = "true" ] && CMD="$CMD --check-only"
        [ -n "$CURRENT_VERSION" ] && CMD="$CMD --current-version $CURRENT_VERSION"
        CMD="$CMD --timeout $TIMEOUT"
        ;;
    
    *)
        echo "Error: Unknown action '$ACTION'"
        echo "Valid actions: search, install, upgrade, list, self-upgrade"
        exit 1
        ;;
esac

# Execute the command
eval "$CMD"
