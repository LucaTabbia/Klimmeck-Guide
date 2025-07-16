

import 'enum.dart';

class Bill {
  Bill({
    required this.id,
    required this.contractId,
    required this.supplyId,
    required this.description,
    required this.createdAt,
    required this.date,
    required this.code,
    required this.podPdr,
    required this.totalAmount,
    required this.typology,
    required this.consumption,
    required this.pdfUrl,
    required this.expireAt,
    required this.status,
    required this.address,
  });

  final String id;
  final String? description;
  final String createdAt;
  final String date;
  final String code;
  final double totalAmount;
  final String? contractId;
  final String? supplyId;
  final String? pdfUrl;
  final String? expireAt;
  final Status? status;
  final String? consumption;
  Typology? typology;
  String? podPdr;
  String? address;
  String? payedAt;
  String? paymentMethod;
  String? paymentScheduleId;

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json["id"],
    contractId: json["contract_id"],
    supplyId: json["supply_id"],
    totalAmount: json["total_amount"].toDouble(),
    description: json["description"],
    createdAt: json["created_at"],
    code: json["code"],
    typology: null,
    podPdr: null,
    consumption: json["consumption"],
    pdfUrl: json["external_pdf_url"],
    expireAt: json["expire_at"],
    address: null,
    status: Status.values.byName(json['status']),
    date: json["date"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "contract_id": contractId,
    "supply_id": supplyId,
    "total_amount": totalAmount,
    "created_at": createdAt,
    "code": code,
    "description": description,
    "consumption": consumption,
    "external_pdf_url": pdfUrl,
    "expire_at": expireAt,
    "status": status,
    "date": date,
  };
}
