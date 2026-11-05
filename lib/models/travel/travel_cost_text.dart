import '../quantity_line.dart';
import 'travel_food_item.dart';
import 'travel_preview.dart';

/// Frase dell'utente per la fame (15-CONTEXT D-06): riga «Vita» rossa, riga
/// «Viaggio» rossa e corpo dei due banner.
const String starvingPhrase = 'Non hai cibo a sufficienza per il viaggio';

/// Copy provvisoria (D-02, Claude's discretion).
const String noLifeLostText = 'nessuna perdita';

/// Cibo nell'ordine del BE, «Nx nome» separati da virgola; [empty] quando il
/// BE non mangia nulla (D-02, D-04). Nessun calcolo: solo stampa (FOOD-04).
String foodText(List<TravelFoodItem> food, {required String empty}) =>
    food.isEmpty
    ? empty
    : food.map((entry) => quantityLine(entry.quantity, entry.name)).join(', ');

/// Vita persa sui km scoperti: la frase dell'utente quando il BE dice che il
/// personaggio non arriverebbe vivo (D-10: niente numero), altrimenti
/// «−N HP» (U+2212, D-11) o «nessuna perdita».
String lifeText(TravelPreview preview) {
  if (!preview.arrivesAlive) return starvingPhrase;
  if (preview.hpLost <= 0) return noLifeLostText;
  return '−${preview.hpLost} HP';
}
