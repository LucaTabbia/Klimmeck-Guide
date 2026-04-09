# Testing Patterns

**Analysis Date:** 2026-04-09

## Test Framework

**Runner:**
- flutter_test (SDK built-in) - Native Flutter testing framework
- No external test runner package needed
- Config: No separate config file; tests discovered via `test/` directory convention

**Assertion Library:**
- Dart's built-in `expect()` function from `flutter_test` package

**Run Commands:**
```bash
flutter test                    # Run all tests
flutter test --watch           # Watch mode (re-run on changes)
flutter test --coverage        # Generate coverage report
flutter test test/widget_test.dart  # Run specific test file
```

## Test File Organization

**Location:**
- Tests co-located in `test/` directory at project root (separate from source code)
- Test files mirror source structure: `test/widget_test.dart` for main app tests
- Not co-located with source files (separate test folder pattern)

**Naming:**
- `*_test.dart` suffix convention (standard Flutter)
- File: `test/widget_test.dart`

**Structure:**
```
test/
├── widget_test.dart          # Widget and integration tests
└── (additional test files follow same pattern)
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Test implementation
    expect(find.text('0'), findsOneWidget);
  });
}
```

**Patterns:**
- `void main()` entry point with test suites
- `testWidgets()` for widget tests (async test function)
- `WidgetTester` parameter for widget interaction
- Single test function without nesting (flat structure observed)

**Test Lifecycle:**
- Setup: Initialize components before test (implicit in `testWidgets`)
- Action: Use tester methods to interact with widget
- Assert: Use `expect()` to verify behavior

## Widget Testing

**Key Methods (from test/widget_test.dart):**
```dart
// Build widgets
await tester.pumpWidget(KlimmeckGuideApp(client: client));

// Find widgets
find.text('0')         // Find by text content
find.byIcon(Icons.add) // Find by icon

// Widget matchers
findsOneWidget         // Expect exactly one match
findsNothing           // Expect no matches
findsWidgets           // Find multiple widgets

// Interaction
await tester.tap(find.byIcon(Icons.add));  // Tap a widget
await tester.pump();   // Render frame (without animations)
```

## Mocking

**Framework:** Not detected in current codebase

**Current Approach:**
- Tests use real GraphQL client initialization: `final client = initGraphQLClient();`
- No mock objects or stubs observed
- Real dependencies passed to widgets and cubits during testing
- Integration-style testing pattern

**What to Mock (recommended additions):**
- GraphQL client responses (for unit testing cubits)
- HTTP responses (for REST service testing)
- Local storage/preferences (for storage_cubit testing)
- File system operations (for SVG cache testing)

**What NOT to Mock:**
- Widget rendering (test against real widgets)
- Flutter framework components
- Animation controllers (test animation behavior)

## Fixtures and Factories

**Test Data:**
- Not detected in current codebase
- Single test file with hardcoded expectations: `expect(find.text('0'), findsOneWidget);`
- No factory or fixture pattern for test data

**Recommended Pattern (for future tests):**
```dart
// Could add test fixtures at top of test files
const testUser = User(id: '1', name: 'Test User');
final testCharacter = Character(id: '1', name: 'TestChar', userId: '1');

testWidgets('displays user name', (WidgetTester tester) async {
  await tester.pumpWidget(const UserWidget(user: testUser));
  expect(find.text('Test User'), findsOneWidget);
});
```

**Location:**
- If added, would be in `test/` directory
- Suggested: `test/fixtures/` subdirectory for shared test data

## Coverage

**Requirements:** Not detected - no coverage enforcement

**View Coverage:**
```bash
flutter test --coverage
lcov --list coverage/lcov.info  # View coverage report (requires lcov)
```

**Current Status:**
- Limited test coverage (only one smoke test file)
- Most Cubits, Services, and Models untested
- Opportunity for expansion with unit and integration tests

## Test Types

**Unit Tests:**
- Not currently present in codebase
- Would test: Models, Services (REST/GraphQL), Cubits, Utilities
- Could use: `test()` function from `flutter_test` (no widget building)
- Example target files:
  - `lib/models/coins.dart` - Test Coins operators and normalization
  - `lib/repository/services/rest/rest.dart` - Test API methods with mocked responses
  - `lib/utils/utils.dart` - Test utility functions

**Integration Tests:**
- Not currently present in codebase
- Would test: BLoC/Cubit workflows, multi-component interactions, navigation
- Could be added to `test/integration/` subdirectory
- Example: Test full flow from SplashScreen through SplashCubit image loading

**Widget Tests (E2E-style):**
- Currently only example: `test/widget_test.dart` - Smoke test for counter
- Tests UI interaction and state reflection
- Uses `testWidgets()` with `WidgetTester`
- Real app initialized with real dependencies

## Testing Patterns Observed

**Widget Tester Pattern:**
```dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  // Arrange
  final client = initGraphQLClient();
  
  // Act
  await tester.pumpWidget(KlimmeckGuideApp(client: client));
  
  // Assert
  expect(find.text('0'), findsOneWidget);
  
  // Act again
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  // Assert final state
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

**Key Elements:**
- Initialize real dependencies before widget building
- Use `await tester.pump()` to render frames without animations
- Chain finds with matchers (`find.text()`, `find.byIcon()`)
- Assertions follow actions (AAA pattern)

## Testing Considerations

**Current Gaps:**
- No async test helpers for GraphQL/network calls
- No test helpers for state observation
- No BLoC/Cubit testing utilities (could use `bloc_test` package)
- No mock data generators for complex models

**Best Practices for This Codebase:**

1. **Cubit Testing (recommended addition):**
   - Use `bloc_test` package: `flutter pub add dev:bloc_test`
   - Pattern: `blocTest<MyCubit, MyState>(...)`
   - Test state emissions: `expect(() => cubit.getData(), emits([...])`

2. **Model Testing:**
   - Test JSON serialization/deserialization
   - Test Equatable implementations
   - Test custom operators: `Coins + Coins`, `Coins >= Coins`

3. **Service Layer Testing:**
   - Mock HTTP clients with `mocktail` package
   - Test error handling paths
   - Verify retry logic and timeouts

4. **Widget Testing:**
   - Follow current pattern: initialize real app
   - Test user interactions: taps, scrolls, text input
   - Verify state-driven UI updates

## Coverage Targets (Recommendations)

**High Priority (for stability):**
- `lib/models/` - All model classes (high-value, low effort)
- `lib/utils/utils.dart` - Utility functions
- `lib/repository/services/` - API clients (with mocking)

**Medium Priority (for reliability):**
- `lib/screens/*/cubit/` - All Cubits (state management logic)
- `lib/repository/cache/` - Caching logic

**Lower Priority (UI-intensive):**
- Widget files under `lib/screens/` and `lib/shared/components/`
- Flutter animations (harder to test, requires widget tests)

---

*Testing analysis: 2026-04-09*
