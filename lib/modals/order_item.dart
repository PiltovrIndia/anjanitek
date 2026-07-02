import 'package:anjanitek/modals/product.dart';

class OrderItem {
  final String dealerId; // ID of the user who added this item to the Order
  final String dealerName; // Name of the dealer
  final int serialId; // Unique identifier for this Order item instance
  final Product product;
  final int quantity;
  final String stockType;
  final int productionQty; // 0 not request production, 1 = request production
  final DateTime addedAt;
  
  final double weight; // weight of the product, we can calculate this based on the product tags

  OrderItem({
    required this.dealerId,
    required this.dealerName,
    required this.serialId,
    required this.product,
    required this.quantity,
    required this.stockType,
    required this.productionQty,
    required this.weight,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  // double get totalPrice => product.price * quantity;

  OrderItem copyWith({
    String? dealerId,
    String? dealerName,
    int? serialId,
    Product? product,
    int? quantity,
    String? stockType,
    int? productionQty,
    DateTime? addedAt,
    double? weight,
  }) {
    return OrderItem(
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      serialId: serialId ?? this.serialId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      stockType: stockType ?? this.stockType,
      productionQty: productionQty ?? this.productionQty,
      addedAt: addedAt ?? this.addedAt,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'serialId': serialId,
        'product': product.toJson(),
        'quantity': quantity,
        'stockType': stockType,
        'productionQty': productionQty,
        'addedAt': addedAt.toIso8601String(),
        'dealerId': dealerId,
        'dealerName': dealerName,
        'weight': weight,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        serialId: json['serialId'] as int,
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        stockType: json['stockType'] as String,
        productionQty: json['productionQty'] as int,
        addedAt: DateTime.parse(json['addedAt'] as String),
        dealerId: json['dealerId'] as String,
        dealerName: json['dealerName'] as String,
        weight: (json['weight'] as num).toDouble(),
      );
}