import 'package:anjanitek/modals/product.dart';

class CartItem {
  final String dealerId; // ID of the user who added this item to the cart
  final String dealerName; // Name of the dealer
  final int serialId; // Unique identifier for this cart item instance
  final Product product;
  final int quantity;
  final String stockType;
  final int isProduction; // 0 not request production, 1 = request production
  final DateTime addedAt;
  
  final double weight; // weight of the product, we can calculate this based on the product tags

  CartItem({
    required this.dealerId,
    required this.dealerName,
    required this.serialId,
    required this.product,
    required this.quantity,
    required this.stockType,
    required this.isProduction,
    required this.weight,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  // double get totalPrice => product.price * quantity;

  CartItem copyWith({
    String? dealerId,
    String? dealerName,
    int? serialId,
    Product? product,
    int? quantity,
    String? stockType,
    int? isProduction,
    DateTime? addedAt,
    double? weight,
  }) {
    return CartItem(
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      serialId: serialId ?? this.serialId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      stockType: stockType ?? this.stockType,
      isProduction: isProduction ?? this.isProduction,
      addedAt: addedAt ?? this.addedAt,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'serialId': serialId,
        'product': product.toJson(),
        'quantity': quantity,
        'stockType': stockType,
        'isProduction': isProduction,
        'addedAt': addedAt.toIso8601String(),
        'dealerId': dealerId,
        'dealerName': dealerName,
        'weight': weight,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        serialId: json['serialId'] as int,
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        stockType: json['stockType'] as String,
        isProduction: json['isProduction'] as int,
        addedAt: DateTime.parse(json['addedAt'] as String),
        dealerId: json['dealerId'] as String,
        dealerName: json['dealerName'] as String,
        weight: (json['weight'] as num).toDouble(),
      );
}