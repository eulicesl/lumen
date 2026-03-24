#!/usr/bin/env bash
set -euo pipefail

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Lumen AI — Project Structure Validator          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Platform: iOS 26 / iPadOS 26 / macOS 26 (native Swift project)"
echo "Language: Swift 6 (strict concurrency)"
echo "Architecture: MVVM + Actors + @Observable"
echo ""

ROOT="$(cd "$(dirname "$0")" && pwd)"
LUMEN="$ROOT/Lumen"
TESTS="$ROOT/LumenTests"

echo "── Project Root: $ROOT"
echo ""

pass=0
fail=0

check_file() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "  ✅  $path"
        ((pass++)) || true
    else
        echo "  ❌  MISSING: $path"
        ((fail++)) || true
    fi
}

echo "▶ App Layer"
check_file "$LUMEN/App/LumenApp.swift"
check_file "$LUMEN/App/AppDelegate.swift"
check_file "$LUMEN/App/ContentView.swift"
echo ""

echo "▶ Design System"
check_file "$LUMEN/DesignSystem/LumenTokens.swift"
check_file "$LUMEN/DesignSystem/LumenColor.swift"
check_file "$LUMEN/DesignSystem/LumenIcon.swift"
check_file "$LUMEN/DesignSystem/Components/GlassContainer.swift"
check_file "$LUMEN/DesignSystem/Components/LumenButton.swift"
check_file "$LUMEN/DesignSystem/Components/LoadingIndicator.swift"
echo ""

echo "▶ Domain Models"
check_file "$LUMEN/Models/AIModel.swift"
check_file "$LUMEN/Models/ChatMessage.swift"
check_file "$LUMEN/Models/Conversation.swift"
check_file "$LUMEN/Models/ChatToken.swift"
check_file "$LUMEN/Models/Enums/MessageRole.swift"
check_file "$LUMEN/Models/Enums/ConversationState.swift"
check_file "$LUMEN/Models/Enums/AIProviderType.swift"
echo ""

echo "▶ Data Layer"
check_file "$LUMEN/Data/SwiftData/ConversationSD.swift"
check_file "$LUMEN/Data/SwiftData/MessageSD.swift"
check_file "$LUMEN/Data/SwiftData/AIModelSD.swift"
check_file "$LUMEN/Data/SwiftData/Schema.swift"
check_file "$LUMEN/Data/DataService.swift"
echo ""

echo "▶ Service Layer"
check_file "$LUMEN/Services/Providers/AIProvider.swift"
check_file "$LUMEN/Services/Providers/OllamaProvider.swift"
check_file "$LUMEN/Services/Providers/FoundationModelsProvider.swift"
check_file "$LUMEN/Services/AIService.swift"
echo ""

echo "▶ State Stores"
check_file "$LUMEN/Stores/AppStore.swift"
check_file "$LUMEN/Stores/ChatStore.swift"
check_file "$LUMEN/Stores/ModelStore.swift"
echo ""

echo "▶ Views — Chat (Phase 1)"
check_file "$LUMEN/Views/Shared/Chat/ChatView.swift"
check_file "$LUMEN/Views/Shared/Chat/MessageBubbleView.swift"
check_file "$LUMEN/Views/Shared/Chat/InputBarView.swift"
echo ""

echo "▶ Views — Sidebar (Phase 1)"
check_file "$LUMEN/Views/Shared/Sidebar/ConversationListView.swift"
check_file "$LUMEN/Views/Shared/Sidebar/ConversationRowView.swift"
echo ""

echo "▶ Views — Models + Settings (Phase 1)"
check_file "$LUMEN/Views/Shared/Models/ModelPickerView.swift"
check_file "$LUMEN/Views/Shared/Settings/SettingsView.swift"
echo ""

echo "▶ Views — Platform Shells"
check_file "$LUMEN/Views/iOS/MainTabView.swift"
check_file "$LUMEN/Views/iOS/iPadContentView.swift"
check_file "$LUMEN/Views/macOS/MacContentView.swift"
echo ""

echo "▶ Extensions"
check_file "$LUMEN/Extensions/Date+Grouping.swift"
check_file "$LUMEN/Extensions/String+Markdown.swift"
echo ""

echo "▶ Tests"
check_file "$TESTS/DataServiceTests.swift"
check_file "$TESTS/AIProviderMock.swift"
echo ""

total=$((pass + fail))
echo "══════════════════════════════════════════════════════════════"
echo "  Files present : $pass / $total"
echo "  Files missing : $fail"

if [ "$fail" -eq 0 ]; then
    echo ""
    echo "  ✅  All required source files are present."
    echo "  📦  Open Lumen/ in Xcode 26 to build and run."
else
    echo ""
    echo "  ⚠️   Some files are missing. Re-run the agent to regenerate."
fi
echo "══════════════════════════════════════════════════════════════"
echo ""

echo "File sizes:"
find "$LUMEN" "$TESTS" -name "*.swift" | sort | while read -r f; do
    lines=$(wc -l < "$f")
    rel="${f#$ROOT/}"
    printf "  %4d lines  %s\n" "$lines" "$rel"
done
echo ""
echo "Total Swift files: $(find "$LUMEN" "$TESTS" -name "*.swift" | wc -l)"
echo ""
echo "Note: This is a native Swift/Xcode project targeting iOS 26 / macOS 26."
echo "      Build and run requires Xcode 26 on macOS."
echo ""

sleep infinity
