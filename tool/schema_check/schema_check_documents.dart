import 'package:klimmeck_guide/graphql/mutations/auth_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/character_mutations.dart';
import 'package:klimmeck_guide/graphql/mutations/mission_mutations.dart';
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
import 'package:klimmeck_guide/graphql/queries/mission_queries.dart';
import 'package:klimmeck_guide/graphql/queries/pending_request_queries.dart';
import 'package:klimmeck_guide/graphql/queries/point_of_interest_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_queries.dart';
import 'package:klimmeck_guide/graphql/queries/quest_result_queries.dart';
import 'package:klimmeck_guide/graphql/queries/server_time_queries.dart';
import 'package:klimmeck_guide/graphql/queries/shop_queries.dart';
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
/// `OnPendingRequestsUpdated` e `TeleportCharacter` (il documento del modulo di
/// completamento è stato tolto dalla Phase 21);
/// la Phase 13 aggiunge `GetCityShop`, `EquipPet` e `UnequipPet` e ha tolto
/// i due cataloghi globali di equipaggiamento e loot (BE D-20: deprecati,
/// nessun consumer); la Phase 14 aggiunge `GenerateQuests`;
/// la Phase 15 aggiunge `GetQuestTravelPreview`; la Phase 18 aggiunge
/// `UseItem`; la Phase 21 aggiunge `ListPointsOfInterest` e i documenti del
/// flusso guidato (`GetMissionDraft`, `ListMissionEnemies`,
/// `GetMissionPrizeOptions`, `StartMissionDraft`, `SaveMissionDraft`,
/// `SimulateMissionFight`, `DiscardMissionDraft`, `CompleteGuidedMission`);
/// ogni documento futuro va aggiunto qui (il test
/// `schema_check_documents_test.dart` lo impone).
final Map<String, String> schemaCheckDocuments = {
  'cities': CityQueries.getAllCities,
  'GetCity': CityQueries.getCity,
  'ListPointsOfInterest': PointOfInterestQueries.listPointsOfInterest,
  'GetCityShop': ShopQueries.getCityShop,
  'GetTravelPreview': TravelQueries.getTravelPreview,
  'GetQuestTravelPreview': TravelQueries.getQuestTravelPreview,
  'lootItems': LootItemQueries.getAllLootItems,
  'lootItemsByIds': LootItemQueries.getLootItemsByIds,
  'GetMe': AuthQueries.getMe,
  'GetServerTime': ServerTimeQueries.getServerTime,
  'GetRaceTraits': CharacterQueries.getRaceTraits,
  'character': CharacterQueries.getCharacter,
  'equipment': CharacterQueries.getEquipment,
  'equipmentItems': EquipmentItemQueries.getAllEquipmentItems,
  'equipmentItemsByIds': EquipmentItemQueries.getEquipmentItemsByIds,
  'quests': QuestQueries.getAllQuests,
  'GetQuestResult': QuestResultQueries.getQuestResult,
  'ListUnacknowledgedQuestResults':
      QuestResultQueries.listUnacknowledgedQuestResults,
  'GetPendingRequests': PendingRequestQueries.getPendingRequests,
  'GetMissionDraft': MissionQueries.getMissionDraft,
  'ListMissionEnemies': MissionQueries.listMissionEnemies,
  'GetMissionPrizeOptions': MissionQueries.getMissionPrizeOptions,
  'lores': LoreQueries.getAllLores,
  'lore': LoreQueries.getLoreById,
  'CreateCharacter': CharacterMutations.createCharacter,
  'DeleteCharacter': CharacterMutations.deleteCharacter,
  'doTransaction': CharacterMutations.doTransaction,
  'equipItem': CharacterMutations.equipItem,
  'EquipSpell': CharacterMutations.equipSpell,
  'UnequipSpell': CharacterMutations.unequipSpell,
  'EquipPet': CharacterMutations.equipPet,
  'UnequipPet': CharacterMutations.unequipPet,
  'UseItem': CharacterMutations.useItem,
  'AcceptQuest': QuestMutations.acceptQuest,
  'AbandonQuest': QuestMutations.abandonQuest,
  'GenerateQuests': QuestMutations.generateQuests,
  'AcknowledgeQuestResult': QuestResultMutations.acknowledgeQuestResult,
  'StartMissionDraft': MissionMutations.startMissionDraft,
  'SaveMissionDraft': MissionMutations.saveMissionDraft,
  'SimulateMissionFight': MissionMutations.simulateMissionFight,
  'DiscardMissionDraft': MissionMutations.discardMissionDraft,
  'CompleteGuidedMission': MissionMutations.completeGuidedMission,
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
