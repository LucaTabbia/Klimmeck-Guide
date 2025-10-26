class CharacterQueries {
  static const String getCharacter = r'''
    query character($id: String!) {
  character(id: $id) {
    assets {
      ownedEquipments {
        item {
          ... on EquipmentItem {
            addedSpell {
              energyDamage {
                power
                type
              }
              id
              maxUsages
              minXpToLearn
              name
              recoveryTime
              requiredLearnTime
              useType
            }
            buyPrice {
              copper
              gold
              silver
            }
            damages {
              base {
                type
                power
              }
              energy {
                power
                type
              }
            }
            description
            equipType
            id
            name
            rarity
            sellPrice {
              copper
              gold
              silver
            }
          }
        }
        quantity
      }
      activeSpells {
        spell {
          energyDamage {
            power
            type
          }
          id
          maxUsages
          minXpToLearn
          name
          recoveryTime
          requiredLearnTime
          useType
        }
        usages
      }
      ownedItems {
        item {
          ... on LootItem {
            buyPrice {
              copper
              gold
              silver
            }
            description
            effect
            id
            name
            power
            rarity
            sellPrice {
              copper
              gold
              silver
            }
          }
        }
        quantity
      }
    }
    id
    infos {
      age
      background
      classType
      imagePath
      name
      pronoun
      race
      sex
    }
    status {
      coins {
        copper
        gold
        silver
      }
      currentLifePoints
      injuries
      level
      location {
        latitude
        longitude
      }
      maxLifePoints
      spells {
        energyDamage {
          power
          type
        }
        id
        maxUsages
        minXpToLearn
        name
        recoveryTime
        requiredLearnTime
        useType
      }
      title
      xp
    }
    quests {
      completedQuests {
        id
      }
      pendingQuest {
        id
      }
    }
  }
}
  ''';

  static const String getEquipment = r'''
    fragment EquipmentItemFields on EquipmentItem {
      id
      name
      equipType
      rarity
      sellPrice {
        gold
        silver
        copper
      }
      buyPrice {
        gold
        silver
        copper
      }
      addedSpell {
        id
        name
        useType
        energyDamage {
          type
          power
        }
      }
    }
    
    query equipment($id: String!) {
      equipment(id: $id) {
        head { ...EquipmentItemFields }
        chest { ...EquipmentItemFields }
        legs { ...EquipmentItemFields }
        arms { ...EquipmentItemFields }
        leftHand { ...EquipmentItemFields }
        rightHand { ...EquipmentItemFields }
        firstAccessory { ...EquipmentItemFields }
        secondAccessory { ...EquipmentItemFields }
        foots { ...EquipmentItemFields }
      }
    }
  ''';

  static const String getOwnedEquipments = r'''
    query ownedEquipments($id: String!) {
      equipment(id: $id) {
        head { ...EquipmentItemFields }
        chest { ...EquipmentItemFields }
        legs { ...EquipmentItemFields }
        arms { ...EquipmentItemFields }
        leftHand { ...EquipmentItemFields }
        rightHand { ...EquipmentItemFields }
        firstAccessory { ...EquipmentItemFields }
        secondAccessory { ...EquipmentItemFields }
        foots { ...EquipmentItemFields }
      }
    }
  ''';

  static const String doTransaction = r'''
    mutation doTransaction($input: TransactionInput!) {
      doTransaction(input: $input) {
        response
        successful
      }
    }''';
}
