# Architecture

## Pattern

**BLoC (Business Logic Component) with Cubit state management** — clean layered architecture.

## Layers

### Presentation
- `lib/screens/` contains StatefulWidgets for splash, sign-in, and main screen with 6 tabs (board, journal, library, map, shop, profile)

### Business Logic
- Cubits in `lib/screens/*/cubit/` handle state (CharacterCubit, ShopCubit, JournalCubit, etc.) with dependency-injected services

### Data/Repository
- `lib/repository/` wraps all data access including GraphQL, REST, and multi-layer caching

### Services
- `KlimmeckGraphQl` in `lib/repository/services/graphql/graphql.dart` provides unified API with query/mutation/subscription methods

### Models
- `lib/models/` contains Equatable domain entities with fromJson/toJson serialization

### Configuration
- `lib/config/env_config.dart` centralizes API URLs and timeouts
- `lib/theme/kg_theme.dart` defines design tokens

## Data Flow

User interactions -> Screens call Cubits -> Cubits emit states via services -> UI rebuilds via BlocBuilder/BlocListener.

Real-time updates via GraphQL subscriptions in CharacterCubit stream.

## Entry Points

- `lib/main.dart` — App entry, MultiBlocProvider setup
- `lib/screens/splash/splash_screen.dart` — Initial screen
- `lib/screens/mainScreen/main_screen.dart` — Main app shell with tab navigation

## Caching Strategy

Three-tier caching:
1. In-memory `SvgCache`
2. Disk `SvgCacheManager`
3. Network (Cloudinary)

GraphQL uses noCache policy for fresh data.

## Key Abstractions

- **Cubits** — State containers per feature (CharacterCubit, ShopCubit, JournalCubit)
- **KlimmeckGraphQl** — Unified GraphQL client wrapper
- **KlimmeckRest** — REST API client
- **Repository layer** — Abstracts data source details from business logic
