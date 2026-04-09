# Structure

## Directory Layout

```
lib/
├── main.dart                    # App entry, MultiBlocProvider setup
├── config/                      # EnvConfig (API URLs, timeouts), theme setup
├── models/                      # Equatable domain entities (Character, Equipment, Quest, etc.)
├── graphql/                     # Query/mutation/subscription string definitions
├── repository/                  # Services (KlimmeckGraphQl, KlimmeckRest), caching, storage
├── screens/                     # Features: splash, signIn, onBoarding, mainScreen (with tabs)
│   └── mainScreen/tabs/         # Board, Journal, Library, Map, Shop, Profile
├── shared/components/           # Reusable widgets (CachedSvg, cards, modals, loaders)
├── routes/                      # Navigation transitions (createSlideRoute, createFadeRoute)
├── theme/                       # Design tokens (KlimmeckGuideTheme)
└── utils/                       # Helpers (notification, utilities)
```

## Key Locations

- **Entry:** `lib/main.dart` -> `lib/screens/splash/splash_screen.dart` -> `lib/screens/mainScreen/main_screen.dart`
- **API wrapper:** `lib/repository/services/graphql/graphql.dart`
- **State management:** `lib/screens/*/cubit/*.dart` (CharacterCubit at `lib/screens/mainScreen/characterCubit/character_cubit.dart`)
- **Shared components:** `lib/shared/components/cached_svg.dart`, `kg_loader.dart`, `kg_error.dart`

## Naming Conventions

- **Files:** `snake_case.dart`
- **Classes:** `PascalCase` (Cubits: `<Feature>Cubit`, States: `<Feature><Type>`)
- **Functions:** `camelCase`, private with `_`
- **Constants:** `UPPER_SNAKE_CASE`

## Adding New Code

### New tab feature
Create `lib/screens/mainScreen/tabs/<feature>/` with:
- Screen widget
- `cubit/` subdirectory
- `components/`
- Register Cubit in `main.dart`

### Shared widget
Add to `lib/shared/components/<widget>.dart` (no business logic)

### GraphQL query
Add to `lib/graphql/queries/<entity>_queries.dart`
