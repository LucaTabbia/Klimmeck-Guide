/// Limiti del BE Phase 22 per il flusso guidato (vedi il BACKEND-NOTES della BE Phase 22, ruling 2026-11-14): l'app li usa come limiti di UI, il BE resta giudice.
const int maxMissionFights = 10;
const int maxEnemyEntriesPerFight = 10;
const int minEnemyQuantity = 1;
const int maxEnemyQuantity = 20;

/// Quantità per voce di oggetto in premio (D-15, limite tecnico).
const int minPrizeItemQuantity = 1;
const int maxPrizeItemQuantity = 99;

/// Vita minima dopo uno scontro: la missione finisce sempre completata (D-05).
const int minLifeAfterFight = 1;

/// Cifre di monete (per taglio) e PE di un premio: tetto tecnico del BE
/// 9 999 999 (protezione del portafoglio, non un tetto di prodotto, D-15).
const int maxPrizeAmountDigits = 7;
