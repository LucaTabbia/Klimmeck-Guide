# Coding Conventions

**Analysis Date:** 2026-04-09

## Naming Patterns

**Files:**
- Dart files use snake_case: `splash_cubit.dart`, `journal_state.dart`, `cached_svg.dart`
- Widget files named after their class: `KGError` in `kg_error.dart`, `CachedSvg` in `cached_svg.dart`
- Cubit/State files follow pattern: `[feature]_cubit.dart` and `[feature]_state.dart` with state file as `part of` cubit
- Component files in subdirectories: `lib/shared/components/popup/equipment_info_display.dart`

**Classes:**
- Widget classes use PascalCase: `CachedSvg`, `KGError`, `EquipmentInfoSheetDisplay`, `AnimatedPencilText`
- State classes use PascalCase with descriptive suffix: `StorageInitial`, `StorageUpdated`, `StorageError`, `JournalLoading`, `JournalLoadData`
- Private state classes prefix with underscore: `_CachedSvgState`, `_ElErrorState`, `_EquipmentInfoSheetDisplayState`
- Model classes use PascalCase: `Coins`, `EquipmentItem`, `AssetQuantity`, `EquipType`
- Service/Repository classes use PascalCase: `KlimmeckRest`, `KlimmeckGraphQl`, `SvgCache`, `SvgCacheManager`

**Functions:**
- Use camelCase: `getStringToShowFromDuration()`, `getTotalAmount()`, `getImages()`, `fetchCloudinarySubfoldersUrls()`
- Private functions prefix with underscore: `_loadSvg()`, `_positionAnimation`, `_loading`
- Boolean getters/checks: `canAfford()`, `isCacheValid()`, `mounted`

**Variables:**
- Local variables use camelCase: `cachedFiles`, `imageUrls`, `totalCopper`, `newSilver`
- Private variables prefix with underscore: `_file`, `_loading`, `_instance`, `_controller`, `_fadeOut`
- Constants use UPPER_SNAKE_CASE or camelCase in class context
- Animation-related variables prefixed with underscore: `_positionAnimation`, `_fadeOut`
- State variables in State classes prefixed: `_file`, `_loading` (with underscore)

**Enums:**
- PascalCase for enum names: `EquipType`, `RarityType`
- Enum values in lowercase: `EquipType.helmet`, `RarityType.rare`

## Code Style

**Formatting:**
- Dart formatter (built-in) - auto-formats on save
- 2-space indentation (Dart standard)
- Line breaking: method calls and list items wrapped after 80 characters
- Bracket placement: opening brackets on same line, closing on new line for complex structures

**Linting:**
- Uses `flutter_lints` package (v6.0.0) via `package:flutter_lints/flutter.yaml`
- Run with: `flutter analyze`
- Configuration file: `analysis_options.yaml`
- Default recommended rules enabled with no custom overrides currently active

**Key Style Rules:**
- Use `const` for widget constructors when possible: `const CachedSvg({...})`
- Use `required` keyword for constructor parameters: `required String url`, `required this.selectedEquipment`
- Use `super.key` in widget constructors: `const KGError({super.key})`
- Use `late` keyword for deferred initialization: `late AnimationController _controller;`

## Import Organization

**Order:**
1. Dart imports: `import 'dart:io';`, `import 'dart:convert';`
2. Flutter imports: `import 'package:flutter/material.dart';`
3. BLoC/State management: `import 'package:flutter_bloc/flutter_bloc.dart';`, `import 'package:bloc/bloc.dart';`
4. Third-party packages: `import 'package:graphql_flutter/graphql_flutter.dart';`, `import 'package:equatable/equatable.dart';`
5. Local imports (relative paths): `import '../../repository/cache/svg_cache.dart';`
6. Part directives: `part 'splash_state.dart';`

**Path Aliases:**
- No path aliases currently used
- All imports use relative paths with proper depth traversal: `../../repository/...`

**Export Pattern:**
- No barrel exports observed
- Each file imported directly

## Error Handling

**Patterns:**
- Try-catch with rethrow in repository methods: See `lib/repository/services/rest/rest.dart`
- Try-catch with emit error state in Cubits: `emit(JournalError(e.toString()));`
- Try-catch with null return for optional results: `return null;` in `rest.dart` uploadImage
- Try-catch with debugPrint for non-critical errors: `debugPrint('CachedSvg: failed to load $e');`
- Silent catches converted to error emits in business logic

**Error State Classes:**
- All Cubits have dedicated error state: `StorageError`, `JournalError`, `SplashError`
- Error states carry message string: `const SplashError(this.error);`
- Errors implemented with Equatable for state comparison

**Exception Handling:**
- Re-throw in service layer: `catch (e) { rethrow; }`
- Emit in state management layer: `emit(JournalError(e.toString()));`
- Print/debugPrint in UI layer for user visibility

## Logging

**Framework:** Dart's built-in `print()` and `debugPrint()`

**Patterns:**
- Use `debugPrint()` for debug-only output in production builds
- Use `print()` for error reporting in service layer
- Format: `debugPrint('ComponentName: message')` or `debugPrint('message: $e\n$stack')`
- Include context in messages: `'CachedSvg: failed to load'`, `'LibraryCubit.loadLoreData error'`
- Stack traces included in error logs: `debugPrint('Error: $e\n$stack')`

**Examples from codebase:**
```dart
// Debug-only logging
debugPrint('CachedSvg: failed to load $e');
debugPrint('Error during Svg loading: $e\n$stack');
debugPrint('Precached ${imagePaths.length} images');

// Error reporting
print(e.toString());
print("Error uploading image: $e");
```

## Comments

**When to Comment:**
- Document public API classes with dartdoc comments
- Explain non-obvious logic or workarounds
- Minimal comments for self-documenting code (clear naming preferred)

**Dartdoc (///):**
- Use `///` for public API documentation: See `lib/config/env_config.dart`, `lib/config/cloudinary_assets.dart`
- Include method description and usage examples
- Document constructor parameters and their purpose

**Section Comments:**
- Use `// ============== Section Name ==============` for organizing large classes
- Seen in `cloudinary_assets.dart` and `env_config.dart` for grouping related constants

## Function Design

**Size:** Functions kept relatively small and focused
- Typical range: 10-40 lines for business logic
- Larger functions broken into private helper methods: `_loadSvg()`, `loadSvg()`
- State initialization in `initState()` and cleanup in `dispose()`

**Parameters:**
- Use named parameters for better readability: `const CachedSvg({ required this.url, ... })`
- Dart automatically ensures named params are named in calls
- Optional parameters with defaults: `this.fit = BoxFit.contain`
- `required` keyword enforced for non-nullable params

**Return Values:**
- Futures for async operations: `Future<void>`, `Future<List<String>>`
- Optional returns marked with `?`: `File?`, `List<String>?`
- State emissions return `Future<void>` in Cubits
- Widget `build()` always returns `Widget`

## Module Design

**Exports:**
- Classes exported from their files directly
- No barrel file pattern observed
- Direct imports from source files required

**Part/Part Of Pattern:**
- State files use `part 'state_name.dart'` to belong to Cubit file
- Cubit file uses `part 'cubit_state.dart'` at top
- Example: `lib/screens/splash/cubit/splash_state.dart` declares `part of 'splash_cubit.dart';`

**File Structure by Feature:**
```
lib/
  screens/[feature]/
    cubit/
      [feature]_cubit.dart (contains Cubit class + part directive)
      [feature]_state.dart (contains State classes, uses part of)
    [feature].dart (main screen widget)
    components/
      [component].dart
```

## Widget Patterns

**StatelessWidget:**
- Used for presentational components
- Constructor parameters final and immutable
- Example: `lib/shared/components/kg_error.dart`, `lib/shared/components/animated_pencil_text.dart`

**StatefulWidget:**
- Used for components with internal state or animations
- Private State class with underscore: `_EquipmentInfoSheetDisplayState`
- Extends `State<WidgetName>`
- Example: `lib/shared/components/cached_svg.dart`, `lib/shared/components/popup/equipment_info_display.dart`

**Mixins:**
- `SingleTickerProviderStateMixin` for animations
- Used in: `AnimatedPencilTextState` in `lib/shared/components/animated_pencil_text.dart`

**Animation Pattern:**
- Create AnimationController in `initState()`
- Dispose in `dispose()` method
- Use `CurvedAnimation` for curve timing
- Use `AnimatedBuilder` or `FadeTransition` for rendering

**Widget Testing (mounted checks):**
- Extend `State<Widget>` and use `State<T>`
- Use `if (mounted)` before setState calls: `if (mounted) setState(() { _file = cached; });`
- Check mounted before state changes to prevent memory leaks

## Lifecycle Methods

**StatefulWidget Lifecycle:**
- `initState()`: Initialize state, load data, start animations
- `didUpdateWidget()`: Respond to widget property changes
- `didChangeDependencies()`: Respond to dependency changes
- `build()`: Construct UI
- `dispose()`: Cleanup animations, subscriptions

## Model Patterns

**Equatable Mixin:**
- All data models extend `Equatable`: `class Coins extends Equatable`
- Implement `props` getter: `List<Object?> get props => [gold, silver, copper]`
- Enables value equality comparison
- Used in State classes for proper state comparison

**JSON Serialization:**
- Use `fromJson()` factory constructor
- Use `toJson()` method
- Manual implementation (not code generation via json_serializable)
- Example: See `lib/models/coins.dart`, `lib/models/asset_quantity.dart`, `lib/models/equipment_item.dart`

**CopyWith Pattern:**
- Implement `copyWith()` for immutable updates
- Only copy specified fields, rest retain original values
- Example: `Coins.copyWith({int? gold, int? silver, int? copper})`

**Operators:**
- Implement custom operators for domain logic: `Coins operator +`, `Coins operator -`
- Comparison operators for sorting/validation: `operator >`, `operator <`, `operator >=`

---

*Convention analysis: 2026-04-09*
