import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';

class Equipment extends Equatable {
  const Equipment({
    required this.head,
    required this.chest,
    required this.arms,
    required this.feet,
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
  final EquipmentItem? feet;
  final EquipmentItem? leftHand;
  final EquipmentItem? rightHand;
  final EquipmentItem? firstAccessory;
  final EquipmentItem? secondAccessory;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    head: EquipmentItem.tryFromJson(json['head']),
    chest: EquipmentItem.tryFromJson(json['chest']),
    arms: EquipmentItem.tryFromJson(json['arms']),
    legs: EquipmentItem.tryFromJson(json['legs']),
    feet: EquipmentItem.tryFromJson(json['feet']),
    leftHand: EquipmentItem.tryFromJson(json['leftHand']),
    rightHand: EquipmentItem.tryFromJson(json['rightHand']),
    firstAccessory: EquipmentItem.tryFromJson(json['firstAccessory']),
    secondAccessory: EquipmentItem.tryFromJson(json['secondAccessory']),
  );

  Map<String, dynamic> toJson() => {
    "head": head?.id,
    "chest": chest?.id,
    "arms": arms?.id,
    "legs": legs?.id,
    "feet": feet?.id,
    "leftHand": leftHand?.id,
    "rightHand": rightHand?.id,
    "firstAccessory": firstAccessory?.id,
    "secondAccessory": secondAccessory?.id,
  };

  Equipment copyWith({
    EquipmentItem? head,
    EquipmentItem? chest,
    EquipmentItem? arms,
    EquipmentItem? feet,
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
      feet: feet ?? this.feet,
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
    feet,
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
    feet,
    leftHand,
    rightHand,
    firstAccessory,
    secondAccessory,
  ];
}
