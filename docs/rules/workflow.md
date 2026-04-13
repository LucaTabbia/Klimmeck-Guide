# Workflow — GSD, branch, commit, PR

## Modello GSD

Il progetto segue il workflow **GSD** (Get Shit Done). Artefatti in `.planning/`:

- `PROJECT.md` — identità e milestone
- `REQUIREMENTS.md` — requisiti per stato
- `ROADMAP.md` — fasi della milestone corrente
- `STATE.md` — stato lavori
- `phases/NN-<slug>/` — contesto, plan, verification, review per ogni fase

**Ogni fase è un'unità di lavoro chiusa** con: branch dedicato, commit atomici, PR verso `develop`.

## Branch (regola invalicabile)

### All'inizio di ogni fase

```bash
git checkout develop && git pull
git checkout -b <prefix>/<phase-slug>
```

### Prefissi (Conventional Commits)

- `feat/` — fase che introduce nuova capability. Es: `feat/auth-session-bootstrap`
- `fix/` — fase di bug-fix mirato
- `refactor/` — refactor/hardening senza feature visibili

### Slug

Lo stesso slug della directory di fase in `.planning/phases/NN-<slug>/`. Phase 1 "Auth Session Bootstrap" → `feat/auth-session-bootstrap`.

### Divieti

- **Mai push diretto su `develop` o `main`.**
- **Mai lavorare direttamente su `develop`.**
- **Mai force push su `main` o `develop`.** Force push ammesso solo sul proprio branch di fase, con cautela.

## Commit

### Conventional Commits

```
<type>(<scope>): <subject>

<body>

<footer>
```

- `type`: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`
- `scope`: area toccata (`auth`, `quest`, `travel`, `map`, `admin`, `graphql`, `ui`, `state`, `theme`)
- `subject`: imperativo, minuscolo, no punto finale, ≤ 72 char
- `body`: il **perché**, non il cosa. Opzionale per commit banali.
- Lingua: inglese.

### Atomicità

- Un commit = una modifica logica. Non mischiare refactor + feature + rename.
- `flutter analyze` deve essere pulito a ogni commit.
- Test rilevanti passano a ogni commit.

## PR

### Quando

Alla **fine della fase**: apri PR dal branch di fase verso `develop`.

### Target

- **Sempre `develop`.** Mai direttamente `main`. `main` riceve solo merge di `develop` in momenti di release.

### Contenuto PR

- Titolo: stesso stile commit (`feat(auth): implementa session bootstrap con refresh silente`).
- Descrizione:
  - Sommario in 1-3 punti.
  - Link alla fase: `.planning/phases/NN-<slug>/`.
  - Test plan (checklist cose da verificare).
- Self-review prima di chiedere review altrui: diff letto, `flutter analyze` ok, `flutter test` ok, usare skill /review.

### Review

- La PR è il punto di review. Lo streamer/dev approva o richiede cambi.
- Conflitti su `develop` → rebase del branch di fase, non merge di `develop` dentro.

## File artefatti di fase

Durante la fase, GSD genera file in `.planning/phases/NN-<slug>/`:

- `CONTEXT.md`, `PLAN.md`, `RESEARCH.md`, `VERIFICATION.md`, `REVIEW.md`, ecc.

Commit questi file **insieme** al codice della stessa fase (stesso branch). Non accumularli su `develop`.

## Secret e .env

- `.env*` **non** in repo (già nel `.gitignore` atteso).
- Credenziali Firebase/Twitch: gestione fuori VCS (keychain, CI secret).
- Se accidentalmente committati: rotate immediatamente + rimuovi da history.

## Release (milestone close)

- Merge `develop` → `main` solo a milestone chiusa (`/gsd-complete-milestone`).
- Tag semver sulla `main`: `v1.0.0`, `v1.0.1`.
- Changelog generato da commit conventional.
