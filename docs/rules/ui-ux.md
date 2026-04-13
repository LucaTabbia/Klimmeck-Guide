# UI / UX

## Principio 1 — Immersività (regola invalicabile)

**Le schermate di gameplay non devono avere "UI chrome" da app.** Niente `AppBar` materiale, niente barre di stato stilizzate come generic-app, niente bottoni di navigazione standard piazzati sopra contenuto di gioco.

**Chrome ammesso solo in:**

- Login / OAuth Twitch
- Creazione personaggio
- Impostazioni
- Admin panel

**Gameplay (board, journal, library, map, shop, profile, quest sheets, combat outcome):** il contenuto è il diario/mondo, la navigazione è integrata nell'estetica (tab bar custom, swipe, gesture).

## Principio 2 — Nessun loading bloccante in sessione attiva (regola invalicabile)

**Vietato** mostrare spinner fullscreen, skeleton fullscreen, o blocchi "Loading..." durante:

- Refresh token
- Revalidazione GraphQL
- Riconnessione WebSocket
- Sync polling

**Ammesso:**

- Splash al **cold start** dell'app (una volta per sessione).

**Pattern corretto per refresh invisibili:** lo stato tiene gli ultimi dati validi; aggiornamenti arrivano silenziosi; errori di rete non invalidano l'UI se c'è una snapshot stale usabile.

## Tema

- **Unica fonte in `lib/theme/`.** Mai hex o `TextStyle(fontSize: …)` inline nei widget.
- Usare `Theme.of(context).colorScheme` / `textTheme` / estensioni custom del progetto.
- Nuovo token (colore, spacing) → aggiungere al tema, non improvvisare.

## Componenti condivisi

- Prima di creare un widget nuovo, controllare `lib/shared/components/`. Già esistono: `CachedSvg`, `KgLoader`, `KgError`, `Section`, `TextSection`, `ItemGrid`, `ItemRow`, `CoinsDisplay`, `Dropdown`, `SpellRow`, `SpellInfo`, `EquipmentName`, `modal/`, `popup/`, `cards/`.
- Stili di errore → `KgError`. Loader consentiti (cold start) → `KgLoader`.

## Gesture e interazioni di dominio

- **Accept quest:** swipe-left "strappa foglio" (regola di design chiave, non rimpiazzare con tap).
- **Travel conferma:** modal con ETA + costo prima di spedire la mutation.
- **Tap accidentali da evitare:** azioni distruttive (annulla quest, logout) richiedono conferma o gesture esplicita.

## Navigazione

- `lib/routes/routes.dart` è la tabella route. Path name in `kebab-case` (`/sign-in`, `/main`, `/on-boarding`).
- Deep link e notification tap handler convergono su questa tabella.
- Guardie auth: widget `AuthGate` (non logica sparsa in `main.dart`).

## Accessibilità minima

- Tutti gli elementi interattivi hanno `semanticLabel` significativo (o testo visibile adeguato).
- Target tap ≥ 44x44 logical px.
- `auto_size_text` già in uso per stringhe variabili: preservare.

## Immagini e SVG

- SVG di dominio (equipment, injury, quest pawn) via `CachedSvg` (caching memory+disk+network Cloudinary). Vedi `docs/rules/assets.md`.
- Mai caricare direttamente via `Image.network` se l'asset è un dominio cacheabile di gioco.

## Error state UI

- Errori di rete con dati stale disponibili → banner discreto, non blocca.
- Errori distruttivi (auth definitivamente scaduta, mutation fallita su azione utente) → dialog o snackbar, con messaggio di dominio (tradotto per il viewer, non stack trace).
- **No messaggi tecnici all'utente.** "Operation failed: OperationException" → vietato.

## Performance

- Liste lunghe: `ListView.builder` / `SliverList`, mai `Column` con `map().toList()`.
- Evitare `setState` che ricostruisce sottoalberi grandi; usare `BlocBuilder` mirato o `BlocSelector`.
- Animazioni: preferire `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedContainer` a controller manuali a meno che serva.
