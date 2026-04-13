# Klimmeck-Guide — Istruzioni operative per Claude

## Cos'è

App mobile **Flutter** che trasforma i punti canale Twitch in un RPG persistente. I viewer spendono punti canale (1:1) come valuta di gioco, accettano quest, viaggiano, combattono (logica server-side). Backend **NestJS + MongoDB** via GraphQL (HTTP + WS) e REST. Single-channel, streamer = game master.

## Stack

- **Mobile:** Flutter (Dart), BLoC/Cubit (`flutter_bloc`), `equatable`
- **Network:** `graphql_flutter` (query/mutation/subscription), `dio` (REST)
- **Auth/Push:** Firebase Auth (OAuth Twitch), Firebase Messaging (FCM/APNs)
- **Mappa:** `flutter_map` + `latlong2`
- **Storage:** `shared_preferences`, `flutter_cache_manager`
- **Backend (non in questo repo):** NestJS + MongoDB

## Stato progetto e pianificazione (fonte di verità)

Prima di qualsiasi lavoro non triviale, leggere:

- `.planning/PROJECT.md` — identità, milestone corrente, requirements, key decisions
- `.planning/REQUIREMENTS.md` — requisiti validati/attivi/out-of-scope
- `.planning/ROADMAP.md` — fasi v1.0 Core Loop e dipendenze
- `.planning/STATE.md` — stato corrente lavori GSD
- `.planning/phases/NN-<slug>/` — contesto, plan, verification della fase attiva

## Rule files (leggere solo quelli rilevanti al task)

| File                                                             | Quando leggerlo                                                       |
| ---------------------------------------------------------------- | --------------------------------------------------------------------- |
| [docs/rules/naming.md](docs/rules/naming.md)                     | Prima di creare file, classi, variabili, widget, eventi BLoC          |
| [docs/rules/architecture.md](docs/rules/architecture.md)         | Prima di decidere dove posizionare codice nuovo (layer, cartelle)     |
| [docs/rules/state-management.md](docs/rules/state-management.md) | Prima di creare/modificare BLoC, Cubit, State, Event                  |
| [docs/rules/graphql.md](docs/rules/graphql.md)                   | Prima di toccare query/mutation/subscription o service GraphQL/REST   |
| [docs/rules/ui-ux.md](docs/rules/ui-ux.md)                       | Prima di costruire/modificare schermate, widget, loading, navigazione |
| [docs/rules/testing.md](docs/rules/testing.md)                   | Prima di scrivere test widget, bloc_test, integration                 |
| [docs/rules/workflow.md](docs/rules/workflow.md)                 | Inizio/fine fase GSD, commit, branch, PR                              |
| [docs/rules/assets.md](docs/rules/assets.md)                     | Prima di aggiungere SVG/immagini, toccare caching o Cloudinary        |

## Principi trasversali (sempre applicati)

- **Clean Code.** Nomi parlanti, funzioni piccole a singolo scopo, zero duplicazione, niente commenti che spiegano "cosa" (lo dice il codice). Early return, niente nesting profondo, niente flag booleani che cambiano comportamento.
- **Separation of Concerns (SoC).** Una responsabilità per modulo/classe/funzione. UI non fa networking, Cubit non costruisce widget, Repository non conosce `BuildContext`, Model non dipende da Flutter. Layer in `docs/rules/architecture.md`.
- **TDD (Test-Driven Development).** Red → Green → Refactor. Nessuna feature o bugfix senza test scritto **prima** dell'implementazione. Dettagli in `docs/rules/testing.md`.
- **Boy Scout Rule.** Lascia il codice più pulito di come l'hai trovato. Se tocchi un file e vedi nome scadente, micro-duplicazione, import morto, magic number → sistema nello stesso commit (se resta in scope). Refactor massivi fuori scope → PR separata.

## Regole invalicabili (mai derogare)

1. **No UI chrome fuori utility screens.** Gameplay immersivo. AppBar, bottom nav, bordi "app-style" solo in: login, creazione personaggio, settings, admin panel.
2. **No loading bloccanti in sessione attiva.** Refresh token, validazione, riconnessione WS devono essere invisibili. Spinner/skeleton ammessi solo al cold start o su azione esplicita dell'utente.
3. **Branch + PR per ogni fase GSD.** Mai push diretto su `develop` o `main`. Branch off `develop` con prefisso `feat/`, `fix/`, `refactor/` + slug fase. PR target = `develop`. Dettagli: [docs/rules/workflow.md](docs/rules/workflow.md).
4. **Il backend è fonte di verità.** Progressione, combattimento, HP, slot magie, apprendimento magie: logica server-side. Frontend è reattivo, non calcola né duplica.
5. **Nessun secret in repo.** `.env`, token, credenziali Firebase/Twitch restano fuori dal VCS.

## Comandi essenziali

```bash
flutter pub get           # dopo pull o modifiche a pubspec.yaml
flutter analyze           # lint (flutter_lints) — deve essere pulito prima di PR
flutter test              # test unit/widget/bloc
flutter run               # dev run (device selezionato)
dart format lib test      # formattazione prima di commit
```

## Quando dubiti

- Domanda di contesto → `.planning/PROJECT.md`
- Domanda "dove va questo file?" → `docs/rules/architecture.md`
- Domanda "come si chiama?" → `docs/rules/naming.md`
- Domanda su workflow/commit → `docs/rules/workflow.md`

---

_Le istruzioni in questo file e nei rule file in `docs/rules/` prevalgono sui default comportamentali. Se una regola è ambigua o sembra obsoleta, chiedere invece di assumere._
