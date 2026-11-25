# Phase 26: Potion Pour Gesture — Context

**Gathered:** 2026-11-25 (conversazione con l'utente, fase GSD snella: niente ricerca né UI-SPEC, design iterativo sul device con hot reload)
**Status:** Ready for planning
**BE companion:** nessuna. Mutation `useItem`, `PotionCubit.drink/give`, `PotionRecoveryCubit` e `companionPotionTargetsOf` restano come sono.

## Phase Boundary

Il foglio di conferma della pozione (`PotionSheet` in un `showModalBottomSheet`) è sostituito da una scena a gesti: la boccetta si trascina verso sinistra, si inclina e versa il contenuto in chi deve bere. Solo presentazione: nessuna regola di gioco nuova nel client, il backend resta giudice.

## Decisions

- **D-01** La scena sostituisce la modale per le pozioni heal bevibili dal Diario (stesse condizioni di oggi in `ItemsSection._potionAwareRow`: missione in corso, attesa di soccorso e ricarica senza compagni restano righe non toccabili).
- **D-02** Nessun pulsante, nessuna parola toccabile: tutto è contestuale e gestuale (regola dell'utente).
- **D-03** Una sola boccetta per tutte le pozioni (disegno Gemini dell'utente, `Gemini_Generated_Image_rcjby5rcjby5rcjb.jpeg`), il nome della pozione scritto sull'etichetta di pergamena; il colore del liquido viene da una **tabella fissa per rarità** (scelta dell'utente). Asset UI fisso → bundle locale (`docs/rules/assets.md`).
- **D-04** La boccetta è a livelli: vetro, liquido disegnato in codice (ritagliato sulla sagoma interna, fusione multiply sul vetro), etichetta sopra il liquido, tappo separato.
- **D-05** Il liquido obbedisce alla gravità: pelo sempre orizzontale rispetto allo schermo, volume conservato, onda leggera, sciabordio a molla smorzata quando cambia l'inclinazione; quando il pelo supera il bordo del collo esce un getto che cade e il volume cala.
- **D-06** Gesto: la boccetta sta **al centro**; trascinata segue il dito e si inclina verso il lato in cui va, in proporzione alla distanza (verso destra → il personaggio, verso sinistra → il compagno a schermo). Rilasciata prima che esca la prima goccia torna dritta e non si consuma nulla.
- **D-07** Punto di non ritorno = la prima goccia oltre il bordo del collo: parte `drink` (personaggio) o `give` (compagno), la boccetta si svuota fino in fondo e svanisce. Un rifiuto del backend chiude la scena e il motivo resta al banner di `PotionOutcomeListener`, come oggi.
- **D-08** Bevitori: il personaggio se non è in ricarica, più i compagni di `companionPotionTargetsOf`. **Chi non può bere non compare** (scelta dell'utente).
- **D-09** Disposizione (utente, 2026-11-25, rivede la prima idea «tutti a sinistra»): **personaggio fisso a destra**, che spunta dal bordo destro; **compagni a sinistra**, uno alla volta, che spuntano dal bordo sinistro il più grandi possibile e **scorrono** in verticale per cambiare compagno. Personaggio in ricarica = lato destro vuoto; nessun compagno idoneo = lato sinistro vuoto.
- **D-10** Figure: il compagno con il suo asset (immagine del pet, scontornata); il personaggio **non** con il suo ritratto (forma qualunque, di solito non scontornato) ma con l'SVG della razza e del sesso su Cloudinary `main/races/<razza>_<male|female>.svg`. Finché la PR #58 (rename razze) non entra, `tiefling` → `infernal` e `aarakocra` → `volucri`.
- **D-11** Uscita: tocco fuori dalla boccetta o gesto indietro (bloccati mentre la pozione è in volo). Tocco prolungato sulla boccetta = dettagli (cosa cura, ricarica).
- **D-12** Esito in-world dopo il versamento (vita, ferite guarite, lore sbloccata): resa da decidere sul device.
- **D-13** Il disegno cambierà strada facendo (utente: «la modificheremo strada facendo»): ritocchi sul device con hot reload, un commit per ritocco; errori veri di layout e logica in TDD.

## Canonical refs

- `lib/screens/mainScreen/tabs/journal/sections/items_section.dart` — apertura della modale (`_confirmDrink`)
- `lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart` — foglio attuale (conferma, «Dai a …», esito)
- `lib/models/companion/companion_potion_target.dart` — chi può bere
- `lib/config/cloudinary_assets.dart`, `lib/config/env_config.dart` — URL Cloudinary
- `lib/models/enums/race_type.dart`, `lib/models/enums/sex_type.dart`, `lib/models/enums/rarity_type.dart`
