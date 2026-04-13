# Asset & caching

## Sorgenti asset

- **Locali (`assets/`)**: icone UI statiche, splash, logo, sfondo mappa, font. Dichiarati in `pubspec.yaml`.
- **Remoti (Cloudinary)**: equipaggiamento, ferite, quest pawn, lore art. URL centralizzati in `lib/config/cloudinary_assets.dart`.

**Regola:** asset di dominio che variano con il catalogo di gioco → Cloudinary. Asset UI fissi → locali.

## Naming file

- **`snake_case`** sempre.
- Prefisso per dominio: `quest_pawn_<id>.svg`, `injury_<id>.svg`, `equipment_<slot>_<id>.svg`.
- SVG preferito per grafica vettoriale di gioco; PNG solo per texture/fotografico.

## Dichiarazione in pubspec

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/svg/
```

Preferire dichiarazione di **directory** a singoli file quando possibile.

## SVG caching (regola chiave)

Il progetto ha un sistema multi-livello in `lib/repository/cache/`:

1. **Memory cache** — `svg_cache.dart` (hot path, istantaneo)
2. **Disk cache** — `svg_cache_manager.dart` via `flutter_cache_manager` (persistente tra sessioni)
3. **Network** — Cloudinary (ultimo fallback)

**Widget di consumo:** `CachedSvg` in `lib/shared/components/cached_svg.dart`. **Usare sempre questo widget** per SVG di dominio. Mai `SvgPicture.network` direttamente.

## Scadenza cache

- `cache_expiry.dart` definisce TTL per categoria. Modificare qui, non sparpagliare costanti.
- Invalidazione manuale: esposta da `SvgCacheManager`. Chiamare dopo aggiornamenti di catalogo (admin modifica equipment SVG).

## Immagini Cloudinary

- URL costruiti tramite helper in `cloudinary_assets.dart`. Mai concatenare stringhe raw nei widget.
- Parametri Cloudinary (size, quality, format) applicati a monte: widget consuma URL finale.
- Per raster remote usare `cached_network_image` (già in dipendenze).

## Icone

- Set primario: `cupertino_icons` (già in pubspec). Preferire icone native iOS-like per coerenza estetica.
- Icone custom del progetto: SVG in `assets/icons/`, consumate via `CachedSvg` locale o `SvgPicture.asset`.

## Font

Dichiarati in `pubspec.yaml > flutter > fonts`. Aggiunti al tema in `lib/theme/`. **Mai** riferimenti a `fontFamily: 'XYZ'` inline nei widget.

## Dimensioni e ottimizzazione

- SVG: ottimizzati (svgo) prima di commit. No metadata editor, no gruppi inutili.
- PNG: compressi (pngquant / squoosh). Dimensione intrinseca ragionevole; evitare 4K se il target è 200px logici.
- Un asset > 500 KB va giustificato.

## Anti-pattern

- `Image.network('https://res.cloudinary.com/...')` sparso nei widget → vietato.
- Asset di gioco (equipment, injury) locali nel bundle → vietato, sono dinamici lato server.
- TTL cache inline in un widget → deve stare in `cache_expiry.dart`.
- Nuova variante SVG salvata come `injury_bleeding_2_final_FINAL.svg` → rispetta naming semantico.
