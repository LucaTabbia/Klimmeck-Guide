# Architettura & posizionamento codice

## Layer (top-down)

```
UI (screens, shared/components)
   ↓ ascolta stati, emette eventi
BLoC / Cubit (lib/screens/<feature>/<feature>Cubit o /bloc)
   ↓ chiama metodi
Repository (lib/repository/*)
   ↓ usa
Service (lib/repository/services/graphql|rest, cache, storage)
```

**Regola di flusso:** la UI non chiama mai direttamente i Service. Passa sempre per un BLoC/Cubit → Repository. Un Repository può orchestrare più Service (GraphQL + cache + storage).

## Dove va cosa

### `lib/config/`
Costanti di ambiente, URL Cloudinary base, feature flag statici. **No logica.**

### `lib/graphql/`
Documenti GraphQL puri (stringhe). Sottocartelle: `queries/`, `mutations/`, `subscriptions/`, `fragments/`. Nessun `import 'package:flutter/…'` qui.

### `lib/models/`
POJO di dominio con `fromJson`/`toJson`, `Equatable`. Subdir per aggregati: `character/`, `quest/`, `request/`, `enums/`. **No dipendenze da Flutter.** Un modello è serializzabile e testabile senza widget tree.

### `lib/repository/`
- `services/graphql/` — client GraphQL + provider
- `services/rest/` — client Dio per REST
- `cache/` — caching (es. SVG memory+disk)
- `storage/` — persistenza locale (`shared_preferences`, secure storage)
- Classi `XxxRepository` esposte all'app (la UI via BLoC inietta il repository).

### `lib/routes/`
Solo `routes.dart`: mapping path → `WidgetBuilder`. Niente logica di guardia complessa qui (quella va in un `AuthGate` widget).

### `lib/screens/<feature>/`
Una cartella per feature principale. Struttura interna tipica:

```
screens/mainScreen/
├── main_screen.dart           # entry widget
├── cubit/                     # cubit principale della feature
│   ├── main_screen_cubit.dart
│   └── main_screen_state.dart
├── characterCubit/            # sub-cubit per aggregato specifico
├── questCubit/
├── components/                # widget interni alla feature
└── tabs/                      # sezioni navigabili della feature
```

Widget riusato in ≥2 feature → promuovere a `lib/shared/components/`.

### `lib/shared/components/`
Widget generici riusabili: `cached_svg.dart`, `kg_loader.dart`, `kg_error.dart`, `section.dart`, `modal/`, `popup/`, `cards/`. Prefisso `Kg` per componenti marcati come "design system" del progetto.

### `lib/theme/`
Colori, tipografia, shape, spacing. **Unica fonte di verità** per stili. Nessun color hex o `TextStyle` inline nei widget.

### `lib/utils/`
Funzioni pure, helper stateless, extension. No I/O, no dipendenze da BLoC/repository.

### `test/`
Mirror della struttura `lib/`. Vedi `docs/rules/testing.md`.

## Regole di dipendenza

- **UI → BLoC → Repository → Service** (mai salti, mai inversioni).
- **Models non dipende da nessuno** (solo package di serializzazione/equatable).
- **Graphql (documenti) non dipende da nessuno.**
- **Theme non dipende da feature** (feature dipende da theme).
- Import circolari vietati. Se servono, il design è sbagliato.

## Decisioni architetturali ricorrenti

- **Nuovo dominio dati?** → modello in `models/<dominio>/`, query in `graphql/queries/<dominio>_queries.dart`, repository in `repository/<dominio>_repository.dart`, cubit nella feature che lo consuma.
- **Widget "dove va?"** → usato in 1 feature: `screens/<feature>/components/`. Usato in ≥2: `shared/components/`.
- **Stato globale necessario?** → cubit registrato in alto nell'albero (vicino a `MaterialApp`), esposto via `BlocProvider`. Vedi `docs/rules/state-management.md`.
