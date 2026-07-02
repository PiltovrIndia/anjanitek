class CartItem {
  final String cartId;
  final String dealerId;
  final String userId;
  final String createdOn;
  final int totalDesigns;
  final int totalRequestedQty;
  final int totalApprovedQty;
  final int totalProductionQty;
  final String orderStatus;
  final List<OrderedItem>? orderedItems; // this will be populated when we fetch the cart details

  CartItem({
    required this.cartId,
    required this.dealerId,
    required this.userId,
    required this.createdOn,
    required this.totalDesigns,
    required this.totalRequestedQty,
    required this.totalApprovedQty,
    required this.totalProductionQty,
    required this.orderStatus,
    required this.orderedItems,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cartId'] as String,
      dealerId: json['dealerId'] as String,
      userId: json['userId'] as String,
      createdOn: json['createdOn'] as String,
      totalDesigns: json['totalDesigns'] as int,
      totalRequestedQty: json['totalRequestedQty'] as int,
      totalApprovedQty: json['totalApprovedQty'] as int,
      totalProductionQty: json['totalProductionQty'] as int,
      orderStatus: json['orderStatus'] as String,
      orderedItems: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderedItem.fromJson(item))
              .toList()
          : null,
    );
  }
}

class OrderedItem {
  final int id;
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
  final int productionQty;
  final int availabilityPercent; // this is the sequence number for the waitlist, if the reservation is in waitlist then this will be greater than 0, if it's not in waitlist then this will be 0
  final int? waitlistPosition; // this is the sequence number for the waitlist, if the reservation is in waitlist then this will be greater than 0, if it's not in waitlist then this will be 0
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
  final int? serialId;
  final int? isDeleted;

  OrderedItem({
    required this.id,
    required this.serialId,
    required this.design,
    required this.name,
    required this.requestedQty,
    required this.status,
    required this.availabilityPercent,
    required this.approvedQty,
    required this.stockType,
    required this.createdOn,
    required this.approvedOn,
    required this.modifiedOn,
    required this.orderedBy,
    required this.productionQty,
    required this.waitlistPosition,
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
    required this.isDeleted,
  });

  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    return OrderedItem(
      id: json['id'] as int,
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
      productionQty: json['productionQty'] as int,
      availabilityPercent: json['availabilityPercent'] as int,
      waitlistPosition: json['waitlistPosition'] as int?,
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
      serialId: json['serialId'] as int?,
      isDeleted: json['isDeleted'] as int?,
    );
  }
}