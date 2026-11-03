import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/pet.dart';

/// Pool del negozio della città del marker, servito da `cityShop` (D-01): il
/// FE non filtra mai per rarità, taglia o prezzo (regola 4).
class CityShop extends Equatable {
  const CityShop({
    required this.cityId,
    required this.equipment,
    required this.loot,
    required this.pets,
  });

  factory CityShop.fromJson(Map<String, dynamic> json) {
    final cityId = (json['city'] as Map<String, dynamic>?)?['id'];
    if (cityId is! String) {
      throw const FormatException('cityShop.city.id missing');
    }
    return CityShop(
      cityId: cityId,
      equipment: _assets(json['equipment']),
      loot: _assets(json['loot']),
      pets: List<Pet>.unmodifiable(
        ((json['pets'] as List?) ?? const []).map(
          (x) => Pet.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  final String cityId;
  final List<AssetQuantity> equipment;
  final List<AssetQuantity> loot;
  final List<Pet> pets;

  static List<AssetQuantity> _assets(Object? raw) =>
      List<AssetQuantity>.unmodifiable(
        ((raw as List?) ?? const []).map(
          (x) => AssetQuantity.fromJson(x as Map<String, dynamic>),
        ),
      );

  @override
  List<Object?> get props => [cityId, equipment, loot, pets];
}
