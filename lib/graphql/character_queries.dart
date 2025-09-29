class CharacterQueries {
  static const String getCharacter = r'''
    query character($id: String!) {
      character(id: $id) {
        id
        infos {
          sex
          imagePath
          name
          pronoun
          race
          classType
          age
          background
        }
        status {
          location {
            latitude
            longitude
          }
          xp
          spells {
            id
          }
          coins {
            gold
            silver
            copper
          }
          injuries
          currentLifePoints
          maxLifePoints
          title
          level
        }
        quests {
          completedQuests {
            id
          }
          pendingQuest {
            id
          }
        }
        assets {
          ownedItems {
            item 
            quantity
          }
          wearedEquipment {
            head {
              id
            }
            chest {
              id
            }
            firstAccessory {
              id
            }
            foots {
              id
            }
            arms {
              id
            }
            leftHand {
              id
            }
            legs {
              id
            }
            rightHand {
              id
            }
            secondAccessory {
              id
            }
          }
          ownedEquipments {
            item 
            quantity
          }
          activeSpells {
            spell {
              id
            }
            usages
          }
          pet {
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
}
