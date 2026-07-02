class ReservationProduct {
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
  final String? orderedBy;
  final int productId;
  final String? description;
  final String? size;
  final String? tags;
  final String? media;
  final int prm;
  final int std;
  final int isActive;
  final int designType;
  final String? dealer;
  final String? mobile;
  final String? mapTo;
  final int? isProduction;
  final String? cartId;
  final int? serialId;
  final int? isDeleted;

  ReservationProduct({
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
    required this.orderedBy,
    required this.productId,
    required this.description,
    required this.size,
    required this.tags,
    required this.media,
    required this.prm,
    required this.std,
    required this.isActive,
    required this.designType,
    required this.dealer,
    required this.mobile,
    required this.mapTo,
    required this.isProduction,
      this.cartId,
      this.serialId,
      this.isDeleted,
  });

  factory ReservationProduct.fromJson(Map<String, dynamic> json) {
    return ReservationProduct(
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
      orderedBy: json['orderedBy'] as String?,
      productId: json['productId'] as int,
      description: json['description'] as String,
      size: json['size'] as String?,
      tags: json['tags'] as String?,
      media: json['media'] as String?,
      prm: json['prm'] as int,
      std: json['std'] as int,
      isActive: json['isActive'] as int,
      designType: json['designType'] as int,
      dealer: json['dealer'] as String?,
      mobile: json['mobile'] as String?,
      mapTo: json['mapTo'] as String?,
      isProduction: json['isProduction'] as int?,
      cartId: json['cartId'] as String?,
      serialId: json['serialId'] as int?,
      isDeleted: json['isDeleted'] as int?,
    );
  }
}