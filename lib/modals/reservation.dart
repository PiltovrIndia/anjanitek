
/// Simple reservations model
class Reservation {
  final int id;
  final String userId;
  final String design;
  final String name;
  final int requestedQty;
  final String status;
  final int approvedQty;
  final String stockType;
  final String createdOn;
  final String? approvedOn;
  final String? modifiedOn;
  final int? isProduction;
  final String? cartId;
  final int? serialId;
  final int? isDeleted;
  final String? orderedBy;
  final int? designType;

  Reservation({
    required this.id,
    required this.userId,
    required this.design,
    required this.name,
    required this.requestedQty,
    required this.status,
    required this.approvedQty,
    required this.stockType,
    required this.createdOn,
    required this.approvedOn,
    required this.modifiedOn,
    required this.isProduction,
    required this.cartId,
    required this.serialId,
    required this.isDeleted,
    required this.orderedBy,
    required this.designType,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      userId: json['userId'] as String,
      design: json['design'] as String,
      name: json['name'] as String,
      requestedQty: json['requestedQty'] as int,
      status: json['status'] as String,
      approvedQty: json['approvedQty'] as int,
      stockType: json['stockType'] as String,
      createdOn: json['createdOn'] as String,
      approvedOn: json['approvedOn'] as String?,
      modifiedOn: json['modifiedOn'] as String?,
      isProduction: json['isProduction'] as int?,
      cartId: json['cartId'] as String?,
      serialId: json['serialId'] as int?,
      isDeleted: json['isDeleted'] as int?,
      orderedBy: json['orderedBy'] as String?,
      designType: json['designType'] as int?
    );
  }
}

