# VoidX Today Widget MVP

## Scope

- Shows today's remaining todos.
- Supports small, medium, and large WidgetKit families.
- Completes a todo from the widget with `CompleteTodoIntent`.
- Opens the main app with `voidxtodo://today` from the `+` button.

## Build Paths

### SwiftPM local bundle

```sh
scripts/run-app.sh
```

This builds the app and packages `VoidXTodoWidget.appex` into:

```txt
dist/VoidX Todo.app/Contents/PlugIns/VoidXTodoWidget.appex
```

This path is useful for local packaging checks, but macOS may not show the widget in the widget gallery when the app is only ad-hoc signed.

### Xcode WidgetKit path

```sh
xcodegen generate
open VoidXTodoMac.xcodeproj
```

In Xcode:

1. Select the `VoidXTodoMac` project.
2. Set a valid Apple Developer Team for both `VoidXTodoMac` and `VoidXTodoWidget`.
3. Build and run the `VoidXTodoMac` scheme.
4. Add `VoidX Today` from macOS widgets.

## Current Limitation

This Mac currently has no valid code signing identity, so the WidgetKit extension builds but may not register in the macOS widget gallery until a Developer Team signs the app and extension.
