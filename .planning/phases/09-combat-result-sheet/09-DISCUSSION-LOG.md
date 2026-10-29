# Phase 9: Combat Result Sheet - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-27
**Phase:** 9-combat-result-sheet
**Areas discussed:** Anatomia del foglio, Consegna/coda/risultati persi, Morte/soccorso/stato ferito, Push questEnd/banner/tap (plus the BE routing question and three closing questions)

---

## Framing (FE areas + BE next step)

| Option | Description | Selected |
|--------|-------------|----------|
| Anatomia del foglio | Pergamena vs schermata, sezioni per esito, animazione HP, righe extra | ✓ |
| Consegna, coda e risultati persi | Momento sicuro, ordine, più fogli, risultati persi senza snapshot | ✓ |
| Morte, soccorso e stato ferito | Hold del routing, foglio rescued, stato awaitingAid, aid in board | ✓ |
| Push questEnd, banner e tap | Registry, foreground, toggle, già visto | ✓ |

**BE next:** «Pianifica la 10 così com'è (Recommended)» selected over «Rivedi prima il CONTEXT della 10» and «Aggiungi una fase BE nuova oltre la 10». Companion BE 9.2 inserted later in the session because of the «risultati persi» answer.

---

## Anatomia del foglio

| Option | Description | Selected |
|--------|-------------|----------|
| Pergamena a tutto schermo sopra la shell | Overlay sul Navigator radice, linguaggio PaperSheetModal/QuestInfoSheet, shell viva sotto | ✓ |
| Schermata dedicata a tutto schermo | Route propria con sfondo pieno | |
| Foglio dentro il tab Mappa | Layer della mappa come il quest paper (in tensione con COMBAT-01) | |

**User's choice:** Pergamena a tutto schermo sopra la shell (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Barra di vita + numeri che contano | Barra hpBefore→hpAfter contro maxLifePoints con numeri in step | ✓ |
| Solo numeri che scorrono | Contatore animato senza barra | |
| Solo barra | Barra senza cifre | |

**User's choice:** Barra di vita + numeri che contano (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Livello e titolo prima → dopo | levelBefore/After, titleBefore/After solo quando cambiano | ✓ |
| Magia appresa e salvati | spellLearned, rescuedCharacters | ✓ |
| Nemico: immagine e nome | enemy { name imagePath } | ✓ |
| Intestazione con titolo e tipo della quest | quest { title type } + resolvedAt | ✓ |

**User's choice:** all four (multi-select).

| Option | Description | Selected |
|--------|-------------|----------|
| Stessa struttura, intestazione e inchiostro per esito | Un widget, titolo e colore per esito, sezioni vuote nascoste | ✓ |
| Fogli diversi per famiglia | Combattimento / narrativo / soccorso-morte con layout propri | |
| Nessuna distinzione oltre ai dati | Foglio neutro | |

**User's choice:** Stessa struttura, intestazione e inchiostro per esito (Recommended).

---

## Consegna, coda e risultati persi

| Option | Description | Selected |
|--------|-------------|----------|
| Navigator radice libero e nessuna gesture in corso | Nessuna route sopra la shell, nessuno strappo/drag; qualunque tab | |
| Solo dialog e fogli modali bloccano | Gesture e overlay della mappa non contano | |
| Anche una mutation in volo blocca | Attesa degli overlay ottimistici | |

**User's choice (free text, verbatim):** «Il foglio risultati si vede solo una volta entrati nel tab mappa, per sicurezza. Cliccare sul banner che ti avvisa della fine della missione ti porta sul tab mappa a e apre la sheet del risultato».
**Notes:** new rule → D-06; the two follow-up questions below were asked right after.

| Option | Description | Selected |
|--------|-------------|----------|
| In fila per resolvedAt, uno alla volta | Il tap chiude e apre il successivo | ✓ |
| Un foglio con pagine da sfogliare | PageView in una pergamena | |
| Solo l'ultimo come foglio, gli altri a banner | | |

**User's choice:** In fila per resolvedAt, uno alla volta (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Companion BE 9.2: risultati non confermati + ack | Query dei risultati non confermati + mutation di conferma; fase BE prima della 10 | ✓ |
| Companion BE light: lista storica senza ack | Lista recente, «visto» locale | |
| Nessuna companion: solo subscription + push | Posizione YAGNI del BE §14 | |

**User's choice:** Companion BE 9.2: risultati non confermati + ack (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Pulsante esplicito in fondo alla pergamena | Un solo tasto; scrim, back e swipe ignorati | ✓ |
| Tap ovunque sul foglio | | |
| Tap ovunque, anche sullo sfondo | | |

**User's choice:** Pulsante esplicito in fondo alla pergamena (Recommended).

### Follow-ups of the Map-only rule

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, subito, senza banner | Sulla Mappa il foglio si apre appena il tab è libero; i fogli in attesa si aprono entrando in Mappa | ✓ |
| No, sempre prima il banner | | |

**User's choice:** Sì, subito, senza banner (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Nessun foglio/dialog aperto e nessun drag della pedina | Quest paper, conferma viaggio, abbandono e drag rimandano il foglio | ✓ |
| Basta essere sulla Mappa | Il foglio si sovrappone a tutto | |

**User's choice:** Nessun foglio/dialog aperto e nessun drag della pedina (Recommended).

---

## Morte, soccorso e stato ferito

| Option | Description | Selected |
|--------|-------------|----------|
| La morte è l'eccezione: foglio ovunque, poi la creazione | Hold del routing finché il foglio death non è chiuso; tetto se il risultato tarda | ✓ |
| Stessa regola: banner, poi Mappa, poi foglio | Shell «zombie» finché l'utente ignora il banner | |
| Nessuna sospensione: creazione subito, foglio sopra | | |

**User's choice:** La morte è l'eccezione: foglio ovunque, poi la creazione (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Stesso foglio, inchiostro scuro e intestazione «È morto» | Stesso widget, tasto «Riposa in pace» → creazione | ✓ |
| Pergamena dedicata in stile lapide | Widget a parte, asset nuovo | |

**User's choice:** Stesso foglio, inchiostro scuro e intestazione «È morto» (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Etichetta sulla pedina + blocchi come in viaggio | «In attesa di soccorso» sopra la pedina; drag, Bacheca, Negozio disabilitati (Phase 7 D-12) | ✓ |
| Foglio della quest fallita sulla mappa con l'etichetta | Riuso del quest paper layer | |
| Solo i blocchi, nessuna etichetta | | |

**User's choice:** Etichetta sulla pedina + blocchi come in viaggio (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Stesso foglio, intestazione «Sei stato salvato» | Widget unico, aid come quest, nessun premio | ✓ |
| Solo banner «Sei stato salvato» | | |
| Foglio breve dedicato | | |

**User's choice:** Stesso foglio, intestazione «Sei stato salvato» (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Scheda combat con nemico e posti | `aid` nella famiglia combat di Phase 6 | ✓ |
| Resta scheda servizio | | |
| Rinvia a un quick task dopo la UAT | | |

**User's choice:** Scheda combat con nemico e posti (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Alla chiusura col tasto | ack quando l'utente preme il tasto; best-effort con retry | ✓ |
| Alla visualizzazione | | |
| Alla ricezione | | |

**User's choice:** Alla chiusura col tasto (Recommended).

---

## Push questEnd, banner e tap

| Option | Description | Selected |
|--------|-------------|----------|
| Notifica e banner tacciono, il foglio resta | Toggle = notifiche (Phase 4/5); il foglio è gameplay | ✓ |
| Tace solo la notifica di sistema, il banner in-app resta | Cambia la regola di Phase 5 | |
| Tace tutto, foglio compreso | | |

**User's choice:** Notifica e banner tacciono, il foglio resta (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Il FE dalla subscription, stessa chiave della push | Banner questEnd|<id> pubblicato dal FE, push foreground deduplicata | ✓ |
| Solo la push del BE | | |

**User's choice:** Il FE dalla subscription, stessa chiave della push (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Solo Mappa, nessun foglio ripetuto | Un foglio per risultato; id ignoto → questResult(id) | ✓ |
| Riapre il foglio in sola lettura | | |

**User's choice:** Solo Mappa, nessun foglio ripetuto (Recommended).

| Option | Description | Selected |
|--------|-------------|----------|
| Copia per esito dal risultato | «Vittoria: <quest>», «Sconfitta: <quest>»… | |
| Testo generico del BE | Stesso titolo e corpo della push ovunque | ✓ |

**User's choice:** Testo generico del BE (against the recommendation).

---

## Closing questions

| Option | Description | Selected |
|--------|-------------|----------|
| Nomi, campo additivo nella BE 9.2 | rescuedAdventurers { id name title } | |
| Solo il numero | «Hai salvato 2 avventurieri» | ✓ |

**User's choice:** Solo il numero (against the recommendation).

| Option | Description | Selected |
|--------|-------------|----------|
| Nella BE 9.2: la board non le mostra più | quests esclude le avviate | |
| Nella BE 9.2: campo additivo e il FE le strappa | Quest.started/startedAt + strappo FE | |
| Rinvia al backlog | | |

**User's choice (free text):** «Ma non ho capito perché dovrebbe cambiare. Avevo specificato che finché una missione non è conclusa il foglio resta strappato sulla board una volta che i posti sono pieni (e che quindi la quest è cominciata)».
**Notes:** the rule already holds; the question concerned only the seat freed after the start. Re-asked twice after the explanation (the user asked «In che senso viene eliminato un partecipante? come può accadere questa cosa?» — answered: a participant deletes the character from Settings or dies, the archive frees the seat, the started quest goes on with who remains).

| Option | Description | Selected |
|--------|-------------|----------|
| Campo additivo Quest.startedAt nella BE 9.2 + strappo FE | startedAt additivo, strappo FE a prescindere dai posti | |
| Il BE non libera i posti delle quest avviate | Segnaposto fino alla conclusione, posti pieni, k/N con posto fantasma | ✓ |
| Lascia così: caso raro | QUEST_FULL al tentativo | |

**User's choice:** Il BE non libera i posti delle quest avviate (against the recommendation) → BE Phase 9.2 scope, FE unchanged (D-18).

| Option | Description | Selected |
|--------|-------------|----------|
| Scrivi CONTEXT FE 9 + companion BE 9.2 | CONTEXT, LOG, BACKEND-NOTES, BE 9.2 inserted, feat/10-hardening restacked | ✓ |
| Esplora altre aree prima | aptica/suono, ritorno in città, copia delle ferite | |

**User's choice:** Scrivi CONTEXT FE 9 + companion BE 9.2 (Recommended).

---

## Claude's Discretion

Animation timing and skip-on-tap, the queue counter, cubit/coordinator placement and names, how «Map is free» is observed, the death hold cap, ack/refetch retry policy, provisional copy and ink colours, the Italian injury labels, haptics on open, `resolvedAt` formatting.

## Deferred Ideas

Result history page; names of the rescued adventurers; per-outcome banner copy; tombstone parchment; return-to-city flow (nothing to build); sound/haptics on open.
