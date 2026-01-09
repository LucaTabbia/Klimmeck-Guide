class CharacterSubscriptions {
  static const String characterUpdated = r'''
  
  fragment SpellFields on Spell {
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
          description
  }
  
   fragment EquipmentItemFields on EquipmentItem {
      id
      name
      equipType
      description
      rarity
      damages {
        base {
        power
        type
        }
        energy{
        power
        type
        }
      }
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
        ...SpellFields
      }
    }
    
    subscription characterUpdated($id: String!) {
  characterUpdated(id: $id) {
    assets {
    wearedEquipment {
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
      ownedEquipments {
        item {
          ... on EquipmentItem {
            ...EquipmentItemFields
          }
        }
        quantity
      }
      activeSpells {
        spell {
          ...SpellFields
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
        id
        location
      }
      maxLifePoints
      maxActiveSpells
      spells {
        ...SpellFields
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
}
