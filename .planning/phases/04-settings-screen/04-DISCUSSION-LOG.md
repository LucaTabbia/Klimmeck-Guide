# Phase 4: Settings Screen - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-14 / 2026-10-15
**Phase:** 04-settings-screen
**Areas discussed:** Punto d'ingresso nel menù, Struttura della schermata, Toggle notifiche, Cancellazione personaggio

---

## Punto d'ingresso nel menù

| Option | Description | Selected |
|--------|-------------|----------|
| Voce nell'overlay del menù | Etichetta testuale 'Impostazioni' nell'overlay aperto della borsa, nessun nuovo asset | |
| Settima voce nella borsa | Nuova icona SVG che vola come le altre 6; asset Cloudinary + revisione griglia | ✓ |
| Pulsante nel tab Profilo | Azione dentro la scheda Profilo | |

**User's choice:** Settima voce nella borsa.
**Notes:** "Lo slot della mappa prende le dimensioni di una casella in larghezza e due in altezza. Bisogna creare un nuovo asset da aggiungere a Cloudinary, lo farò separatamente."

| Option | Description | Selected |
|--------|-------------|----------|
| Testo in Cinzel come le etichette | Stesso stile di Mappa/Profilo (titleMedium, paleSilver, ombre) | ✓ |
| SVG a tema da Cloudinary | Icona disegnata per l'overlay | |
| Icona Material (Icons.settings) | Chrome da app in superficie di gioco | |

**User's choice:** Testo in Cinzel per l'etichetta dell'overlay.

| Option | Description | Selected |
|--------|-------------|----------|
| No, solo dal menù di gioco | La creazione mantiene la sola azione 'Esci' | ✓ |
| Sì, anche dalla creazione | AppBar della creazione con accesso a Impostazioni | |

**User's choice:** Solo dal menù di gioco.

| Option | Description | Selected |
|--------|-------------|----------|
| Impostazioni in basso a destra | Riga 1: Profilo, Diario, Libreria. Riga 2: Bacheca, Negozio, Impostazioni | ✓ |
| Impostazioni in alto a destra | Riga 1: Profilo, Diario, Impostazioni. Riga 2: Libreria, Bacheca, Negozio | |
| Decidi tu | Claude sceglie l'ordine | |

**User's choice:** Impostazioni in basso a destra.

| Option | Description | Selected |
|--------|-------------|----------|
| SVG esistente temporaneo | Asset già presente dietro `CloudinaryAssets.settings`, si cambia solo il path | ✓ |
| Slot vuoto ma cliccabile | Box vuoto finché l'asset manca | |
| Aspetto l'asset prima di implementare | Fase bloccata fino all'upload | |

**User's choice:** SVG esistente temporaneo.

---

## Struttura della schermata

| Option | Description | Selected |
|--------|-------------|----------|
| Route a schermo intero sul Navigator radice | Scaffold + AppBar con back, come SignIn/creazione | |
| Settima pagina del PageView | Tab come Mappa/Profilo; borsa e overlay restano sopra | ✓ |

**User's choice:** Settima pagina del PageView.

| Option | Description | Selected |
|--------|-------------|----------|
| Scheda su pergamena | Sfondo parchment, titoli Cinzel, righe a sezioni, switch tematizzati | ✓ |
| Material pulito | ListView con SwitchListTile/ListTile standard | |
| Decidi tu | Claude dentro i token di kg_theme.dart | |

**User's choice:** Scheda su pergamena.

| Option | Description | Selected |
|--------|-------------|----------|
| Intestazione con nome personaggio | Riga 'Personaggio: <nome>' dal CharacterCubit | ✓ |
| Solo sezioni Notifiche e Account | Nessuna intestazione | |
| Decidi tu | Claude decide con i dati in sessione | |

**User's choice:** Intestazione con nome personaggio.

| Option | Description | Selected |
|--------|-------------|----------|
| Solo 'Esci' | Riusa confirmLogout; cambio account via nuovo login | ✓ |
| 'Esci' e 'Cambia account' | Secondo pulsante logout + login immediato (Phase 11 D-14) | |

**User's choice:** Solo 'Esci'.

| Option | Description | Selected |
|--------|-------------|----------|
| Titolo 'Impostazioni' dentro la scheda | Come Profilo: foglio parchment, titolo Cinzel, nessuna AppBar | ✓ |
| AppBar in cima al tab | Chrome esplicito dentro la pagina del PageView | |
| Decidi tu | Claude sceglie | |

**User's choice:** Titolo dentro la scheda.

| Option | Description | Selected |
|--------|-------------|----------|
| In fondo al foglio, sezione Account, rosso | ElevatedButton bloodRed, ultimo elemento scrollabile | ✓ |
| In alto a destra nel foglio | Azione testuale 'Esci' in cima | |
| Decidi tu | Claude posiziona con conferma | |

**User's choice:** In fondo al foglio, sezione Account, rosso.

---

## Toggle notifiche

| Option | Description | Selected |
|--------|-------------|----------|
| Tutti attivi | Il viewer riceve tutto finché non spegne una categoria | ✓ |
| Tutti disattivi | Opt-in esplicito per categoria | |

**User's choice:** Tutti attivi.

| Option | Description | Selected |
|--------|-------------|----------|
| Solo locali, shared_preferences | Phase 5 filtra sul device; il BE non sa nulla | ✓ |
| Sincronizzate col backend | Nuova mutation + campo su User; soppressione server-side | |
| Locali ora, sync BE in futuro | Store dietro interfaccia, domanda aperta in BACKEND-NOTES | |

**User's choice:** Solo locali, shared_preferences.

| Option | Description | Selected |
|--------|-------------|----------|
| Per utente sul device | Chiave con user.id; il logout non le cancella | ✓ |
| Per device, condivise | Una sola terna di toggle | |
| Per utente, azzerate al logout | Default ripristinati al teardown | |

**User's choice:** Per utente sul device.

| Option | Description | Selected |
|--------|-------------|----------|
| Niente in Phase 4 | Permesso e avvisi sono di Phase 5 (NOTIF-02) | ✓ |
| Nota + link alle impostazioni di sistema | Riga 'Notifiche disattivate dal sistema' con apertura OS | |

**User's choice:** Niente in Phase 4.

| Option | Description | Selected |
|--------|-------------|----------|
| Subito al tap, senza pulsante Salva | Scrittura immediata; su errore lo switch torna indietro | ✓ |
| Con pulsante 'Salva' esplicito | Toggle come bozza fino alla conferma | |

**User's choice:** Subito al tap.

---

## Cancellazione personaggio

| Option | Description | Selected |
|--------|-------------|----------|
| Rinviata: Settings nasce senza | SET-01..04 non la coprono; il BE non ha la mutation; idea differita | |
| In scope ora, con lavoro BE | Voce 'Elimina personaggio' + mutation deleteCharacter proposta; fase BE prima della PR FE | ✓ |

**User's choice:** In scope ora, con lavoro BE.
**Notes:** Nuovo requisito SET-05 aggiunto a REQUIREMENTS/ROADMAP; fase BE 03.1 inserita.

| Option | Description | Selected |
|--------|-------------|----------|
| Dialog con nome da digitare | 'Elimina' abilitato solo se il nome coincide | |
| Dialog semplice a due pulsanti | Come il logout: Annulla / Elimina | ✓ |
| Decidi tu | Claude sceglie con conferma esplicita | |

**User's choice:** Dialog semplice a due pulsanti.

| Option | Description | Selected |
|--------|-------------|----------|
| Adotta lo User restituito | deleteCharacter: User! → adoptUser; userUpdated resta il backup | ✓ |
| Aspetta l'evento userUpdated | La mutation ritorna solo un esito | |

**User's choice:** Adotta lo User restituito.

| Option | Description | Selected |
|--------|-------------|----------|
| Archiviato (soft delete) | Resta nel DB marcato come eliminato e scollegato dallo User | ✓ |
| Cancellato fisicamente | Documento rimosso | |
| Decide il BE | Domanda aperta | |

**User's choice:** Archiviato (soft delete).

| Option | Description | Selected |
|--------|-------------|----------|
| Fase decimale companion (es. BE 3.1) | Fase piccola e mirata, PR BE prima della PR FE | ✓ |
| Dentro la Phase 4 BE (Atomics) | Aggiunta alla fase economica | |
| Decidi tu | Claude propone, il BE sceglie | |

**User's choice:** Fase decimale companion BE 03.1.

---

## Claude's Discretion

- Nomi e cartelle della feature Settings, store delle preferenze (formato chiavi, API per Phase 5), placeholder temporaneo dell'icona, generalizzazione della geometria del menù, copy e spacing delle sezioni, posizione dei provider dei nuovi Cubit, layout dei test.
- Regole BE su viaggio/quest attivi al momento della cancellazione (domanda aperta in BACKEND-NOTES).

## Deferred Ideas

- Pulsante "Cambia account"; nota/link al permesso OS (Phase 5); sync delle preferenze col BE; conferma con nome digitato; avviso post-cancellazione sulla pagina di creazione.
