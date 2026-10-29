import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
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
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/abandon_quest_request.dart';
import 'package:klimmeck_guide/models/request/accept_quest_request.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/models/request/equip_spell_request.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';

class KlimmeckGraphQl {
  /// Il client arriva dal composition root (`main.dart`) o dal test: il
  /// service non conosce l'albero dei widget né il `navigatorKey`.
  KlimmeckGraphQl({required GraphQLClient Function() resolveClient})
    : _resolveClient = resolveClient;

  final GraphQLClient Function() _resolveClient;

  final KGStorageManager localStorage = KGStorageManager();

  String getGenericErrorMessage(OperationException? exception) {
    if (exception != null) {
      if (exception.linkException != null) {
        return 'Network error: ${exception.linkException}';
      }
      if (exception.graphqlErrors.isNotEmpty) {
        final String graphqlError = exception.graphqlErrors
            .map((e) => e.message)
            .join(', ');
        return 'Server error: $graphqlError';
      }
    }
    return 'Generic server error';
  }

  Future<QueryResult> performQuery(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: variables ?? {},
      fetchPolicy: FetchPolicy.noCache,
    );
    final client = _resolveClient();
    final result = await client.query(options);
    return result;
  }

  Future<QueryResult> performMutation({
    required String query,
    Map<String, dynamic> variables = const {},
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(query),
      variables: variables,
      fetchPolicy: FetchPolicy.noCache,
    );
    final client = _resolveClient();
    final result = await client.mutate(options);
    return result;
  }

  Stream<QueryResult<Object?>> performSubscription(
    String query, {
    Map<String, dynamic>? variables,
  }) {
    final SubscriptionOptions options = SubscriptionOptions(
      document: gql(query),
      variables: variables ?? {},
      fetchPolicy: FetchPolicy.noCache,
    );
    final client = _resolveClient();
    return client.subscribe(options);
  }

  Stream<User> subscribeToUser() =>
      performSubscription(UserSubscriptions.userUpdated).map((result) {
        _throwIfStreamFailed(result, operation: 'userUpdated');
        return _userFrom(result.data?['userUpdated']);
      });

  Stream<Character> subscribeToCharacter(String id) =>
      performSubscription(
        CharacterSubscriptions.characterUpdated,
        variables: {'id': id},
      ).map((result) {
        _throwIfStreamFailed(result, operation: 'characterUpdated');
        return _characterFrom(result.data?['characterUpdated']);
      });

  Stream<Quest> subscribeToQuest(String questId) =>
      performSubscription(
        QuestSubscriptions.questUpdated,
        variables: {'questId': questId},
      ).map((result) {
        _throwIfStreamFailed(result, operation: 'questUpdated');
        return _questFrom(result.data?['questUpdated']);
      });

  /// Esiti del personaggio in foreground (BE Phase 9 §3): payload completo,
  /// nessuno snapshot. Un evento malformato diventa una FormatException senza
  /// chiudere lo stream (T-9-15).
  Stream<QuestResult> subscribeToQuestResults(String characterId) =>
      performSubscription(
        QuestResultSubscriptions.questResultReceived,
        variables: {'characterId': characterId},
      ).map((result) {
        _throwIfStreamFailed(result, operation: 'questResultReceived');
        return _questResultFrom(result.data?['questResultReceived']);
      });

  /// Esito per id (tap su `questEnd`, D-11). Lancia [OperationException] o
  /// [FormatException].
  Future<QuestResult> getQuestResult(String id) async {
    final data = _dataOrThrow(
      await performQuery(
        QuestResultQueries.getQuestResult,
        variables: {'id': id},
      ),
    );
    return _questResultFrom(data['questResult']);
  }

  /// Risultati dell'utente non ancora confermati, nell'ordine del server (BE
  /// 9.2 D-02). Una voce malformata è scartata, le altre restano (09-REVIEW
  /// IN-04). Lancia [OperationException] o [FormatException] se la lista manca.
  Future<List<QuestResult>> getUnacknowledgedQuestResults() async {
    final data = _dataOrThrow(
      await performQuery(QuestResultQueries.listUnacknowledgedQuestResults),
    );
    final entries = data['unacknowledgedQuestResults'];
    if (entries is! List) {
      throw const FormatException('unacknowledgedQuestResults missing');
    }
    return List.unmodifiable(
      entries.map(QuestResult.tryFromJson).whereType<QuestResult>(),
    );
  }

  /// Conferma un foglio chiuso (BE 9.2 D-03), idempotente; la conferma di una
  /// morte stacca il personaggio corrente (D-12). Lancia [OperationException]
  /// o [FormatException].
  Future<void> acknowledgeQuestResult(String id) async {
    final data = _dataOrThrow(
      await performMutation(
        query: QuestResultMutations.acknowledgeQuestResult,
        variables: {'id': id},
      ),
    );
    final result = data['acknowledgeQuestResult'];
    if (result is! Map<String, dynamic> || result['successful'] != true) {
      throw const FormatException('acknowledgeQuestResult not successful');
    }
  }

  /// Coda del GM (BE 09 §9): snapshot alla sottoscrizione, poi la lista intera
  /// a ogni insert/delete di PendingQuest. Una voce malformata è scartata, le
  /// altre restano (Phase 9 IN-04); solo se manca la lista l'evento è un errore.
  Stream<List<PendingRequest>> subscribeToPendingRequests() =>
      performSubscription(
        PendingRequestSubscriptions.pendingRequestsUpdated,
      ).map((result) {
        _throwIfStreamFailed(result, operation: 'pendingRequestsUpdated');
        return _pendingRequestsFrom(result.data?['pendingRequestsUpdated']);
      });

  /// Rilettura della coda (D-18). Lancia [OperationException] o
  /// [FormatException].
  Future<List<PendingRequest>> getPendingRequests() async {
    final data = _dataOrThrow(
      await performQuery(PendingRequestQueries.getPendingRequests),
    );
    return _pendingRequestsFrom(data['pendingRequests']);
  }

  /// Completa una richiesta per tutti i partecipanti (BE 09 §9): restituisce i
  /// risultati creati, voce per voce. Lancia [OperationException] o
  /// [FormatException].
  Future<List<QuestResult>> completePendingRequest(
    CompletePendingRequestInput input,
  ) async {
    final data = _dataOrThrow(
      await performMutation(
        query: PendingRequestMutations.completePendingRequest,
        variables: {'input': input.toJson()},
      ),
    );
    final entries = data['completePendingRequest'];
    if (entries is! List) {
      throw const FormatException('completePendingRequest missing');
    }
    return List.unmodifiable(
      entries.map(QuestResult.tryFromJson).whereType<QuestResult>(),
    );
  }

  List<PendingRequest> _pendingRequestsFrom(Object? json) {
    if (json is! List) throw const FormatException('pendingRequests missing');
    final parsed = json
        .map(PendingRequest.tryFromJson)
        .whereType<PendingRequest>()
        .toList();
    final skipped = json.length - parsed.length;
    if (skipped > 0) {
      debugPrint('[Innkeeper] skipped $skipped malformed queue entries');
    }
    return List.unmodifiable(parsed);
  }

  void _throwIfStreamFailed(QueryResult result, {required String operation}) {
    if (!result.hasException) return;
    throw SubscriptionStreamException(
      operation: operation,
      code: graphQlErrorCode(result.exception),
    );
  }

  Character _characterFrom(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('character missing');
    }
    try {
      return Character.fromJson(json);
    } on Object catch (error) {
      throw FormatException('character malformed: ${error.runtimeType}');
    }
  }

  Quest _questFrom(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('quest missing');
    }
    try {
      return Quest.fromJson(json);
    } on Object catch (error) {
      throw FormatException('quest malformed: ${error.runtimeType}');
    }
  }

  QuestResult _questResultFrom(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('questResult missing');
    }
    final result = QuestResult.tryFromJson(json);
    if (result == null) throw const FormatException('questResult malformed');
    return result;
  }

  Future<List<City>> getCities() async {
    final result = await performQuery(CityQueries.getAllCities);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? citiesData = result.data?['cities'];
    if (citiesData == null) {
      throw Exception('No cities found');
    }

    return citiesData.map((json) => City.fromJson(json)).toList();
  }

  Future<List<Quest>> getQuests() async {
    final result = await performQuery(QuestQueries.getAllQuests);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? questsData = result.data?['quests'];
    if (questsData == null) {
      throw Exception('No quest found');
    }

    final quests = <Quest>[];
    for (final json in questsData) {
      final quest = Quest.tryFromJson(json);
      if (quest == null) {
        debugPrint('Quest skipped: ${json is Map ? json['id'] : 'unknown'}');
        continue;
      }
      quests.add(quest);
    }
    return quests;
  }

  /// Id dei POI della città (marker incluso). Lancia [OperationException] o
  /// [FormatException].
  Future<Set<String>> getCityPointIds(String cityId) async {
    final data = _dataOrThrow(
      await performQuery(CityQueries.getCity, variables: {'id': cityId}),
    );
    final city = data['city'];
    if (city is! Map<String, dynamic>) {
      throw const FormatException('city missing');
    }
    return Set.unmodifiable({
      if (city['markerLocation'] case {'id': final String markerId}) markerId,
      for (final poi
          in (city['pointsOfInterest'] as List<dynamic>? ?? const []))
        if (poi case {'id': final String poiId}) poiId,
    });
  }

  Future<List<EquipmentItem>> getEquipmentItems(List<String> ids) async {
    final result = await performQuery(
      EquipmentItemQueries.getEquipmentItemsByIds,
      variables: {"ids": ids},
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? equipmentItemsData =
        result.data?['equipmentItemsByIds'];
    if (equipmentItemsData == null) {
      throw Exception('No equipmentItem found');
    }

    return equipmentItemsData
        .map((json) => EquipmentItem.fromJson(json))
        .toList();
  }

  Future<List<EquipmentItem>> getAllEquipmentItems() async {
    final result = await performQuery(
      EquipmentItemQueries.getAllEquipmentItems,
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? equipmentItemsData = result.data?['equipmentItems'];
    if (equipmentItemsData == null) {
      throw Exception('No equipmentItem found');
    }

    return equipmentItemsData
        .map((json) => EquipmentItem.fromJson(json))
        .toList();
  }

  Future<List<AssetQuantity>> getAllEquipmentAssetsQuantity({
    bool? sellable,
  }) async {
    final Map<String, dynamic> variables = sellable != null
        ? {"sellable": sellable}
        : {};

    final result = await performQuery(
      EquipmentItemQueries.getAllEquipmentAssetsQuantity,
      variables: variables,
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? equipmentAssetsQuantityData =
        result.data?['equipmentAssetsQuantity'];
    if (equipmentAssetsQuantityData == null) {
      throw Exception('No equipmentItem found');
    }

    return equipmentAssetsQuantityData
        .map((json) => AssetQuantity.fromJson(json))
        .toList();
  }

  Future<List<LootItem>> getLootItems(List<String> ids) async {
    final result = await performQuery(
      LootItemQueries.getLootItemsByIds,
      variables: {"ids": ids},
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? lootItemsData = result.data?['lootItemsByIds'];
    if (lootItemsData == null) {
      throw Exception('No lootItem found');
    }

    return lootItemsData.map((json) => LootItem.fromJson(json)).toList();
  }

  Future<List<LootItem>> getAllLootItems() async {
    final result = await performQuery(LootItemQueries.getAllLootItems);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? lootItemsData = result.data?['lootItems'];
    if (lootItemsData == null) {
      throw Exception('No lootItem found');
    }

    return lootItemsData.map((json) => LootItem.fromJson(json)).toList();
  }

  Future<List<AssetQuantity>> getAllLootAssetsQuantity() async {
    final result = await performQuery(LootItemQueries.getAllLootAssetsQuantity);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? lootAssetsQuantityData =
        result.data?['lootAssetsQuantity'];
    if (lootAssetsQuantityData == null) {
      throw Exception('No lootItem found');
    }

    return lootAssetsQuantityData
        .map((json) => AssetQuantity.fromJson(json))
        .toList();
  }

  Future<Character> getCharacter(String id) async {
    final result = await performQuery(
      CharacterQueries.getCharacter,
      variables: {"id": id},
    );
    final code = graphQlErrorCode(result.exception);
    if (accessDeniedCodes.contains(code)) {
      throw GraphQlAccessDeniedException(operation: 'character', code: code!);
    }
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic characterData = result.data?['character'];
    if (characterData == null) {
      throw Exception('No character found');
    }

    return Character.fromJson(characterData);
  }

  Future<Equipment> getEquipment(String id) async {
    final result = await performQuery(
      CharacterQueries.getEquipment,
      variables: {"id": id},
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic equipmentData = result.data?['equipment'];
    if (equipmentData == null) {
      throw Exception('No equipment found');
    }

    return Equipment.fromJson(equipmentData);
  }

  Future<List<Lore>> getAllLores() async {
    final result = await performQuery(LoreQueries.getAllLores);
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final List<dynamic>? loresData = result.data?['lores'];
    if (loresData == null) {
      throw Exception('No lore found');
    }

    return loresData.map((json) => Lore.fromJson(json)).toList();
  }

  Future<Lore> getLoreById(String id) async {
    final result = await performQuery(
      LoreQueries.getLoreById,
      variables: {"id": id},
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic loreData = result.data?['lore'];
    if (loreData == null) {
      throw Exception('No lore found');
    }

    return Lore.fromJson(loreData);
  }

  /// Lancia [OperationException] (codici in `transaction_failure.dart`) o
  /// [FormatException].
  Future<String> doTransaction(TransactionRequest request) async {
    final data = _dataOrThrow(
      await performMutation(
        query: CharacterMutations.doTransaction,
        variables: {"request": request},
      ),
    );
    final result = data['doTransaction'];
    final response = result is Map<String, dynamic> ? result['response'] : null;
    if (response is! String) {
      throw const FormatException('doTransaction malformed');
    }
    return response;
  }

  Future<String> equipItem(EquipItemRequest request) async {
    final result = await performMutation(
      query: CharacterMutations.equipItem,
      variables: {"request": request},
    );
    if (result.hasException) {
      final errorMessage = getGenericErrorMessage(result.exception);
      throw Exception(errorMessage);
    }

    final dynamic transactionResult = result.data?['equipItem'];
    if (transactionResult == null) {
      throw Exception("Can't equip item");
    }

    return transactionResult["response"];
  }

  /// Tabella età/razza dal backend. Lancia [OperationException] o [FormatException].
  Future<List<RaceTraits>> getRaceTraits() async {
    final data = _dataOrThrow(
      await performQuery(CharacterQueries.getRaceTraits),
    );
    final list = data['raceTraits'];
    if (list is! List) throw const FormatException('raceTraits missing');
    return List<RaceTraits>.unmodifiable(
      list
          .whereType<Map<String, dynamic>>()
          .map(RaceTraits.tryFromJson)
          .whereType<RaceTraits>(),
    );
  }

  /// Crea il personaggio dell'utente autenticato e restituisce lo User aggiornato.
  Future<User> createCharacter(CreateCharacterRequest request) async {
    final data = _dataOrThrow(
      await performMutation(
        query: CharacterMutations.createCharacter,
        variables: {'input': request.toJson()},
      ),
    );
    return _userFrom(data['createCharacter']);
  }

  /// Elimina (archivia) il personaggio corrente e restituisce lo User aggiornato,
  /// con `currentCharacter: null`. Lancia [OperationException] o [FormatException].
  Future<User> deleteCharacter() async {
    final data = _dataOrThrow(
      await performMutation(query: CharacterMutations.deleteCharacter),
    );
    return _userFrom(data['deleteCharacter']);
  }

  /// Accetta la quest (D-05). La corsia e il saldo arrivano dalle subscription,
  /// mai da questa risposta (D-03). Lancia [OperationException] o [FormatException].
  Future<void> acceptQuest(AcceptQuestRequest request) async {
    final data = _dataOrThrow(
      await performMutation(
        query: QuestMutations.acceptQuest,
        variables: {'request': request.toJson()},
      ),
    );
    final result = data['acceptQuest'];
    if (result is! Map<String, dynamic> || result['successful'] != true) {
      throw const FormatException('acceptQuest not successful');
    }
  }

  /// Lascia il gruppo in attesa sul marker (BE 09-19). Lancia
  /// [OperationException] o [FormatException].
  Future<void> abandonQuest(AbandonQuestRequest request) async {
    final data = _dataOrThrow(
      await performMutation(
        query: QuestMutations.abandonQuest,
        variables: {'request': request.toJson()},
      ),
    );
    final result = data['abandonQuest'];
    if (result is! Map<String, dynamic> || result['successful'] != true) {
      throw const FormatException('abandonQuest not successful');
    }
  }

  /// Ora del server per l'offset dell'interpolazione (Phase 7 D-07). Lancia
  /// [OperationException] o [FormatException].
  Future<DateTime> getServerTime() async {
    final data = _dataOrThrow(
      await performQuery(ServerTimeQueries.getServerTime),
    );
    final serverTime = data['serverTime'];
    if (serverTime is! String) {
      throw const FormatException('serverTime missing');
    }
    return DateTime.parse(serverTime);
  }

  /// Anteprima del viaggio per il foglio di conferma (D-03): stesse regole e
  /// codici di `startTravel`, nessuna scrittura. Lancia [OperationException] o
  /// [FormatException].
  Future<TravelPreview> previewTravel(TravelRequest request) async {
    final data = _dataOrThrow(
      await performQuery(
        TravelQueries.getTravelPreview,
        variables: {'request': request.toJson()},
      ),
    );
    return _travelPreviewFrom(data['travelPreview']);
  }

  /// Avvia il viaggio (D-05): il viaggio arriva su `characterUpdated`, mai da
  /// questa risposta; restituisce solo `successful`. Lancia [OperationException]
  /// o [FormatException] per una risposta malformata.
  Future<bool> startTravel(TravelRequest request) =>
      _travelMutation(TravelMutations.startTravel, 'startTravel', request);

  /// Teletrasporto del GM (BE 08 §7): solo `successful`, la posizione arriva
  /// dalla coda/`characterUpdated`. Lancia [OperationException] o
  /// [FormatException].
  Future<bool> teleportCharacter(TravelRequest request) => _travelMutation(
    TravelMutations.teleportCharacter,
    'teleportCharacter',
    request,
  );

  Future<bool> _travelMutation(
    String document,
    String field,
    TravelRequest request,
  ) async {
    final data = _dataOrThrow(
      await performMutation(
        query: document,
        variables: {'request': request.toJson()},
      ),
    );
    final result = data[field];
    final successful = result is Map<String, dynamic>
        ? result['successful']
        : null;
    if (successful is! bool) throw FormatException('$field malformed');
    return successful;
  }

  /// Equipaggia una magia (D-06): lo stato arriva su `characterUpdated`, mai da
  /// questa risposta (D-16). Restituisce solo `successful`; lancia
  /// [OperationException] o [FormatException] per una risposta malformata.
  Future<bool> equipSpell(EquipSpellRequest request) =>
      _spellSlotMutation(CharacterMutations.equipSpell, 'equipSpell', request);

  /// Disequipaggia una magia (D-06), stesso contratto di [equipSpell].
  Future<bool> unequipSpell(EquipSpellRequest request) => _spellSlotMutation(
    CharacterMutations.unequipSpell,
    'unequipSpell',
    request,
  );

  Future<bool> _spellSlotMutation(
    String document,
    String field,
    EquipSpellRequest request,
  ) async {
    final data = _dataOrThrow(
      await performMutation(
        query: document,
        variables: {'request': request.toJson()},
      ),
    );
    final result = data[field];
    final successful = result is Map<String, dynamic>
        ? result['successful']
        : null;
    if (successful is! bool) throw FormatException('$field malformed');
    return successful;
  }

  /// Registra il device per il push (D-07): `platform` è un valore di `PushPlatform`.
  /// Lancia [OperationException]; il Boolean restituito è sempre `true`.
  Future<void> registerPushDevice({
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    _dataOrThrow(
      await performMutation(
        query: PushMutations.registerPushDevice,
        variables: {
          'input': {'deviceId': deviceId, 'token': token, 'platform': platform},
        },
      ),
    );
  }

  /// Rimuove il device del chiamante (D-08, prima del logout). Lancia [OperationException].
  Future<void> unregisterPushDevice(String deviceId) async {
    _dataOrThrow(
      await performMutation(
        query: PushMutations.unregisterPushDevice,
        variables: {'deviceId': deviceId},
      ),
    );
  }

  /// Utente corrente via il client autenticato (recovery di CHARACTER_ALREADY_EXISTS).
  Future<User> getMe() async =>
      _userFrom(_dataOrThrow(await performQuery(AuthQueries.getMe))['me']);

  Map<String, dynamic> _dataOrThrow(QueryResult result) {
    final exception = result.exception;
    if (exception != null) throw exception;
    return result.data ?? const {};
  }

  /// Confine di parsing: un payload malformato fa lanciare a `User.fromJson`
  /// TypeError/ArgumentError, che qui diventano la [FormatException] attesa dal
  /// repository (stesso pattern di `RaceTraits.tryFromJson`).
  User _userFrom(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('user missing');
    }
    try {
      return User.fromJson(json);
    } on Object catch (error) {
      throw FormatException('user malformed: ${error.runtimeType}');
    }
  }

  /// Confine di parsing dell'anteprima (stesso pattern di `_userFrom`).
  TravelPreview _travelPreviewFrom(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('travelPreview missing');
    }
    try {
      return TravelPreview.fromJson(json);
    } on Object catch (error) {
      throw FormatException('travelPreview malformed: ${error.runtimeType}');
    }
  }
}
