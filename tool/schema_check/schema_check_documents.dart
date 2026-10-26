import 'package:klimmeck_guide/graphql/mutations/auth_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/push_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/quest_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/travel_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/auth_queries.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/equipment_item_queries.dart';
import 'package:klimmeck_guide/graphql/queries/loot_item_queries.dart';
import 'package:klimmeck_guide/graphql/queries/lore_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';
import 'package:klimmeck_guide/graphql/queries/server_time_queries.dart';
import 'package:klimmeck_guide/graphql/queries/travel_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';
import 'package:klimmeck_guide/graphql/subscriptions/user_subscriptions.dart';

/// Ogni operazione GraphQL nominata dell'app, per nome operazione.
///
/// Validata contro `src/schema.gql` del backend da `validate_documents.js`.
/// La Phase 5 aggiunge `RegisterPushDevice` e `UnregisterPushDevice`; la
/// Phase 7 aggiunge `GetServerTime`, `GetTravelPreview` e `StartTravel`; ogni
/// documento futuro va aggiunto qui
/// (il test `schema_check_documents_test.dart` lo impone).
final Map<String, String> schemaCheckDocuments = {
  'cities': CityQueries.getAllCities,
  'GetCity': CityQueries.getCity,
  'GetTravelPreview': TravelQueries.getTravelPreview,
  'lootItems': LootItemQueries.getAllLootItems,
  'lootAssetsQuantity': LootItemQueries.getAllLootAssetsQuantity,
  'lootItemsByIds': LootItemQueries.getLootItemsByIds,
  'GetMe': AuthQueries.getMe,
  'GetServerTime': ServerTimeQueries.getServerTime,
  'GetRaceTraits': CharacterQueries.getRaceTraits,
  'character': CharacterQueries.getCharacter,
  'equipment': CharacterQueries.getEquipment,
  'equipmentItems': EquipmentItemQueries.getAllEquipmentItems,
  'equipmentAssetsQuantity': EquipmentItemQueries.getAllEquipmentAssetsQuantity,
  'equipmentItemsByIds': EquipmentItemQueries.getEquipmentItemsByIds,
  'quests': QuestQueries.getAllQuests,
  'lores': LoreQueries.getAllLores,
  'lore': LoreQueries.getLoreById,
  'CreateCharacter': CharacterMutations.createCharacter,
  'DeleteCharacter': CharacterMutations.deleteCharacter,
  'doTransaction': CharacterMutations.doTransaction,
  'equipItem': CharacterMutations.equipItem,
  'equipSpell': CharacterMutations.equipSpell,
  'unequipSpell': CharacterMutations.unequipSpell,
  'AcceptQuest': QuestMutations.acceptQuest,
  'StartTravel': TravelMutations.startTravel,
  'RegisterPushDevice': PushMutations.registerPushDevice,
  'UnregisterPushDevice': PushMutations.unregisterPushDevice,
  'ExchangeLoginTicket': AuthMutations.exchangeLoginTicket,
  'RefreshSession': AuthMutations.refreshSession,
  'Logout': AuthMutations.logout,
  'characterUpdated': CharacterSubscriptions.characterUpdated,
  'OnUserChanged': UserSubscriptions.userUpdated,
};
