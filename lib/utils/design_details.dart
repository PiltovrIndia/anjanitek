// lib/utils/product_details.dart
import 'dart:convert';
import 'dart:math';

import 'package:anjanitek/card_interactive.dart';
import 'package:anjanitek/modals/order_item.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/users.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/database_helper.dart';
import 'package:anjanitek/utils/dotted_line.dart';
import 'package:anjanitek/utils/shimmer_text.dart';
import 'package:anjanitek/utils/shopping_cart.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:anjanitek/widgets/dealer_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:http/http.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full screen design details page. Accepts dynamic design and a list of designTags
/// so it can be dropped into an existing project without forcing model imports.
/// It expects the design to expose fields used below (name, description, tags, design, media, size)
/// and each tag to expose (tagId, type, name, description) like in your original code.
///

class DesignDetails extends StatefulWidget {
  // final List<int> alreadySelectedTagIds;
  final dynamic product;
  final List<dynamic> productTags;
  DesignDetails(
      {required this.product, required this.productTags, super.key});

  @override
  _DesignDetailsState createState() => _DesignDetailsState();
}

class _DesignDetailsState extends State<DesignDetails> {
// class DesignDetails extends StatelessWidget {

  bool reserving = false;
  static String name = '',
      id = '',
      role = 'Guest',
      cartDealerId = '',
      mapMobile = '',
      cartDealerName = '';
  late SharedPreferences prefs;
  DatabaseHelper dbHelper = DatabaseHelper();

  // const DesignDetails({
  //   Key? key,
  //   required this.product,
  //   required this.productTags,
  // }) : super(key: key);

  @override
  void initState() {
    super.initState();

    getUserData();
  }

  // get user details
  void getUserData() async {
    await dbHelper.initDb();
    prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Constants.name)) {
      setState(() {
        id = prefs.get(Constants.id) as String;
        name = prefs.get(Constants.name) as String;
        role = prefs.get(Constants.role) as String;
        mapMobile = prefs.getString(Constants.mapMobile) ?? '';
      });
    }
  }

  String get _activeDealerId {
    if (shoppingCartController.items.isNotEmpty &&
        shoppingCartController.items.first.dealerId.isNotEmpty) {
      return shoppingCartController.items.first.dealerId;
    }
    return cartDealerId;
  }
  String get _activeDealerName {
    if (shoppingCartController.items.isNotEmpty &&
        shoppingCartController.items.first.dealerName.isNotEmpty) {
      return shoppingCartController.items.first.dealerName;
    }
    return cartDealerName;
  }

  String get _activeDealerLabel {
    if (_activeDealerName.isNotEmpty) {
      return _activeDealerName;
    }
    if (_activeDealerId.isNotEmpty) {
      return _activeDealerId;
    }
    return '';
  }

  Future<void> _handleOrderFlow(
    BuildContext context,
    int premiumStock,
    int standardStock,
    
  ) async {
    HapticFeedback.selectionClick();

    final canProceed = await _ensureDealerSelected(context);
    if (!canProceed || !mounted) {
      return;
    }

    _showReservationSheet(context, premiumStock, standardStock);
  }

  Future<bool> _ensureDealerSelected(BuildContext context) async {
    if (role.toLowerCase() == Constants.dealer.toLowerCase()) {
      return true;
    }

    if (id.isEmpty) {
      showToast(
        context,
        'Your account details are still loading. Try again in a moment.',
        Constants.warning,
      );
      return false;
    }

    final currentCartDealerId = _activeDealerId;
    final currentCartDealerName = _activeDealerName;
    if (currentCartDealerId.isNotEmpty) {
      if (cartDealerId != currentCartDealerId) {
        setState(() {
          cartDealerId = currentCartDealerId;
          cartDealerName = currentCartDealerName;
        });
      }
      return true;
    }

    final dealer = await _showDealerSelectionSheet(context);
    if (dealer == null || (dealer.id?.isEmpty ?? true) || !mounted) {
      return false;
    }

    setState(() {
      cartDealerId = dealer.id!;
      cartDealerName = dealer.name ?? '';
    });
    return true;
  }

  Future<Users?> _showDealerSelectionSheet(BuildContext context) async {
    return showModalBottomSheet<Users>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DealerSelectionSheet(
          role: role,
          adminId: id,
          activeDealerLabel: _activeDealerLabel,
          hasActiveDealer: _activeDealerId.isNotEmpty,
        );
      },
    );
  }

  Future<Users?> _showAddCustomerSheet(BuildContext context) async {
    return showModalBottomSheet<Users>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddCustomerSheet(
          adminId: id,
          requesterRole: role,
          onCreateCustomer: _createCustomer,
        );
      },
    );
  }

  String _generateCustomerId() {
    final random = Random();
    final randomDigits = random.nextInt(90000) + 10000;
    return 'C$randomDigits';
  }

  Future<Users?> _createCustomer({
    required String customerName,
    required String mobileNumber,
    required String emailAddress,
  }) async {
    final trimmedName = customerName.trim();
    final trimmedMobile = mobileNumber.trim();
    final trimmedEmail = emailAddress.trim();

    final newCustomer = {
      'id': _generateCustomerId(),
      'name': trimmedName,
      'designation': 'Customer',
      'email': trimmedEmail,
      'mobile': trimmedMobile,
      'role': 'Customer',
      'mapTo': id,
      'relatedTo': id,
      'userImage': '-',
      'gcm_regId': '-',
      'isActive': 1,
    };

    final result = await post(
      Uri.parse(
        APIUrls.getUrl(
          '${APIUrls.user}${APIUrls.pass}/U11/$role',
          {},
        ),
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(newCustomer),
    );
    
    final jsonObject = jsonDecode(result.body) as Map;
    if (jsonObject['status'] != 200) {
      throw Exception(jsonObject['message'] ?? 'Unable to create customer.');
    }

    return Users(
      id: newCustomer['id'] as String,
      name: newCustomer['name'] as String,
      designation: newCustomer['designation'] as String,
      email: newCustomer['email'] as String,
      mobile: newCustomer['mobile'] as String,
      role: newCustomer['role'] as String,
      mapTo: newCustomer['mapTo'] as String,
      userImage: newCustomer['userImage'] as String,
      gcmRegId: newCustomer['gcm_regId'] as String,
      isActive: newCustomer['isActive'] as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final _FallbackTag defaultTag = _FallbackTag(description: 'FFFFFF', name: 'Unknown', type: '');

    // var colorTag = productTags.firstWhere((tag) => filteredProducts[index].tags?.split(',').contains(tag.tagId.toString()) == true && tag.type == 'Color', orElse: () => ProductTag(description: 'FFFFFF'));
    //                   return Color(int.parse('0xFF${colorTag.description ?? 'FFFFFF'}'))
    final colorTag = widget.productTags.firstWhere(
      (tag) =>
          (widget.product?.tags
                  ?.toString()
                  .split(',')
                  .contains(tag.tagId?.toString()) ??
              false) &&
          (tag.type == 'Color'),
      orElse: () => ProductTag(description: 'FFFFFF'),
    );

    Color backgroundColor;
    try {
      final hex = (colorTag.description ?? 'FFFFFF').replaceAll('#', '');
      backgroundColor = Color(int.parse('0x22$hex'));
    } catch (_) {
      backgroundColor = const Color(0x22000000);
    }

    // safe parsing for image size
    double getImageHeight() {
      try {
        final size = widget.product?.size?.toString() ?? '';
        final parts = size.split('x');
        if (parts.length == 2) return double.parse(parts[1]);
      } catch (_) {}
      return MediaQuery.of(context).size.height * 0.5;
    }

    double getImageWidth() {
      try {
        final size = widget.product?.size?.toString() ?? '';
        final parts = size.split('x');
        if (parts.length == 2) return double.parse(parts[0]);
      } catch (_) {}
      return MediaQuery.of(context).size.width * 0.6;
    }

    final mediaFirst = widget.product?.media?.toString().split(',').first ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product?.name ?? 'Product',
          style: GoogleFonts.inter(
              textStyle: Theme.of(context).textTheme.bodyLarge,
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Transform.rotate(
                    angle: -0.1,
                    child: _buildInteractiveCard(
                        context, mediaFirst, getImageHeight(), getImageWidth(), widget.product),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    widget.product?.name ?? 'No Name',
                    style: GoogleFonts.inter(
                      textStyle: Theme.of(context).textTheme.headlineMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    child:
                        Text(
                          (widget.product?.designType == 1) ? 'ATL' : 'VCL',
                          style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                              color: (widget.product?.designType == 1) ? Color(0xFFFF5252) : Color(0xFFC41306),
                              fontWeight: FontWeight.bold
                              ),
                        )
                    ),
                    Text(
                      widget.product?.design ?? '',
                      style: GoogleFonts.robotoMono(
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.product?.description.length > 2
                        ? widget.product?.description
                        : '',
                    style: GoogleFonts.inter(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                // show stock values
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: [
                //     Text('Premium stock: ${widget.product?.prm ?? 'N/A'}',
                //         style: GoogleFonts.inter(
                //             textStyle: Theme.of(context).textTheme.bodyLarge,
                //             fontWeight: FontWeight.w600)),
                //     const SizedBox(width: 24),
                //     Text('Standard stock: ${widget.product?.std ?? 'N/A'}',
                //         style: GoogleFonts.inter(
                //             textStyle: Theme.of(context).textTheme.bodyLarge,
                //             fontWeight: FontWeight.w600)),
                //   ],
                // ),

                role == Constants.guest
                    ? const SizedBox(
                        height: 0,
                      )
                    : _buildReservationFlow(context),

                // const SizedBox(height: 16),
                // _buildCartAction(context),
                const SizedBox(height: 16),
                _buildTagsSection(context),
                const SizedBox(height: 64),

                // show reserve button which will prompt the user to select stock type and quantity and then confirm reservation
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildCartAction(BuildContext context) {
  //   final orderItem = OrderItem(
  //     product: widget.product,
  //     quantity: 1,
  //     addedAt: DateTime.now(),
  //   );

  //   return AnimatedBuilder(
  //     animation: shoppingCartController,
  //     builder: (context, _) {
  //       final alreadyInCart = shoppingCartController.contains(widget.product.productId.toString());
  //       return SizedBox(
  //         width: double.infinity,
  //         child: OutlinedButton.icon(
  //           onPressed: () {
  //             shoppingCartController.add(orderItem);
  //             showToast(
  //               context,
  //               alreadyInCart
  //                   ? 'Added one more to your cart.'
  //                   : 'Design added to your cart.',
  //               Constants.success,
  //             );
  //           },
  //           style: OutlinedButton.styleFrom(
  //             padding: const EdgeInsets.symmetric(vertical: 15),
  //             foregroundColor: const Color(0xFF101828),
  //             side: const BorderSide(color: Color(0xFF101828)),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(14),
  //             ),
  //           ),
  //           icon: Icon(
  //             alreadyInCart
  //                 ? Icons.add_shopping_cart
  //                 : Icons.shopping_bag_outlined,
  //           ),
  //           label: Text(
  //             alreadyInCart ? 'Add another to cart' : 'Add to cart',
  //             style: GoogleFonts.inter(fontWeight: FontWeight.w800),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void reserveTheStock(
      int totalRequestedQuantity, String selectedStockType) async {
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

      // print("${APIUrls.reservations}${APIUrls.pass}/U4/$id/${widget.product.design}/$totalRequestedQuantity/$selectedStockType/$createdOnStr");
      var result = await get(
        Uri.parse(APIUrls.getUrl(
            "${APIUrls.reservations}${APIUrls.pass}/U4/$id/${widget.product.design}/$totalRequestedQuantity/$selectedStockType/$createdOnStr",
            {})),
        headers: {"Accept": "application/json"},
      );
      // print(result.body);
      var jsonString = jsonDecode(result.body);
      var jsonObject = jsonString as Map;

      if (jsonObject['status'] == 200) {
        int createdId = jsonObject['data'] as int;
        if (createdId > 0) {
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

          setState(() {
            reserving = false;
          });
          // user is not active, logout the user
          showToast(
              context,
              'Your Stock Reservation is sent!\nOur team will contact you.',
              Constants.success);
        }
      } else {
        setState(() {
          reserving = false;
        });
        showToast(context, 'Stock Reservation failed! Try again later.',
            Constants.error);
      }
    } else {
      setState(() {
        reserving = false;
      });
      showToast(context, 'No connection. Try again later!', Constants.warning);
    }
  }

  Future<void> _callSalesPerson(BuildContext context) async {
    final rawContact = mapMobile;
    if (rawContact.isEmpty) {
      showToast(context, 'Sales contact not available.', Constants.warning);
      return;
    }

    final cleaned = rawContact.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    showToast(context, 'Unable to place call right now.', Constants.error);
  }

  Widget _buildInteractiveCard(BuildContext context, String mediaFirst,
      double imageHeight, double imageWidth, Product product) {
    // CardInteractive is referenced from original code. Keep call as-is; if your project
    // has a different widget name, replace it here.
    try {
      return 
      // CardInteractive(
      //   design: widget.product?.design,
      //   media: mediaFirst,
      //   imageHeight: imageHeight,
      //   imageWidth: imageWidth,
      //   zoom: 2,
      // );
      CardInteractive(
              design: product.design!,
              media: product.media!.split(',')[0],
              imageHeight: double.parse(product.size!.split('x')[1]),
              imageWidth: double.parse(product.size!.split('x')[0]),
              zoom: 2,
              productSize: product.size,
            );
    } catch (_) {
      // Fallback placeholder if CardInteractive is not available at runtime.
      return Container(
        height: imageHeight,
        width: imageWidth,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 48, color: Colors.black26),
      );
    }
  }

  Widget _buildTagsSection(BuildContext context) {
    final rawTags = widget.product?.tags?.toString();
    if (rawTags == null || rawTags.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0)),
        child: Text('No Tags',
            style: GoogleFonts.inter(
                textStyle: Theme.of(context).textTheme.bodyLarge)),
      );
    }

    final tagIds = rawTags.split(',');
    final tagWidgets = tagIds.map((tagId) {
      final tag = widget.productTags.firstWhere(
        (t) => t.tagId?.toString() == tagId,
        orElse: () => ProductTag(description: 'FFFFFF'),
      );
      // ignore the tag BoxWeight if (widget.product?.designType == 1)
      return 
      ((tag.name == 'BoxWeight' || tag.type == 'BoxWeight') && widget.product?.designType == 1) ?
      
      sizedBox(0) :
       Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tag.type ?? ''}: ${tag.name ?? 'Unknown'}',
                style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.bodyMedium)),
            const SizedBox(height: 8),
            DottedLine(),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tagWidgets,
    );
  }

  Widget _buildReservationFlow(BuildContext context) {
    final int premiumStock = widget.product?.prm is int
        ? widget.product?.prm ?? 0
        : int.tryParse('${widget.product?.prm ?? 0}') ?? 0;
    final int standardStock = widget.product?.std is int
        ? widget.product?.std ?? 0
        : int.tryParse('${widget.product?.std ?? 0}') ?? 0;
    final bool hasInventory = premiumStock > 0 || standardStock > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StockCount(label: 'Premium', value: premiumStock),
              const SizedBox(width: 12),
              _StockCount(label: 'Standard', value: standardStock),
            ],
          ),
          sizedBox(12),
          if (role.toLowerCase() == Constants.dealer.toLowerCase())
            if (mapMobile.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _callSalesPerson(context);
                  },
                  style: ElevatedButton.styleFrom(
                    maximumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF0246A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: Text(
                    'Call Sales person',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              sizedBox(0)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E7E1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F4EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.userCircle,
                          color: Color(0xFF0C6B54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            (_activeDealerId.isNotEmpty) ?
                            Text(
                              'Ordering for',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            )
                            :
                            (role.toLowerCase() != Constants.staff.toLowerCase()) ?
                            Text(
                              'Select Dealer',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            )
                            :
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0C6B54),
                                
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: const Color(0xFF0C6B54)),
                                )
                              ),
                              onPressed: 
                              // open a bottomsheet to add new customer with Name, mobile as details and call API on submit and return the value to populate the dealer details and select that dealer for current order flow
                              () async {
                                final newDealer = await _showAddCustomerSheet(context);
                                if (newDealer == null || newDealer.id?.isEmpty == true || !mounted) {
                                  return;
                                }
                                setState(() {
                                  cartDealerId = newDealer.id!;
                                  cartDealerName = newDealer.name ?? '';
                                });
                              },
                              child: Text(
                                'Add Customer',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _activeDealerLabel.isNotEmpty ? const SizedBox(height: 8) : sizedBox(0),
                            
                            _activeDealerLabel.isNotEmpty ?
                            Text(
                              _activeDealerLabel,
                              // _activeDealerId.isNotEmpty
                              //     ? 'This dealer will be used for the current cart.'
                              //     : 'Pick a dealer once and the order flow will continue automatically.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            )
                            : sizedBox(0),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C6B54),
                          
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: const Color(0xFF0C6B54)),
                          )
                        ),
                        onPressed: shoppingCartController.items.isNotEmpty
                            ? null
                            : () async {
                              
                                final dealer = await _showDealerSelectionSheet(context);
                                if (dealer == null || (dealer.id?.isEmpty ?? true) || !mounted) {
                                  return;
                                }
                                setState(() {
                                  cartDealerId = dealer.id!;
                                  cartDealerName = dealer.name ?? '';
                                });
                              },
                        child: Text(
                          _activeDealerId.isNotEmpty ? 'Change' : 'Search',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: reserving
                      ? ShimmerText(
                          text: 
                          // hasInventory ? 'Reserving...' : 
                          'Requesting...',
                          style: GoogleFonts.inter(
                            textStyle: Theme.of(context).textTheme.bodyLarge,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: 
                              // hasInventory ? 
                              () async {
                                      await _handleOrderFlow(
                                        context,
                                        premiumStock,
                                        standardStock,
                                      );
                                    },
                                  // : null,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: 
                                // hasInventory ? 
                                const Color(0xFF048563),
                                    // : const Color(0xFFAF4B03),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                              ),
                              icon: 
                              // hasInventory ? 
                                  const Icon(
                                      PhosphorIconsRegular.plus,
                                      color: Colors.white,
                                    ),
                                  // : null,
                              label: Text(
                                // hasInventory ? 
                                'Add to cart', 
                                // : 'Out of stock',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            // ElevatedButton.icon(
                            //   onPressed: () async {
                            //     await _handleOrderFlow(
                            //       context,
                            //       premiumStock,
                            //       standardStock,
                            //       1,
                            //     );
                            //   },
                            //   style: ElevatedButton.styleFrom(
                            //     padding:
                            //         const EdgeInsets.symmetric(vertical: 14),
                            //     backgroundColor: const Color(0xFFAF4B03),
                            //     foregroundColor: Colors.white,
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(12),
                            //     ),
                            //     disabledBackgroundColor: Colors.grey.shade300,
                            //     disabledForegroundColor: Colors.grey.shade600,
                            //   ),
                            //   icon: const HugeIcon(
                            //     icon: HugeIcons.strokeRoundedShippingTruck01,
                            //     color: Colors.white,
                            //   ),
                            //   label: Text(
                            //     'Future order',
                            //     style: GoogleFonts.inter(
                            //         fontWeight: FontWeight.w600),
                            //   ),
                            // ),
                          ],
                        ),
                ),
              ],
            ),

          // const SizedBox(height: 8),
          // role.toLowerCase() != Constants.dealer.toLowerCase() ? const SizedBox(height: 0,)
          // : SizedBox(
          //   width: double.infinity,
          //   child:
          //   reserving ? ShimmerText(text: hasInventory ? 'Reserving...' : 'Requesting...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), )
          //   : ElevatedButton.icon(
          //     onPressed:
          //     // hasInventory
          //     //     ?
          //         () => {
          //           // add haptic feedback of tap
          //         HapticFeedback.selectionClick(),
          //         _showReservationSheet(context, premiumStock, standardStock) },
          //         // : null,
          //     style: ElevatedButton.styleFrom(
          //       padding: const EdgeInsets.symmetric(vertical: 14),
          //       backgroundColor: hasInventory ? Color(0xFF048563) : Color(0xFFFF9E0C),
          //       foregroundColor: Colors.white,
          //       shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(12)),
          //       disabledBackgroundColor: Colors.grey.shade300,
          //       disabledForegroundColor: Colors.grey.shade600,
          //     ),
          //     icon: const Icon(PhosphorIconsRegular.checkSquareOffset, color: Colors.white,),
          //     label: Text(
          //       hasInventory ? 'Reserve for future' : 'Request stock',
          //       style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _showReservationSheet(BuildContext context, int premiumStock, int standardStock) {
    // if ((premiumStock <= 0) && (standardStock <= 0)) return;
    int totalRequestedQuantity = 1;
    int requestedReserveQty = 0;
    // int requestedProduceQty = 0;

    // String selectedStockType = premiumStock > 0 ? 'prm' : 'std';
    String selectedStockType = 'prm';
    TextEditingController qtyController = TextEditingController(text: '1');
    int clampQty(int qty, int available) {
      if (available <= 0) return qty;
      if (qty < 1) return 1;
      if (qty > available) return available;
      return qty;
    }

    showModalBottomSheet(
        context: context,
        useSafeArea: true,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                qtyController.text = '$totalRequestedQuantity';
                final int maxQty =
                    selectedStockType == 'prm' ? premiumStock : standardStock;

                // totalRequestedQuantity = clampQty(totalRequestedQuantity, maxQty);
                totalRequestedQuantity = totalRequestedQuantity;

                requestedReserveQty = totalRequestedQuantity - maxQty > 0
                        ? maxQty
                        : totalRequestedQuantity;
                // requestedProduceQty = 1;

                final bool canReserve = maxQty > 0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Stock details',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // isFutureOrder == 0 ?
                    // Text(
                    //   (premiumStock > 0 || standardStock > 0)
                    //       ? 'Lock inventory instantly before it runs out. Click below to select stock type and quantity.'
                    //       : 'Inventory is unavailable right now. Click below to Request Production of stock',
                    //   style: GoogleFonts.inter(color: Colors.black54),
                    // ) : Text(
                    //   'Select Premium quantity you want to order for future delivery.',
                    //   style: GoogleFonts.inter(color: Colors.black54),
                    // ),

                    // const SizedBox(height: 16),
                    Text(
                            'Stock type',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                    
                    sizedBox(8),
                    
                    Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StockCount(
                                label: 'Premium',
                                value: premiumStock,
                                isSelected: selectedStockType == 'prm',
                                onTap: () => setSheetState(() {
                                  selectedStockType = 'prm';
                                  // totalRequestedQuantity = totalRequestedQuantity;
                                  totalRequestedQuantity = clampQty(
                                      totalRequestedQuantity, premiumStock);
                                }),
                              ),
                              const SizedBox(width: 12),
                              _StockCount(
                                label: 'Standard',
                                value: standardStock,
                                isSelected: selectedStockType == 'std',
                                onTap: standardStock == 0
                                    ? null
                                    : () => setSheetState(() {
                                          selectedStockType = 'std';
                                          totalRequestedQuantity = clampQty(
                                              totalRequestedQuantity,
                                              standardStock);
                                        }),
                              ),
                            ],
                          ),
                          
                    sizedBox(24),
                    Text(
                      '${selectedStockType == 'prm' ? 'Premium' : 'Standard'} Quantity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '1',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      controller: qtyController,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          // capping for just standard and unlimited for premium as per new logic
                          // but I am making it stay uniform
                          print('Parsed quantity: $parsed');
                          setSheetState(() {
                            totalRequestedQuantity = (selectedStockType == 'std' ? clampQty(parsed, standardStock) : parsed);
                            print('Clamped quantity: $totalRequestedQuantity');
                          });
                          // setSheetState(() {
                            // totalRequestedQuantity = parsed;

                            // totalRequestedQuantity = isFutureOrder == 0
                            //     ? (selectedStockType == 'std'
                            //         ? clampQty(parsed, standardStock)
                            //         : clampQty(parsed, premiumStock))
                            //     : parsed;

                            // requestedReserveQty =
                            //     totalRequestedQuantity - maxQty > 0
                            //         ? maxQty
                            //         : totalRequestedQuantity;
                            // requestedProduceQty =
                            //     totalRequestedQuantity - maxQty > 0
                            //         ? totalRequestedQuantity - maxQty
                            //         : 0;
                          // });

                          // the previous one where we had cap for both selections
                          // setSheetState(() {
                          //   totalRequestedQuantity = ((premiumStock <= 0) && (standardStock <= 0)) ? parsed : clampQty(parsed, maxQty);
                          // });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   mainAxisSize: MainAxisSize.min,
                    //   spacing: 8,
                    //   children: [
                    //     (isFutureOrder == 0)
                    //         ? Text(
                    //             '$requestedReserveQty quantity will be added to current order.',
                    //             style: GoogleFonts.inter(
                    //                 fontSize: 16,
                    //                 color: Color(0xFF048563),
                    //                 fontWeight: FontWeight.w600))
                    //         : Text(
                    //             '$requestedReserveQty quantity will be added to future order.',
                    //             style: GoogleFonts.inter(
                    //                 fontSize: 16,
                    //                 color: Color(0xFFAF4B03),
                    //                 fontWeight: FontWeight.w600)),
                    //     sizedBox(2),
                    //   ],
                    // ),
                    Text(
                        'Orders are served based on availability and are not guaranteed until confirmed by our team.',
                        style: GoogleFonts.inter(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            // canReserve
                            //     ?
                            () async {

                              final weightTag = double.parse(widget.productTags.firstWhere(
                              (tag) =>
                                    (widget.product?.tags
                                            ?.toString()
                                            .split(',')
                                            .contains(tag.tagId?.toString()) ??
                                        false) &&
                                    (tag.type == 'BoxWeight'),
                                orElse: () => ProductTag(name: '0'),
                              ).name);

                          // add haptic feedback of tap
                          HapticFeedback.selectionClick();

                          // we are taking current order and future order as separate items in the cart with isProduction value as 0 and 1 respectively, so based on the isFutureOrder value, we will add the item to the cart with respective isProduction value and requestedReserveQty quantity. 
                          //This is to make sure that we can show the correct items in the current order and future order sections in the cart and also to make sure that we can handle the checkout flow accordingly in the cart screen based on the isProduction value of the items in the cart.
                          // we need to check if the isFutureOrder here is same as the isProduction value for all items in the cart, if not, show a toast that says "You have pending current/future order in your cart. Please checkout or remove it before placing another current/future order." and return
                          if (totalRequestedQuantity > 0) {
                            
                            if (shoppingCartController.items.isNotEmpty) {
                              
                                // showToast(context, 'You have pending future order in your cart. Please checkout or remove it before placing another future order.', Constants.warning);
                                final orderItem = OrderItem(
                                  dealerId: cartDealerId,
                                  dealerName: cartDealerName,
                                  serialId: shoppingCartController
                                          .items.length +
                                      1, // this is based on number of items in cart + 1
                                  product: widget.product,
                                  quantity: totalRequestedQuantity,
                                  stockType: selectedStockType,
                                  // isProduction: (selectedStockType == 'prm') ? 1 : 0,
                                  productionQty: 0,
                                  addedAt: DateTime.now(),
                                  weight: weightTag,
                                );

                                shoppingCartController.add(orderItem);
                              
                            } else {
                              final orderItem = OrderItem(
                                dealerId: cartDealerId,
                                dealerName: cartDealerName,
                                serialId: shoppingCartController.items.length +
                                    1, // this is based on number of items in cart + 1
                                product: widget.product,
                                quantity: totalRequestedQuantity,
                                stockType: selectedStockType,
                                productionQty: 0,
                                addedAt: DateTime.now(),
                                weight: weightTag,
                              );

                              shoppingCartController.add(orderItem);
                            }
                          } else {
                            showToast(
                                context,
                                'Please enter a valid quantity to proceed.',
                                Constants.warning);
                            return;
                          }

                          // if (isFutureOrder == 1 && requestedReserveQty > 0) {
                          //   // show confirmation dialog for production request
                          //   final proceed = await showDialog<bool>(
                          //     context: context,
                          //     builder: (context) => AlertDialog(
                          //       backgroundColor: Colors.white,
                          //       title: Text('Production Request',
                          //           style: GoogleFonts.inter(
                          //               fontWeight: FontWeight.w600)),
                          //       content: Text(
                          //         'You are requesting $requestedReserveQty quantity for production. Do you want to proceed?',
                          //         style: GoogleFonts.inter(),
                          //       ),
                          //       actions: [
                          //         TextButton(
                          //           onPressed: () =>
                          //               Navigator.of(context).pop(false),
                          //           child: Text('Cancel',
                          //               style: GoogleFonts.inter(
                          //                   textStyle: Theme.of(context)
                          //                       .textTheme
                          //                       .bodyMedium,
                          //                   color: Colors.black87)),
                          //         ),
                          //         ElevatedButton(
                          //           style: ButtonStyle(
                          //             backgroundColor: WidgetStateProperty.all(
                          //                 Color(0xFF048563)),
                          //             foregroundColor:
                          //                 WidgetStateProperty.all(Colors.white),
                          //           ),
                          //           onPressed: () =>
                          //               Navigator.of(context).pop(true),
                          //           child: Text('Proceed',
                          //               style: GoogleFonts.inter(
                          //                   textStyle: Theme.of(context)
                          //                       .textTheme
                          //                       .bodyMedium,
                          //                   color: Colors.white,
                          //                   fontWeight: FontWeight.w600)),
                          //         ),
                          //       ],
                          //     ),
                          //   );

                          //   if (proceed != true) {
                          //     return;
                          //   } else {
                          //     if (isFutureOrder == 1 && requestedReserveQty > 0) {
                          //       final orderItem = OrderItem(
                          //         serialId: shoppingCartController
                          //                 .items.length +
                          //             1, // this is based on number of items in cart + 1
                          //         product: widget.product,
                          //         quantity: requestedReserveQty,
                          //         stockType: selectedStockType,
                          //         isProduction: 0,
                          //         addedAt: DateTime.now(),
                          //       );
                          //       shoppingCartController.add(orderItem);
                          //     }

                          //     if (isFutureOrder == 1 && requestedReserveQty > 0) {
                          //       final orderItem1 = OrderItem(
                          //         serialId: shoppingCartController
                          //                 .items.length +
                          //             1, // this is based on number of items in cart + 1
                          //         product: widget.product,
                          //         quantity: requestedReserveQty,
                          //         stockType: selectedStockType,
                          //         isProduction: 1,
                          //         addedAt: DateTime.now(),
                          //       );
                          //       shoppingCartController.add(orderItem1);
                          //     }
                          //   }
                          // } else {
                          //   final orderItem = OrderItem(
                          //     serialId: shoppingCartController.items.length +
                          //         1, // this is based on number of items in cart + 1
                          //     product: widget.product,
                          //     quantity: totalRequestedQuantity,
                          //     stockType: selectedStockType,
                          //     isProduction: (selectedStockType == 'prm' &&
                          //             premiumStock == 0)
                          //         ? 1
                          //         : 0,
                          //     addedAt: DateTime.now(),
                          //   );

                          //   shoppingCartController.add(orderItem);
                          // }

                          Navigator.of(context).pop();
                          // make the api call to reserve here using product?.id, selectedStockType, totalRequestedQuantity
                          // on success:
                          // totalRequestedQuantity > 0
                          //   ? {
                          //       reserveTheStock( totalRequestedQuantity, selectedStockType, ),
                          //       Navigator.pop(context)
                          //     }
                          //   : showToast(context, 'Please enter a valid quantity to proceed.', Constants.warning);
                        },
                        // : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Color(0xFF048563),
                          // : Color(0xFF0C8894),
                          foregroundColor:
                              // canReserve ? 
                              // Colors.white :
                               Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                        ),
                        child: Text('Add to Cart',
                          // ? 'Confirm Reservation'
                          // : 'Request Production',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    sizedBox(120)
                  ],
                );
              },
            ),
          );
        });
  }

  Future<dynamic> _handleReservation(
      BuildContext context, String stockType, int quantity) async {
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => const Center(child: CircularProgressIndicator()),
    // );
    // await Future.delayed(const Duration(milliseconds: 600));
    // Navigator.of(context).pop();

    // call the API for reservation here using product?.id, stockType, quantity
    // show the local confirmation after success

    // send data back to the previous screen while popping
    Navigator.of(context).pop({
      // 'productId': product?.id,
      'stockType': stockType,
      'quantity': quantity,
    });
  }
}

class _StockCount extends StatelessWidget {
  final String label;
  final int value;
  final bool isSelected;
  final VoidCallback? onTap;
  const _StockCount({
    required this.label,
    required this.value,
    this.isSelected = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    final Color accent = const Color(0xFF048563);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : Colors.black12,
                width: isSelected ? 1.4 : 1,
              ),
              color: isSelected
                  ? accent.withOpacity(0.08)
                  : Colors.black.withOpacity(0.02),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.16),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: isSelected ? accent : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w700 : null,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(top: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: value > 0
                            ? (isSelected ? accent : Colors.green)
                            : Colors.black12,
                        shape: BoxShape.circle,
                        boxShadow: value > 0
                            ? [
                                BoxShadow(
                                  color: (isSelected ? accent : Colors.green)
                                      .withOpacity(0.35),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: (isSelected ? accent : Colors.green)
                                      .withOpacity(0.15),
                                  blurRadius: 22,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 0,
                                  spreadRadius: 0,
                                )
                              ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? accent
                        : value > 0
                            ? Colors.black
                            : Colors.black38,
                  ),
                ),
                // if (isDisabled) ...[
                //   const SizedBox(height: 2),
                //   Text(
                //     'Unavailable',
                //     style: GoogleFonts.inter(
                //       fontSize: 11,
                //       color: Colors.black45,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   )
                // ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DealerSelectionSheet extends StatefulWidget {
  const _DealerSelectionSheet({
    required this.role,
    required this.adminId,
    required this.activeDealerLabel,
    required this.hasActiveDealer,
  });

  final String role;
  final String adminId;
  final String activeDealerLabel;
  final bool hasActiveDealer;

  @override
  State<_DealerSelectionSheet> createState() => _DealerSelectionSheetState();
}

class _DealerSelectionSheetState extends State<_DealerSelectionSheet> {
  late final TextEditingController _searchController;
  List<Users> _dealers = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _emptyStateMsg =
      'Search by name to assign this order before choosing quantity.';
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _requestToken++;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchDealers(String searchTerm) async {
    final query = searchTerm.trim();

    if (query.isEmpty) {
      _requestToken++;
      if (!mounted) {
        return;
      }
      setState(() {
        _dealers = [];
        _isLoading = false;
        _hasSearched = false;
        _emptyStateMsg =
            'Search by name to assign this order before choosing quantity.';
      });
      return;
    }

    final currentToken = ++_requestToken;
    setState(() {
      _hasSearched = true;
      _isLoading = true;
      _emptyStateMsg = 'Searching ...';
    });

    if (!await checkInternetConnectivity()) {
      if (!mounted || currentToken != _requestToken) {
        return;
      }
      setState(() {
        _dealers = [];
        _isLoading = false;
        _emptyStateMsg = 'No internet connection. Try again to load.';
      });
      showToast(
        context,
        'No connection. Try again later!',
        Constants.warning,
      );
      return;
    }

    try {
      final result = await get(
        Uri.parse(
          APIUrls.getUrl(
            '${APIUrls.user}${APIUrls.pass}/U2/$query/0/${widget.role}/${widget.adminId}',
            {},
          ),
        ),
        headers: {'Accept': 'application/json'},
      );

      if (!mounted || currentToken != _requestToken) {
        return;
      }

      final jsonString = jsonDecode(result.body);
      final jsonObject = jsonString as Map;

      if (jsonObject['status'] == 200) {
        final dealerData = jsonObject['data'] as List;
        final results =
            dealerData.map<Users>((json) => Users.fromJson(json)).toList();

        setState(() {
          _dealers = results;
          _isLoading = false;
          _emptyStateMsg = results.isEmpty
              ? 'No matching users found. Try a different name.'
              : _emptyStateMsg;
        });
        return;
      }

      setState(() {
        _dealers = [];
        _isLoading = false;
        _emptyStateMsg = 'No matching users found. Try a different name.';
      });
    } catch (_) {
      if (!mounted || currentToken != _requestToken) {
        return;
      }
      setState(() {
        _dealers = [];
        _isLoading = false;
        _emptyStateMsg = 'Unable to load users right now. Please retry.';
      });
      showToast(
        context,
        'Unable to load users right now.',
        Constants.error,
      );
    }
  }

  void _clearSearch() {
    _requestToken++;
    _searchController.clear();
    setState(() {
      _dealers = [];
      _isLoading = false;
      _hasSearched = false;
      _emptyStateMsg =
          'Search by name to assign this order before choosing quantity.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF4FBF8), Color(0xFFE7F3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD8E6DF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.role.toLowerCase() != Constants.staff.toLowerCase()) ? 'Choose Dealer' : 
                      'Choose Customer',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10231B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Assign this order to a ${(widget.role.toLowerCase() != Constants.staff.toLowerCase()) ? 'dealer' : 'customer'}, then continue directly into stock selection.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: const Color(0xFF52605B),
                      ),
                    ),
                    if (widget.hasActiveDealer) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.userCircle,
                              color: Color(0xFF0C6B54),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.activeDealerLabel,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF10231B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              DealerSearchWidget(
                controller: _searchController,
                dealers: _dealers,
                isLoading: _isLoading,
                readOnlyWhenFilled: false,
                autofocus: true,
                hintText: 'Search dealer by name',
                emptyStateText: _emptyStateMsg,
                onChanged: (value) {
                  if (value.trim().isEmpty) {
                    _clearSearch();
                    return;
                  }

                  if (value.trim().length >= 3) {
                    _searchDealers(value);
                  }
                },
                onSubmitted: _searchDealers,
                onClear: _clearSearch,
                onDealerTap: (dealer) {
                  Navigator.of(context).pop(dealer);
                },
              ),
              if (!_hasSearched) ...[
                const SizedBox(height: 16),
                Text(
                  'Tip: start typing at least 3 letters for instant suggestions, or press search on the keyboard.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6A7671),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet({
    required this.adminId,
    required this.requesterRole,
    required this.onCreateCustomer,
  });

  final String adminId;
  final String requesterRole;
  final Future<Users?> Function({
    required String customerName,
    required String mobileNumber,
    required String emailAddress,
  }) onCreateCustomer;

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (!await checkInternetConnectivity()) {
      if (!mounted) {
        return;
      }
      showToast(context, 'No connection. Try again later!', Constants.warning);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final createdCustomer = await widget.onCreateCustomer(
        customerName: _nameController.text,
        mobileNumber: _mobileController.text,
        emailAddress: _emailController.text,
      );

      if (!mounted || createdCustomer == null) {
        return;
      }

      showToast(
        context,
        'Customer added successfully.',
        Constants.success,
      );
      Navigator.of(context).pop(createdCustomer);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showToast(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        Constants.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4FBF8), Color(0xFFE7F3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8E6DF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Customer',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF13231D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a customer profile and continue this order with that customer selected.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5B6B64),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _CustomerField(
                  controller: _nameController,
                  label: 'Customer Name',
                  hintText: 'Enter customer name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Enter the customer name.';
                    }
                    if (trimmed.length < 3) {
                      return 'Name should be at least 3 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _CustomerField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  hintText: 'Enter mobile number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Enter the mobile number.';
                    }
                    if (trimmed.length < 10) {
                      return 'Enter a valid mobile number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _CustomerField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter email address (optional)',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    final emailRegex = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+',
                    );
                    if (!emailRegex.hasMatch(trimmed)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF048563),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Creating customer...',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Create Customer',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF24312C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: Colors.black38),
            filled: true,
            fillColor: const Color(0xFFF8FAF9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E2DE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9E2DE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF048563), width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB42318)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QtyButton({required this.icon, this.onPressed});
  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: enabled ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Icon(icon, color: enabled ? Colors.white : Colors.grey),
        ),
      ),
    );
  }
}

// Note: CardInteractive is referenced above as in your previous bottom sheet.
// If it's in another file, keep the import; if not present, replace or implement it.
