import 'package:klimmeck_guide/models/equipment_item.dart';

class Equipment {
  Equipment({
    required this.head,
    required this.chest,
    required this.arms,
    required this.foots,
    required this.legs,
    required this.leftHand,
    required this.rightHand,
    required this.firstAccessory,
    required this.secondAccessory,
  });

  EquipmentItem? head;
  EquipmentItem? chest;
  EquipmentItem? arms;
  EquipmentItem? legs;
  EquipmentItem? foots;
  EquipmentItem? leftHand;
  EquipmentItem? rightHand;
  EquipmentItem? firstAccessory;
  EquipmentItem? secondAccessory;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    head: json["head"] != null ? EquipmentItem.fromJson(json["head"]) : null,
    chest: json["chest"] != null ? EquipmentItem.fromJson(json["chest"]) : null,
    arms: json["arms"] != null ? EquipmentItem.fromJson(json["arms"]) : null,
    legs: json["legs"] != null ? EquipmentItem.fromJson(json["legs"]) : null,
    foots: json["foots"] != null ? EquipmentItem.fromJson(json["foots"]) : null,
    leftHand: json["leftHand"] != null ? EquipmentItem.fromJson(json["leftHand"]) : null,
    rightHand: json["rightHand"] != null ? EquipmentItem.fromJson(json["rightHand"]) : null,
    firstAccessory: json["firstAccessory"] != null
        ? EquipmentItem.fromJson(json["firstAccessory"])
        : null,
    secondAccessory: json["secondAccessory"] != null
        ? EquipmentItem.fromJson(json["secondAccessory"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "head": head?.id,
    "chest": chest?.id,
    "arms": arms?.id,
    "legs": legs?.id,
    "foots": foots?.id,
    "leftHand": leftHand?.id,
    "rightHand": rightHand?.id,
    "firstAccessory": firstAccessory?.id,
    "secondAccessory": secondAccessory?.id,
  };
}

extension EquipmentValues on Equipment {
  List<EquipmentItem?> get values => [
    head,
    chest,
    arms,
    legs,
    foots,
    leftHand,
    rightHand,
    firstAccessory,
    secondAccessory,
  ];
}
