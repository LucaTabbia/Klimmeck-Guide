import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';

class Equipment extends Equatable {
  const Equipment({
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

  final EquipmentItem? head;
  final EquipmentItem? chest;
  final EquipmentItem? arms;
  final EquipmentItem? legs;
  final EquipmentItem? foots;
  final EquipmentItem? leftHand;
  final EquipmentItem? rightHand;
  final EquipmentItem? firstAccessory;
  final EquipmentItem? secondAccessory;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    head: json["head"] != null ? EquipmentItem.fromJson(json["head"]) : null,
    chest: json["chest"] != null ? EquipmentItem.fromJson(json["chest"]) : null,
    arms: json["arms"] != null ? EquipmentItem.fromJson(json["arms"]) : null,
    legs: json["legs"] != null ? EquipmentItem.fromJson(json["legs"]) : null,
    foots: json["foots"] != null ? EquipmentItem.fromJson(json["foots"]) : null,
    leftHand: json["leftHand"] != null
        ? EquipmentItem.fromJson(json["leftHand"])
        : null,
    rightHand: json["rightHand"] != null
        ? EquipmentItem.fromJson(json["rightHand"])
        : null,
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

  Equipment copyWith({
    EquipmentItem? head,
    EquipmentItem? chest,
    EquipmentItem? arms,
    EquipmentItem? foots,
    EquipmentItem? legs,
    EquipmentItem? leftHand,
    EquipmentItem? rightHand,
    EquipmentItem? firstAccessory,
    EquipmentItem? secondAccessory,
  }) {
    return Equipment(
      head: head ?? this.head,
      chest: chest ?? this.chest,
      arms: arms ?? this.arms,
      foots: foots ?? this.foots,
      legs: legs ?? this.legs,
      leftHand: leftHand ?? this.leftHand,
      rightHand: rightHand ?? this.rightHand,
      firstAccessory: firstAccessory ?? this.firstAccessory,
      secondAccessory: secondAccessory ?? this.secondAccessory,
    );
  }

  @override
  List<Object?> get props => [
    head,
    chest,
    arms,
    foots,
    legs,
    leftHand,
    rightHand,
    firstAccessory,
    secondAccessory,
  ];
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
