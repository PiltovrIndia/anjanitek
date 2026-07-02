import 'dart:convert';
import 'dart:math';

import 'package:anjanitek/card_interactive.dart';
import 'package:anjanitek/modals/order_item.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
const String cartHomeRouteName = '/home';
const String cartScreenRouteName = '/anjanitek/cart';
final ShoppingCartRouteObserver shoppingCartRouteObserver =
    ShoppingCartRouteObserver();

// class CartProduct {
//   final String id;
//   final String design;
//   final String name;
//   final String size;
//   final String media;

//   const CartProduct({
//     required this.id,
//     required this.design,
//     required this.name,
//     required this.size,
//     required this.media,
//   });

//   factory CartProduct.fromProduct(dynamic product) {
//     final productId = product?.productId?.toString();
//     final design = product?.design?.toString() ?? '';
//     return CartProduct(
//       id: (productId != null && productId.isNotEmpty) ? productId : design,
//       design: design,
//       name: product?.name?.toString() ?? 'Design',
//       size: product?.size?.toString() ?? '',
//       media: product?.media?.toString().split(',').first ?? '',
//     );
//   }
// }

// class OrderItem {
//   final CartProduct product;
//   final int quantity;

//   const OrderItem({required this.product, required this.quantity});

//   OrderItem copyWith({int? quantity}) {
//     return OrderItem(
//       product: product,
//       quantity: quantity ?? this.quantity,
//     );
//   }
// }

class ShoppingCartController extends ChangeNotifier {
  final Map<String, OrderItem> _items = {};
  final Map<String, double> _productWeightCache = {};
  final Map<String, ProductTag> _boxWeightTagsById = {};
  bool _isCartScreenOpen = false;
  bool _hasBottomNavigation = false;
  double _bottomNavigationHeight = 0;
  String? _dealerId;
  bool _loadingWeightTags = false;

  List<OrderItem> get items => _items.values.toList(growable: false);

  int get itemCount => _items.length;

  int get totalQuantity => _items.values.fold(0, (total, item) => total + item.quantity);

  // this is showing 0 when we land first time on this screen because the weight tags are not loaded yet, we can show a loading indicator for the weight tags in the cart screen until they are loaded, and then show the total weight once they are loaded
  double get totalWeight => _items.values.fold( 0, (total, item) => total + (_getItemWeight(item) * item.quantity), );

  bool get isCartScreenOpen => _isCartScreenOpen;

  bool get hasBottomNavigation => _hasBottomNavigation;

  double get bottomNavigationHeight => _bottomNavigationHeight;

  bool get isLoadingWeightTags => _loadingWeightTags;

  bool contains(String id) => _items.containsKey(id);

  Future<void> ensureBoxWeightTagsLoaded() async {
    if (_boxWeightTagsById.isNotEmpty || _loadingWeightTags) return;

    _loadingWeightTags = true;

    try {
      final result = await http.get(
        Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U0", {})),
        headers: {"Accept": "application/json"},
      );
      final jsonObject = jsonDecode(result.body) as Map<String, dynamic>;
      if (jsonObject['status'] == 200) {
        final data = jsonObject['data'] as List<dynamic>;
        final tags = data
            .map((json) => ProductTag.fromJson(json as Map<String, dynamic>))
            .where((tag) => tag.type == 'BoxWeight' && tag.tagId != null)
            .toList();

        _boxWeightTagsById
          ..clear()
          ..addEntries(
            tags.map(
              (tag) => MapEntry(tag.tagId.toString(), tag),
            ),
          );
      }
    } catch (_) {
      // Ignore weight tag loading failures and keep the cart functional.
    } finally {
      _loadingWeightTags = false;
      notifyListeners();
    }
  }

  formatTotalWeightForDesignType(List<OrderItem> items) {
    double weightInKg = 0;
    for (var item in items) {
      // final itemWeight = shoppingCartController._getItemWeight(item);
      weightInKg += item.weight * item.quantity;
    }


    // final weightInKg = items.fold( 0, (total, item) => total + (item.weight * item.quantity), );

    if (weightInKg >= 1000) {
      final weightInTons = weightInKg / 1000;
      return '${weightInTons.toStringAsFixed(weightInTons % 1 == 0 ? 0 : 2)} ton';
    }

    if (weightInKg >= 1) {
      return '${weightInKg.toStringAsFixed(weightInKg % 1 == 0 ? 0 : 2)} kg';
    }

    final weightInGrams = weightInKg * 1000;
    return '${weightInGrams.toStringAsFixed(weightInGrams % 1 == 0 ? 0 : 2)} g';
  }

  double _getItemWeight(OrderItem item) {
    final productId = item.product.productId?.toString();
    if (productId != null && _productWeightCache.containsKey(productId)) {
      return _productWeightCache[productId] ?? 0;
    }
    print("Calculating weight for product ${item.product.name} (${item.product.productId}) with tags: ${item.product.tags}");

    final tagIds = item.product.tags
        ?.split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (tagIds == null || tagIds.isEmpty) {
      if (productId != null) {
        _productWeightCache[productId] = 0;
      }
      return 0;
    }

    for (final tagId in tagIds) {
      final tag = _boxWeightTagsById[tagId];
      final parsedWeight = _parseWeightValue(tag?.name);
      if (parsedWeight > 0) {
        if (productId != null) {
          _productWeightCache[productId] = parsedWeight;
        }
        return parsedWeight;
      }
    }

    if (productId != null) {
      _productWeightCache[productId] = 0;
    }
    return 0;
  }

  double _parseWeightValue(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return 0;
    }

    final normalized = rawValue.toLowerCase().trim();
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(normalized);
    if (match == null) {
      return 0;
    }

    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) {
      return 0;
    }

    if (normalized.contains('gm') || normalized.contains('gram')) {
      return value / 1000;
    }

    return value;
  }

  String formatTotalWeight() {
    final weightInKg = totalWeight;

    if (weightInKg >= 1000) {
      final weightInTons = weightInKg / 1000;
      return '${weightInTons.toStringAsFixed(weightInTons % 1 == 0 ? 0 : 2)} ton';
    }

    if (weightInKg >= 1) {
      return '${weightInKg.toStringAsFixed(weightInKg % 1 == 0 ? 0 : 2)} kg';
    }

    final weightInGrams = weightInKg * 1000;
    return '${weightInGrams.toStringAsFixed(weightInGrams % 1 == 0 ? 0 : 2)} g';
  }

  // void add(Product product, {int quantity = 1}) {
  void add(OrderItem orderItem) {
    final existing = _items[orderItem.product.productId.toString() + orderItem.stockType];

    _items[orderItem.product.productId.toString() + orderItem.stockType] = existing == null
        ? OrderItem(
            dealerId: orderItem.dealerId,
            dealerName: orderItem.dealerName,
            serialId: shoppingCartController.items.length + 1,
            product: orderItem.product,
            quantity: orderItem.quantity,
            stockType: orderItem.stockType,
            weight: orderItem.weight,
            productionQty: orderItem.productionQty,
          )
        : 
        // // we need also check the stockType for the existing item in the cart if its the same product is being added again with different stock type, we should treat it as a new item in the cart instead of merging the quantity, because the price might be different for different stock types for the same product
        // (existing != null && existing.stockType != orderItem.stockType) ?
        //   _items[orderItem.product.productId.toString() + orderItem.stockType] = OrderItem(
        //     dealerId: orderItem.dealerId,
        //     dealerName: orderItem.dealerName,
        //     serialId: shoppingCartController.items.length + 1,
        //     product: orderItem.product,
        //     quantity: orderItem.quantity,
        //     stockType: orderItem.stockType,
        //     isProduction: orderItem.isProduction,
        //   )
        // : 
        existing.copyWith(
            quantity: existing.quantity + orderItem.quantity,
            serialId: shoppingCartController.items.length + 1,
          );

    notifyListeners();
    _saveCart();
  }

  void increment(String id) {
    final item = _items[id];
    if (item == null) return;
    _items[id.toString()] = item.copyWith(
      quantity: item.quantity + 1,
      stockType: item.stockType,
      serialId: item.serialId,
    );
    notifyListeners();
    _saveCart();
  }

  void decrement(String id) {
    final item = _items[id];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(id.toString());
    } else {
      _items[id.toString()] = item.copyWith(
        quantity: item.quantity - 1,
        stockType: item.stockType,
        // serialId: shoppingCartController.items.length + 1,
        serialId: item.serialId,
      );
    }
    notifyListeners();
    _saveCart();
  }

  void remove(String id) {
    _items.remove(id.toString());
    notifyListeners();
    _saveCart();
  }

  void clear() {
    _items.clear();
    _productWeightCache.clear();
    notifyListeners();
    _saveCart();
  }

  void setCartScreenOpen(bool value) {
    if (_isCartScreenOpen == value) return;
    _isCartScreenOpen = value;
    notifyListeners();
  }

  void setBottomNavigationVisible(bool value) {
    if (_hasBottomNavigation == value) return;
    _hasBottomNavigation = value;
    notifyListeners();
  }

  void setBottomNavigationHeight(double value) {
    if ((_bottomNavigationHeight - value).abs() < 1) return;
    _bottomNavigationHeight = value;
    notifyListeners();
  }

  VoidCallback? _placeOrderCallback;

  void registerPlaceOrderCallback(VoidCallback callback) {
    _placeOrderCallback = callback;
  }

  void unregisterPlaceOrderCallback() {
    _placeOrderCallback = null;
  }

  void invokePlaceOrder() {
    _placeOrderCallback?.call();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  String get _storageKey => 'anjanitek_cart_$_dealerId';

  /// Call after login. Loads the cart that was last saved for [dealerId].
  Future<void> loadCart(String dealerId) async {
    _dealerId = dealerId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _items.clear();
      _productWeightCache.clear();
      for (final map in list) {
        final item = OrderItem.fromJson(map as Map<String, dynamic>);
        _items[item.product.productId.toString() + item.stockType] = item;
      }
      notifyListeners();
    } catch (_) {
      // corrupted data — start fresh
      await prefs.remove(_storageKey);
    }
  }

  /// Call on logout. Clears the in-memory cart without touching stored data.
  void unloadCart() {
    _dealerId = null;
    _items.clear();
    _productWeightCache.clear();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    if (_dealerId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_items.values.map((i) => i.toJson()).toList()),
    );
  }
}

final ShoppingCartController shoppingCartController = ShoppingCartController();

class ShoppingCartRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routeStack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.add(route);
    _syncBottomNavigationState();
    _syncCartScreenState();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _syncBottomNavigationState();
    _syncCartScreenState();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _syncBottomNavigationState();
    _syncCartScreenState();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      final index = _routeStack.indexOf(oldRoute);
      if (index >= 0) {
        if (newRoute != null) {
          _routeStack[index] = newRoute;
        } else {
          _routeStack.removeAt(index);
        }
      }
    } else if (newRoute != null) {
      _routeStack.add(newRoute);
    }
    _syncBottomNavigationState();
    _syncCartScreenState();
  }

  void _syncCartScreenState() {
    final isOnCart = _routeStack.any(
      (r) => r.settings.name == cartScreenRouteName,
    );
    shoppingCartController.setCartScreenOpen(isOnCart);
  }

  void _syncBottomNavigationState() {
    final topRoute = _routeStack.isEmpty ? null : _routeStack.last;
    shoppingCartController.setBottomNavigationVisible(
      topRoute?.settings.name == cartHomeRouteName,
    );
  }
}

class ShoppingCartOverlay extends StatelessWidget {
  final Widget child;

  const ShoppingCartOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedBuilder(
          animation: shoppingCartController,
          builder: (context, _) {
            if (shoppingCartController.itemCount == 0) {
              return const SizedBox.shrink();
            }

            final bottomInset = MediaQuery.paddingOf(context).bottom;
            final bottomOffset = shoppingCartController.hasBottomNavigation
                ? shoppingCartController.bottomNavigationHeight + 10
                : bottomInset + 16;

            return Positioned(
              left: 16,
              right: 16,
              bottom: bottomOffset,
              child: _CartFloatingPanel(
                itemCount: shoppingCartController.itemCount,
                totalQuantity: shoppingCartController.totalQuantity,
                isOnCartScreen: shoppingCartController.isCartScreenOpen,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A compact cart icon button with an item-count badge.
/// Place this directly in your custom app header.
/// Returns [SizedBox.shrink] when the cart is empty.
///
/// Example:
///   Row(children: [ ..., const CartHeaderButton() ])
// class CartHeaderButton extends StatelessWidget {
//   const CartHeaderButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: shoppingCartController,
//       builder: (context, _) {
//         final count = shoppingCartController.totalQuantity;
//         // if (count == 0) return const SizedBox.shrink();

//         return GestureDetector(
//           onTap: () => (count == 0) ? null : appNavigatorKey.currentState?.push(
//             MaterialPageRoute(builder: (_) => const ShoppingCartScreen()),
//           ),
//           child: Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF12B981).withValues(alpha: 0.12),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.shopping_bag_outlined,
//                   color: Color(0xFF048563),
//                   size: 22,
//                 ),
//               ),
//               Positioned(
//                 top: -4,
//                 right: -4,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF12B981),
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.white, width: 1.5),
//                   ),
//                   child: Text(
//                     count > 99 ? '99+' : '$count',
//                     style: GoogleFonts.inter(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w800,
//                       height: 1,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

class _CartFloatingPanel extends StatelessWidget {
  final int itemCount;
  final int totalQuantity;
  final bool isOnCartScreen;

  const _CartFloatingPanel({
    required this.itemCount,
    required this.totalQuantity,
    this.isOnCartScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return isOnCartScreen
        ? SizedBox.shrink()
        : Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Container(
                  //   width: 44,
                  //   height: 44,
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFF12B981),
                  //     borderRadius: BorderRadius.circular(14),
                  //   ),
                  //   child:
                  //       const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  // ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalQuantity box${totalQuantity == 1 ? '' : 'es'} in cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$itemCount design${itemCount == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                      onPressed: isOnCartScreen
                          ? shoppingCartController.invokePlaceOrder
                          : () => appNavigatorKey.currentState?.push(
                                MaterialPageRoute(
                                  settings: const RouteSettings(
                                    name: cartScreenRouteName,
                                  ),
                                  builder: (context) =>
                                      const ShoppingCartScreen(),
                                ),
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isOnCartScreen
                            ? const Color(0xFF12B981)
                            : Color(0xFF048563),
                        foregroundColor: isOnCartScreen
                            ? Colors.white
                            : const Color(0xFF101828),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        spacing: 4,
                        children: [
                          Text(
                            isOnCartScreen ? 'Place order' : 'View cart',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight02,
                            size: 16,
                            color: Colors.white,
                          )
                        ],
                      )),
                ],
              ),
            ),
          );
  }
}

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  static String id = '';
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    shoppingCartController.setCartScreenOpen(true);
    shoppingCartController.registerPlaceOrderCallback(_onPlaceOrder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      shoppingCartController.ensureBoxWeightTagsLoaded();
    });

    getUserData();
  }

  // get user details
  void getUserData() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Constants.name)) {
      setState(() {
        id = prefs.get(Constants.id) as String;
      });
    }
  }

  @override
  void dispose() {
    shoppingCartController.setCartScreenOpen(false);
    shoppingCartController.unregisterPlaceOrderCallback();
    super.dispose();
  }

  // void _onPlaceOrder() {

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Cart saved. Checkout integration can connect here.'),
  //     ),
  //   );
  // }

  bool reserving = false;

  void _onPlaceOrder() async {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    final randomSuffix = List.generate(
      1,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();

    var atlCartid = 'C$randomSuffix${DateTime.now().millisecondsSinceEpoch}';
    var vclCartid = 'C$randomSuffix${DateTime.now().millisecondsSinceEpoch + 1}';

    setState(() {
      reserving = true;
    });

    if (await checkInternetConnectivity()) {
      final createdOn = DateTime.now();
      // final expiryDate = DateTime.now();
      // final expiryDate = DateTime.now().add(const Duration(days: 2));
      final createdOnStr =
          "${createdOn.year.toString().padLeft(4, '0')}-${createdOn.month.toString().padLeft(2, '0')}-${createdOn.day.toString().padLeft(2, '0')} ${createdOn.hour.toString().padLeft(2, '0')}:${createdOn.minute.toString().padLeft(2, '0')}:${createdOn.second.toString().padLeft(2, '0')}";
      // final expiryStr = "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')} ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}:${expiryDate.second.toString().padLeft(2, '0')}";
      final requestBody = {
        'userId': id,
        'designs': shoppingCartController.items
            .map((item) => {
                  'dealerId': item.dealerId,
                  'cartId': (item.product.designType == 1) ? atlCartid : vclCartid,
                  'serialId': item.serialId,
                  'productId': item.product.productId,
                  'design': item.product.design,
                  'quantity': item.quantity,
                  'stockType': item.stockType,
                })
            .toList(),
        'createdOn': createdOnStr,
      };
// print(jsonEncode(requestBody));
      var result = await http.post(
        Uri.parse(
            APIUrls.getUrl("${APIUrls.orders}${APIUrls.pass}/U4", {})),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );
      print(result.body);
      Map jsonObject;
      try {
        jsonObject = jsonDecode(result.body) as Map;
      } catch (_) {
        setState(() {
          reserving = false;
        });
        showToast(
            context,
            'Server error (${result.statusCode}). Try again later.',
            Constants.error);
        return;
      }

      if (jsonObject['status'] == 200) {
        int insertedCount = jsonObject['data'] as int;
        if (insertedCount > 0) {
          // deduct the stock locally ------ NOT Required as per new logic
          // if(selectedStockType == 'prm'){
          //   setState(() {
          //     widget.product.prm = (widget.product.prm is int ? widget.product.prm :
          //       int.tryParse('${widget.product.prm ?? 0}') ?? 0) - totalRequestedQuantity;
          //   });
          // }
          // else if(selectedStockType == 'std'){
          //   setState(() {
          //     widget.product.std = (widget.product.std is int ? widget.product.std :
          //       int.tryParse('${widget.product.std ?? 0}') ?? 0) - totalRequestedQuantity;
          //   });
          // }

          // clear the cart
          shoppingCartController.clear();

          setState(() {
            reserving = false;
          });
          // user is not active, logout the user
          showToast(
              context,
              'Your Stock Order is sent!\nOur team will contact you.',
              Constants.success);

          Navigator.of(context)
              .popUntil((route) => route.settings.name == cartHomeRouteName);
        }
      } else {
        setState(() {
          reserving = false;
        });
        showToast(context, 'Error occurred! Try again later.', Constants.error);
      }
    } else {
      setState(() {
        reserving = false;
      });
      showToast(context, 'No connection. Try again later!', Constants.warning);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF7F8FA),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Cart' ,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        // backgroundColor: const Color(0xFFF7F8FA),
        // foregroundColor: const Color(0xFF101828),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: shoppingCartController,
            builder: (context, _) {
              if (shoppingCartController.itemCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: shoppingCartController.clear,
                child: const Text('Clear'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: shoppingCartController,
          builder: (context, _) {
            final items = shoppingCartController.items;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/emptytruck.webp', width: 150.0),
                      Text(
                        'Your truck is empty',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Browse and add designs with required stock.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (_) {
                      // final reservationItems = items.where((i) => i.isProduction == 0).toList();
                      final reservationItems = items;

                      final tiles = <Widget>[];

                      // Widget buildGroupHeader(String label) {
                      //   return Padding(
                      //     padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                      //     child: Row(
                      //       children: [
                      //         Text(
                      //           label,
                      //           style: GoogleFonts.inter(
                      //             fontWeight: FontWeight.w800,
                      //             fontSize: 13,
                      //             color: const Color(0xFF667085),
                      //             letterSpacing: 0.4,
                      //           ),
                      //         ),
                      //         const SizedBox(width: 8),
                      //         const Expanded(
                      //           child: Divider(
                      //             color: Color(0xFFE5E7EB),
                      //             thickness: 1,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   );
                      // }

                      Widget buildDesignTypeHeader(String label, List<OrderItem> group, Color accent) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                          child: 
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    // lets show the total weight for the design type in the header as well, so that user can have an idea about the weight distribution in the cart
                                    label + (label == 'ATL DESIGNS' ? '' : ' • ' + shoppingCartController.formatTotalWeightForDesignType(group)),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.black,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              // '${shoppingCartController.itemCount} design${shoppingCartController.itemCount == 1 ? '' : 's'} • ${shoppingCartController.totalQuantity} box${shoppingCartController.totalQuantity == 1 ? '' : 'es'}',
                              Text(
                                '${group.length} design${group.length == 1 ? '' : 's'} • ${group.fold(0, (total, item) => total + item.quantity)} box${group.fold(0, (total, item) => total + item.quantity) == 1 ? '' : 'es'}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                            ]
                          )
                        );
                      }

                      void addDesignTypeGroup(
                        String label,
                        List<OrderItem> group,
                        Color accent,
                        Color? backgroundTint,
                      ) {
                        if (group.isEmpty) {
                          return;
                        }

                        final sectionChildren = <Widget>[
                          buildDesignTypeHeader(label, group, accent),
                        ];

                        for (var i = 0; i < group.length; i++) {
                          if (i > 0) {
                            sectionChildren.add(const SizedBox(height: 12));
                          }
                          sectionChildren.add(_OrderItemTile(item: group[i]));
                        }

                        tiles.add(
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            decoration: BoxDecoration(
                              color: backgroundTint,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: sectionChildren,
                            ),
                          ),
                        );
                      }

                      void addGroup(String label, List<OrderItem> group) {
                        final atlItems = group
                            .where((i) => i.product.designType == 1)
                            .toList();
                        final vclItems = group
                            .where((i) => i.product.designType == 2)
                            .toList();
                        final otherItems = group
                            .where((i) =>
                                i.product.designType != 1 &&
                                i.product.designType != 2)
                            .toList();

                        // tiles.add(buildGroupHeader(label));
                        addDesignTypeGroup(
                          'ATL DESIGNS',
                          atlItems,
                          const Color(0xFFFF5252),
                          const Color(0xFFFFE3E3),
                        );
                        if (atlItems.isNotEmpty &&
                            (vclItems.isNotEmpty || otherItems.isNotEmpty)) {
                          tiles.add(const SizedBox(height: 14));
                        }
                        addDesignTypeGroup(
                          'VCL DESIGNS',
                          vclItems,
                          const Color(0xFFC41306),
                          const Color(0xFFFFCECB),
                        );
                        if (vclItems.isNotEmpty && otherItems.isNotEmpty) {
                          tiles.add(const SizedBox(height: 14));
                        }
                        addDesignTypeGroup(
                          'OTHER DESIGNS',
                          otherItems,
                          const Color(0xFF667085),
                          null,
                        );
                      }

                      // if (productionItems.isNotEmpty) {
                      //   addGroup('PRODUCTION', productionItems);
                      // }
                      if (reservationItems.isNotEmpty) {
                        // if (productionItems.isNotEmpty) {
                        //   tiles.add(const SizedBox(height: 8));
                        // }
                        addGroup('CURRENT ORDER', reservationItems);
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: tiles,
                      );
                    },
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                //   child: 
                //   Container(
                //     width: double.infinity,
                //     padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                //     decoration: BoxDecoration(
                //       color: const Color(0xFFF8FAFC),
                //       borderRadius: BorderRadius.circular(18),
                //       border: Border.all(color: const Color(0xFFE5E7EB)),
                //     ),
                //     child: Row(
                //       children: [
                //         Text('Weight: ',
                //               style: GoogleFonts.inter(
                //                 fontSize: 12,
                //                 fontWeight: FontWeight.w800,
                //                 color: Colors.black87,
                //               ),
                //             ),
                //             Expanded(
                //           child: 
                //         Text(
                //           shoppingCartController.formatTotalWeight(),
                //               style: GoogleFonts.inter(
                //                 fontSize: 16,
                //                 fontWeight: FontWeight.w800,
                //                 color: const Color(0xFF048563),
                //               ),
                //             ),
                //             ),
                //         Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Text( 
                //                 '${shoppingCartController.itemCount} design${shoppingCartController.itemCount == 1 ? '' : 's'} • ${shoppingCartController.totalQuantity} box${shoppingCartController.totalQuantity == 1 ? '' : 'es'}',
                //                 style: GoogleFonts.inter(
                //                   fontSize: 14,
                //                   fontWeight: FontWeight.w600,
                //                   color: const Color(0xFF101828),
                //                 ),
                //               ),
                //               // const SizedBox(height: 4),
                //               // Text(
                //               //   '${shoppingCartController.itemCount} design${shoppingCartController.itemCount == 1 ? '' : 's'} • ${shoppingCartController.totalQuantity} item${shoppingCartController.totalQuantity == 1 ? '' : 's'}',
                //               //   style: GoogleFonts.inter(
                //               //     fontSize: 12,
                //               //     color: const Color(0xFF667085),
                //               //   ),
                //               // ),
                //             ],
                //           ),
                        
                        
                //         // Column(
                //         //   crossAxisAlignment: CrossAxisAlignment.end,
                //         //   spacing: 2,
                //         //   children: [
                //         //     Text(
                //         //       'Total weight',
                //         //       style: GoogleFonts.inter(
                //         //         fontSize: 12,
                //         //         fontWeight: FontWeight.w600,
                //         //         color: const Color(0xFF667085),
                //         //       ),
                //         //     ),
                //         //     Text(
                //         //       '${shoppingCartController.totalWeight.toStringAsFixed(shoppingCartController.totalWeight % 1 == 0 ? 0 : 2)} kg',
                //         //       style: GoogleFonts.inter(
                //         //         fontSize: 16,
                //         //         fontWeight: FontWeight.w800,
                //         //         color: const Color(0xFF048563),
                //         //       ),
                //         //     ),
                //         //   ],
                //         // ),
                //       ],
                //     ),
                //   ),
                // ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 4,
                      children: [
                        (shoppingCartController.items.any((element) =>
                                    element.product.designType == 1) &&
                                shoppingCartController.items.any((element) =>
                                    element.product.designType == 2))
                            ? Text(
                                '2 Separate orders will be placed for ATL and VCL designs.',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.black45),
                              )
                            : sizedBox(0),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                                onPressed: reserving
                                    ? null
                                    : () => {
                                          HapticFeedback.selectionClick(),
                                          _onPlaceOrder(),
                                        },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  backgroundColor: Color(0xFF048563),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  disabledBackgroundColor:
                                      const Color(0xFF048563),
                                  disabledForegroundColor: Colors.white,
                                ),
                                icon: reserving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                                label: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 4,
                                    children: [
                                      Text(
                                        reserving
                                            ? 'Placing order...'
                                            : 'Place order'.toUpperCase(),
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white),
                                      ),
                                      Text(
                                        'for ${shoppingCartController.items.first.dealerName}',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12),
                                      ),
                                    ])))
                      ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final mediaUrl = item.product.media!.isEmpty
        ? null
        : 'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/products%2F${item.product.media}.webp?alt=media';

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mediaUrl != null
              ? SizedBox(
                  width: 94,
                  height: 94,
                  child: CardInteractive(
                      design: item.product.design!,
                      media: item.product.media!.split(',')[0],
                      imageHeight: 94,
                      imageWidth: 94,
                      zoom: 1))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                      width: 44,
                      height: 44,
                      color: const Color(0xFFF2F4F7),
                      child: const Icon(Icons.image_outlined,
                          color: Color(0xFF98A2B3)))),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(14),
          //   child: Container(
          //     width: 94,
          //     height: 94,
          //     color: const Color(0xFFF2F4F7),
          //     child: mediaUrl == null
          //         ? const Icon(Icons.image_outlined, color: Color(0xFF98A2B3))
          //         :
          //         CardInteractive(design: item.product.design!, media: item.product.media!.split(',')[0],  imageHeight: 64, imageWidth: 64, zoom:1),
          //         // CardInteractive(design: item.product.design!, media: item.product.media!.split(',')[0],  imageHeight: double.parse(item.product.size!.split('x')[1]), imageWidth: double.parse(item.product.size!.split('x')[0]), zoom:2),
          //         // Image.network(
          //         //     mediaUrl,
          //         //     fit: BoxFit.cover,
          //         //     errorBuilder: (_, __, ___) => const Icon(
          //         //       Icons.image_outlined,
          //         //       color: Color(0xFF98A2B3),
          //         //     ),
          //         //   ),
          //   ),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  item.product.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [item.product.design, item.product.size]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    item.stockType.toUpperCase(),
                    item.product.designType == 1
                        ? 'ATL'
                        : item.product.designType == 2
                            ? 'VCL'
                            : ''
                  ].where((value) => value.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () => shoppingCartController
                          .decrement(item.product.productId!.toString() + item.stockType.toString()),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () => shoppingCartController
                          .increment(item.product.productId!.toString() + item.stockType.toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                shoppingCartController.remove(item.product.productId!.toString() + item.stockType.toString()),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: Color(0xFF98A2B3)),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }
}
