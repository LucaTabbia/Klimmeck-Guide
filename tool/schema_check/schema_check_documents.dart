import 'package:klimmeck_guide/graphql/mutations/auth_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/pending_request_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/push_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/quest_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/quest_result_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/travel_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/auth_queries.dart';
import 'package:klimmeck_guide/graphql/queries/character_queries.dart';
import 'package:klimmeck_guide/graphql/queries/city_queries.dart';
import 'package:klimmeck_guide/graphql/queries/equipment_item_queries.dart';
import 'package:klimmeck_guide/graphql/queries/loot_item_queries.dart';
import 'package:klimmeck_guide/graphql/queries/lore_queries.dart';
import 'package:klimmeck_guide/graphql/queries/pending_request_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_result_queries.dart';
import 'package:klimmeck_guide/graphql/queries/server_time_queries.dart';
import 'package:klimmeck_guide/graphql/queries/travel_queries.dart';
import 'package:klimmeck_guide/graphql/subscriptions/character_subscriptions.dart';
import 'package:klimmeck_guide/graphql/subscriptions/pending_request_subscriptions.dart';
import 'package:klimmeck_guide/graphql/subscriptions/quest_result_subscriptions.dart';
import 'package:klimmeck_guide/graphql/subscriptions/quest_subscriptions.dart';
import 'package:klimmeck_guide/graphql/subscriptions/user_subscriptions.dart';

/// Ogni operazione GraphQL nominata dell'app, per nome operazione.
///
/// Validata contro `src/schema.gql` del backend da `validate_documents.js`.
/// La Phase 5 aggiunge `RegisterPushDevice` e `UnregisterPushDevice`; la
/// Phase 7 aggiunge `GetServerTime`, `GetTravelPreview` e `StartTravel`; il
/// quick 261025-grp aggiunge `AbandonQuest`; il quick 261026-prt aggiunge
/// `OnQuestUpdated`; la Phase 8 rinomina `EquipSpell` e `UnequipSpell`; la
/// Phase 9 aggiunge `OnQuestResultReceived` e `GetQuestResult`; la Phase 9
/// (dopo la BE 9.2) aggiunge `ListUnacknowledgedQuestResults` e
/// `AcknowledgeQuestResult`; la Phase 10 aggiunge `GetPendingRequests`,
/// `OnPendingRequestsUpdated`, `CompletePendingRequest` e `TeleportCharacter`;
/// ogni documento futuro va aggiunto qui
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
  'GetQuestResult': QuestResultQueries.getQuestResult,
  'ListUnacknowledgedQuestResults':
      QuestResultQueries.listUnacknowledgedQuestResults,
  'GetPendingRequests': PendingRequestQueries.getPendingRequests,
  'lores': LoreQueries.getAllLores,
  'lore': LoreQueries.getLoreById,
  'CreateCharacter': CharacterMutations.createCharacter,
  'DeleteCharacter': CharacterMutations.deleteCharacter,
  'doTransaction': CharacterMutations.doTransaction,
  'equipItem': CharacterMutations.equipItem,
  'EquipSpell': CharacterMutations.equipSpell,
  'UnequipSpell': CharacterMutations.unequipSpell,
  'AcceptQuest': QuestMutations.acceptQuest,
  'AbandonQuest': QuestMutations.abandonQuest,
  'AcknowledgeQuestResult': QuestResultMutations.acknowledgeQuestResult,
  'CompletePendingRequest': PendingRequestMutations.completePendingRequest,
  'StartTravel': TravelMutations.startTravel,
  'TeleportCharacter': TravelMutations.teleportCharacter,
  'RegisterPushDevice': PushMutations.registerPushDevice,
  'UnregisterPushDevice': PushMutations.unregisterPushDevice,
  'ExchangeLoginTicket': AuthMutations.exchangeLoginTicket,
  'RefreshSession': AuthMutations.refreshSession,
  'Logout': AuthMutations.logout,
  'characterUpdated': CharacterSubscriptions.characterUpdated,
  'OnUserChanged': UserSubscriptions.userUpdated,
  'OnQuestUpdated': QuestSubscriptions.questUpdated,
  'OnQuestResultReceived': QuestResultSubscriptions.questResultReceived,
  'OnPendingRequestsUpdated':
      PendingRequestSubscriptions.pendingRequestsUpdated,
};
