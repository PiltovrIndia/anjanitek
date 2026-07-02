import 'dart:convert';

import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/ordered_item.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/database_helper.dart';
import 'package:anjanitek/utils/dotted_line.dart';
import 'package:anjanitek/utils/segment_progressbar.dart';
import 'package:anjanitek/utils/shimmer_text.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

/// Simple reservations model


class _ReservationGroup {
  final String groupKey;
  final String? cartId;
  final List<OrderedItem> items;

  const _ReservationGroup({
    required this.groupKey,
    required this.cartId,
    required this.items,
  });
}

/// A stateful widget that fetches and shows reservations from an API.
class OrdersAdmin extends StatefulWidget {
  const OrdersAdmin({super.key});

  @override
  _OrdersAdminState createState() => _OrdersAdminState();
}

class _OrdersAdminState extends State<OrdersAdmin> {
  late SharedPreferences prefs;
  DatabaseHelper dbHelper = DatabaseHelper();
  static String id = '', role = 'Guest';
  bool approving = false;
  bool cancelling = false;
  String selectedStatus = 'All';
  String sortBy = 'createdOn';
  List<String> statuses = [
    'All',
    'Submitted',
    'Approved',
    'Modified',
    'Cancelled',
    'OutOfStock'
  ];
  List<Map<String, dynamic>> sorts = [
    {'label': 'Latest Created First', 'value': 'createdOn'},
    {'label': 'Latest Processed First', 'value': 'approvedOn'}
  ];
  // text controllers for approved quantity
  final TextEditingController _approvedQtyController = TextEditingController();
  int offset = 0;
  // pagination / infinite scroll state
  // final List<Reservation> _items = [];
  List<ProductTag> productTags = [];
  List<CartItem> _orders = <CartItem>[];
  late ScrollController _scrollController;
  bool _isLoading = false; // initial load
  bool _isLoadingMore = false; // loading next page
  bool _hasMore = true;
  final int _limit = 20;
  final Map<String, bool> _expandedGroups = <String, bool>{};

  @override
  void initState() {
    super.initState();

    getUserData();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });

  }

  // get user details
  void getUserData() async {
    await dbHelper.initDb();
    prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Constants.name)) {
      setState(() {
        id = prefs.get(Constants.id) as String;
        role = prefs.get(Constants.role) as String;
      });
    }

    _loadInitialReservations();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
      offset = 0;
      _hasMore = true;
      _orders = [];
    });
    await _loadInitialReservations();
  }

  // Get product tags
  Future<List<CartItem>> getProductTagsAndFetchReservations() async {
      
      Map<String, String> queryParams = { };
      // API call
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U0", queryParams)), headers: {"Accept": "application/json"});
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      
      if(jsonObject['status'] == 200){
          var showCataloguesData = jsonObject['data'] as List;
      
            if(showCataloguesData.isNotEmpty){
            
              List<ProductTag> productTagsList = showCataloguesData.map<ProductTag>((json) => ProductTag.fromJson(json)).toList();
              setState(() {
                  // Get new user data
                  productTags = productTagsList;
                  
              });
            }

            return await _fetchReservations();
      }
      else {
        // showToast("Failed to fetch product tags");
        return [];
      }
    }

  Future<List<CartItem>> _fetchReservations() async {
    setState(() {
      _isLoading = true;
    });
  print("${APIUrls.orders}${APIUrls.pass}/U0/$selectedStatus/$offset/$role/$id/$sortBy");
    final uri = Uri.parse(APIUrls.getUrl("${APIUrls.orders}${APIUrls.pass}/U0/$selectedStatus/$offset/$role/$id/$sortBy", {}));
    // final uri = Uri.parse(APIUrls.getUrl("${APIUrls.orders}${APIUrls.pass}/U0/$id/$sortBy", {}));
    final result = await get(uri, headers: {"Accept": "application/json"});
    final jsonString = jsonDecode(result.body);
    final jsonObject = jsonString as Map;
    if (jsonObject['status'] == 200) {
      final showData = jsonObject['data'] as List;

      if (showData.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        return showData.map<CartItem>((json) => CartItem.fromJson(json)).toList();
      } else {
        setState(() {
          _isLoading = false;
        });
        return _orders;
      }

      
    }
    return _orders;
  }

  Future<void> _loadInitialReservations() async {
    setState(() {
      _isLoading = true;
      offset = 0;
      _hasMore = true;
      _orders = [];
    });

    // final page = await _fetchReservations();
    final page = await getProductTagsAndFetchReservations();
    setState(() {
      _orders = page;
      if (page.length < _limit) _hasMore = false;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() {
      _isLoadingMore = true;
    });
    offset += _limit;
    final page = await _fetchReservations();
    setState(() {
      _orders.addAll(page);
      if (page.length < _limit) _hasMore = false;
      _isLoadingMore = false;
    });
  }

  // Future<void> _onRefresh() async {
  //   await _loadInitialReservations();
  // }

  // List<_ReservationGroup> _groupReservationsByCartId(List<CartItem> items) {
  //   final groups = <_ReservationGroup>[];
  //   final groupedMap = <String, List<CartItem>>{};
  //   final cartIds = <String, String?>{};

  //   for (final reservation in items) {
  //     final cartId = reservation.cartId?.trim();
  //     final key = (cartId != null && cartId.isNotEmpty)
  //         ? cartId
  //         : 'single-${reservation.id}';

  //     groupedMap.putIfAbsent(key, () => <CartItem>[]).add(reservation);
  //     cartIds[key] = cartId;
  //   }

  //   groupedMap.forEach((key, value) {
  //     groups.add(_ReservationGroup(
  //       groupKey: key,
  //       cartId: cartIds[key],
  //       items: value,
  //     ));
  //   });

  //   return groups;
  // }

  void _replaceReservationInState(String? cartId, OrderedItem updatedReservation) {
    final reservationIndex = _orders.indexWhere(
      (item) => item.cartId == cartId && item.orderedItems!.firstWhere((orderedItem) => orderedItem.id == updatedReservation.id).id == updatedReservation.id);

    if (reservationIndex == -1) {
      return;
    }

    setState(() {
      _orders.firstWhere((item) => item.cartId == cartId).orderedItems![reservationIndex] = updatedReservation;
    });
  }

  bool _isGroupExpanded(String groupKey) {
    return _expandedGroups[groupKey] ?? true;
  }

  void _toggleGroup(String groupKey) {
    setState(() {
      _expandedGroups[groupKey] = !(_expandedGroups[groupKey] ?? true);
    });
  }

  Widget _buildReservationCard(BuildContext context, String? userId, String? cartId, OrderedItem reservation, {bool isGrouped = false}) {

    final progress = reservation.approvedQty == 0 ? 0.0 : reservation.approvedQty / reservation.requestedQty;
    final progressColor = progress < 0.5 ? Colors.red : const Color(0xFF008060);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isGrouped ?
          Container(
            // padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            // decoration: BoxDecoration(
            //   color: Colors.blue.shade50,
            //   borderRadius: BorderRadius.circular(12),
            // ),
            child:
              Text(
                '${reservation.dealer}'.toUpperCase(),
                style: GoogleFonts.inter(
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              )
           ) : sizedBox(0),
          isGrouped ?
          Text(
            '#${cartId}',
            // group.cartId?.isNotEmpty == true ? 'Cart ${group.cartId}' : 'Single reservation',
            style: GoogleFonts.robotoMono(
              textStyle: Theme.of(context).textTheme.bodyMedium,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
            ),
          ) : sizedBox(0) ,
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.name,
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(reservation.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      reservation.status,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            '${reservation.design}',
            // '${reservation.design} • ${reservation.stockType == 'prm' ? 'PRM' : 'STD'} • ${reservation.designType == 1 ? 'ATL' : 'VCL'}',
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          sizedBox(16),

          Container(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8,
                  children: [
                    HugeIcon(icon: HugeIconsStrokeRounded.artboardTool, size: 20, color: Colors.brown.shade400),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                            
                            Text(
                              reservation.designType == 1 ? 'ATL' : 'VCL',
                              style: GoogleFonts.robotoMono(
                                textStyle: Theme.of(context).textTheme.bodyLarge,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                            reservation.stockType == 'prm' ? 'PRM' : 'STD',
                            style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodySmall,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          ],),
                          
                  ],
                ),
                Text('|', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.black26,),),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8,
                  children: [
                    HugeIcon(icon: HugeIconsStrokeRounded.package, size: 20, color: Colors.brown.shade400),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                            
                            Text('${reservation.requestedQty}', style: GoogleFonts.robotoMono(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w500, color: Colors.black87,),),
                            Text( 'Boxes', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.w500, color: Colors.black54,),
                          ),
                          ],),
                          
                  ],
                ),
                reservation.designType == 1 ? sizedBox(0) :
                Text('|', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.black26,),),
                reservation.designType == 1 ? sizedBox(0) :
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8,
                  children: [
                    HugeIcon(icon: HugeIconsStrokeRounded.weightScale01, size: 20, color: Colors.brown.shade400),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                            
                            Text('${formatTotalWeightForDesignType([reservation], productTags)}'.split(' ').first, style: GoogleFonts.robotoMono(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w500, color: Colors.black87,),),
                            Text('${formatTotalWeightForDesignType([reservation], productTags)}'.split(' ').last, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall,fontWeight: FontWeight.w500,color: Colors.black54,),
                          ),
                          ],),
                          
                  ],
                ),
                
              ],
            ),
          ),
          
          
          
          // Text(
          //   'Requested: ${reservation.requestedQty}',
          //   style: GoogleFonts.inter(
          //     fontWeight: FontWeight.w500,
          //     color: Colors.black87,
          //   ),
          // ),
          // Text(
          //   '${formatTotalWeightForDesignType([reservation], productTags)}',
          //   style: GoogleFonts.robotoMono(
          //     fontWeight: FontWeight.w500,
          //     color: Colors.black87,
          //   ),
          // ),
          sizedBox(16),
          // Text(
          //   'On: ${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.createdOn)!)}',
          //   style: GoogleFonts.inter(
          //     textStyle: Theme.of(context).textTheme.bodySmall,
          //     fontWeight: FontWeight.w500,
          //     color: Colors.black54,
          //   ),
          // ),
          Text(
            '${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.createdOn)!)} • ${reservation.orderedBy ?? ''}',
            style: GoogleFonts.inter(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          // reservation.status.toLowerCase() == 'submitted' ? sizedBox(0) : 
          sizedBox(12),
          // reservation.status.toLowerCase() == 'submitted' ? sizedBox(0) : DottedLine(),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Expanded(child: 
              BuildSegmentedProgressBar2(progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0, progressColor),),
              Text(
                      '${progress.isFinite ? double.parse(((progress).clamp(0.0, 1.0)*100).toStringAsFixed(1)) : 0} %',
                      style: GoogleFonts.inter(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    )
            ],
          ),
          
          reservation.status.toLowerCase() == 'submitted' ? sizedBox(0) : sizedBox(12),
          // reservation.status.toLowerCase() != 'submitted' ? sizedBox(0) : sizedBox(12),
          // reservation.approvedQty == 0 ? sizedBox(0) : sizedBox(12),

          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified') && reservation.approvedQty > 0
                  ? Text(
                      'Reserved: ${reservation.approvedQty}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF008060),
                      ),
                    )
                    : sizedBox(0),

                    (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified') && reservation.productionQty > 0
                    ? 
                    Row(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'In Production: ${reservation.productionQty}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF008060),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(24),

                          ),
                          child: Text(
                            'Waitlist: #${reservation.waitlistPosition}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          )
                          
                        ),
                      ],
                    )
              
                    : sizedBox(0),

              // reservation.status.toLowerCase() == 'rejected' ? sizedBox(12) : sizedBox(0),
              reservation.status.toLowerCase() == 'rejected'
                  ? Text(
                      'Rejected',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                      ),
                    )
                  : sizedBox(0),
              
              reservation.status.toLowerCase() == 'outofstock'
                  ? Text(
                      'Out of Stock',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    )
                  : sizedBox(0),

              (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified' || reservation.status.toLowerCase() == 'rejected' || reservation.status.toLowerCase() == 'outofstock')
                  ? Text(
                      'On: ${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.approvedOn ?? '')!)}',
                      style: GoogleFonts.inter(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    )
                  : sizedBox(0),

            ],
          ),
          
          
          // (reservation.status.toLowerCase() != 'approved')
          //     ? sizedBox(0)
          //     : reservation.stockType == 'std' &&
          //             reservation.approvedQty > reservation.std
          //         ? Text(
          //             'In Production',
          //             style: GoogleFonts.inter(
          //               fontWeight: FontWeight.w600,
          //               color: Colors.green.shade800,
          //             ),
          //           )
          //         : reservation.stockType == 'prm' &&
          //                 reservation.approvedQty > reservation.prm
          //             ? Text(
          //                 'In Production',
          //                 style: GoogleFonts.inter(
          //                   fontWeight: FontWeight.w600,
          //                   color: Colors.green.shade800,
          //                 ),
          //               )
          //             : sizedBox(0),


          // (role.toLowerCase() == Constants.superAdmin.toLowerCase())
          //     ? reservation.status.toLowerCase() != 'submitted'
          //         ? sizedBox(0)
          //         : ElevatedButton(
          //             style: ButtonStyle(
          //                 backgroundColor: WidgetStateProperty.all(
          //                     const Color(0xFF048563))),
          //             onPressed: () {
          //               _showApprovalBottomSheet(context, reservation);
          //             },
          //             child: Row(
          //               mainAxisSize: MainAxisSize.min,
          //               children: [
          //                 const Icon(PhosphorIconsRegular.check,
          //                     color: Colors.white),
          //                 const SizedBox(width: 8.0),
          //                 Text(
          //                   'Review',
          //                   style: GoogleFonts.inter(
          //                       textStyle:
          //                           Theme.of(context).textTheme.bodyMedium,
          //                       color: Colors.white,
          //                       fontWeight: FontWeight.w500),
          //                 ),
          //               ],
          //             ))
          //     : sizedBox(0),

          // Edit is only visible if the reservation is in submitted state and the logged in user is the one who created the reservation
          // (reservation.status.toLowerCase() == 'submitted' && id == userId) ? sizedBox(12) : sizedBox(0),
          // (reservation.status.toLowerCase() == 'submitted' && id == userId) ? DottedLine() : sizedBox(0),
          // (reservation.status.toLowerCase() == 'submitted' && id == userId) ? sizedBox(12) : sizedBox(0),
          (reservation.status.toLowerCase() != 'submitted' && id == userId && role.toLowerCase() == Constants.superAdmin.toLowerCase())
          // (reservation.status.toLowerCase() == 'approved' ||
          //         reservation.status.toLowerCase() == 'rejected')
              ? ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          const Color(0xFF048563))),
                  onPressed: () {
                    _showApprovalBottomSheet(context, userId, cartId, reservation);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.pencilSimple,
                          color: Colors.white),
                      const SizedBox(width: 8.0),
                      Text(
                        'Edit',
                        style: GoogleFonts.inter(
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ))
              : sizedBox(0),



              // creator can DELETE based on status
              (userId != id)
              ? sizedBox(0)
              : 
              (reservation.status.toLowerCase() != 'submitted') ? sizedBox(0) :
              cancelling
                  ? ShimmerText(
                      text: 'Deleting...',
                      style: GoogleFonts.inter(
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          cancelling = true;
                        });
                        final result = await get(
                          Uri.parse(APIUrls.getUrl("${APIUrls.orders}${APIUrls.pass}/U0.4/${reservation.id}/${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}", {})),
                          headers: {"Accept": "application/json"},
                        );
                        // print(result.body);
                        var jsonString = jsonDecode(result.body);
                        var jsonObject = jsonString as Map;

                        if (jsonObject['status'] == 200) {
                          setState(() {
                            _orders.firstWhere((item) => item.cartId == cartId).orderedItems!.removeWhere((r) => r.id == reservation.id);
                          });

                          showToast(context, 'Reservation deleted successfully.', Constants.success);
                        } else {
                          showToast(context, 'Failed to delete reservation.', Constants.warning);
                        }
                        setState(() {
                          cancelling = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                            textStyle: Theme.of(context).textTheme.bodyLarge,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),

        ],
      ),
    );
  }

  Widget _buildList(List<CartItem> items) {
    if (items.isEmpty && !_isLoading) {
      return const Center(child: Text('No reservations'));
    }

    // final groupedItems = _groupReservationsByCartId(items);
    final groupedItems = items;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          240,
        ),
        itemCount: groupedItems.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= groupedItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final group = groupedItems[index];
          final reservations = group.orderedItems;

          if (reservations!.length == 1) {
            return _buildReservationCard(context, group.userId, group.cartId, reservations.first, isGrouped: true);
          }

          final isExpanded = _isGroupExpanded(group.cartId);
          final progress = group.totalApprovedQty == 0 ? 0.0 : group.totalApprovedQty / group.totalRequestedQty;
          final progressColor = progress < 0.5 ? Colors.red : const Color(0xFF008060);

          return Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _toggleGroup(group.cartId),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10, top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(
                            isExpanded
                                ? PhosphorIconsRegular.caretDown
                                : PhosphorIconsRegular.caretRight,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                // decoration: BoxDecoration(
                                //   color: Colors.blue.shade50,
                                //   borderRadius: BorderRadius.circular(12),
                                // ),
                                child:
                                  Text(
                                    '${reservations.first.dealer}'.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      textStyle: Theme.of(context).textTheme.bodyLarge,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  )
                              ),
                              group.cartId?.isNotEmpty == true ? 
                              Text(
                                '#${group.cartId}',
                                // group.cartId?.isNotEmpty == true ? 'Cart ${group.cartId}' : 'Single reservation',
                                style: GoogleFonts.robotoMono(
                                  textStyle: Theme.of(context).textTheme.bodyMedium,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black45,
                                ),
                              ) : sizedBox(0),
                              group.cartId.isNotEmpty == true ? 
                              Text(
                                '${group.orderedItems!.first.designType == 1 ? 'ATL' : 'VCL'}(${reservations.length}) ${group.orderedItems!.first.designType == 1 ? '' : ' • ${formatTotalWeightForDesignType(group.orderedItems!, productTags)}'}',
                                // group.cartId?.isNotEmpty == true ? 'Cart ${group.cartId}' : 'Single reservation',
                                style: GoogleFonts.robotoMono(
                                  textStyle: Theme.of(context).textTheme.bodyMedium,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ) : sizedBox(0),

                              sizedBox(4),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Expanded(child: 
                                    BuildSegmentedProgressBar2(progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0, progressColor),),
                                    Text(
                                      // let only show 1 digit after . in the %
                                            '${progress.isFinite ? double.parse(((progress).clamp(0.0, 1.0)*100).toStringAsFixed(1)) : 0} %',
                                            style: GoogleFonts.inter(
                                              textStyle: Theme.of(context).textTheme.bodySmall,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          )
                                  ],
                                ),
                              
                              // const SizedBox(height: 4),
                              // Text(
                              //   // lets sum the weight of item using weight variable for each item in the group
                              //   DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservations.first.createdOn)!),
                              //   //  • ${isExpanded ? 'Tap to collapse' : 'Tap to expand'}',
                              //   style: GoogleFonts.inter(
                              //     fontSize: 13,
                              //     fontWeight: FontWeight.w500,
                              //     color: Colors.black54,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 10,
                        //     vertical: 6,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(12),
                        //     border: Border.all(color: Colors.grey.shade300),
                        //   ),
                        //   child: Text(
                        //     group.cartId?.isNotEmpty == true ? 'Grouped' : 'Single',
                        //     style: GoogleFonts.inter(
                        //       fontSize: 12,
                        //       fontWeight: FontWeight.w600,
                        //       color: Colors.black54,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  ...reservations.asMap().entries.map((entry) {
                    final reservation = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == reservations.length - 1 ? 0 : 8,
                      ),
                      child: _buildReservationCard(context, group.userId, group.cartId, reservation, isGrouped: false),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showApprovalBottomSheet(BuildContext context, String? userId, String? cartId, OrderedItem reservation) {
    _approvedQtyController.text = reservation.approvedQty.toString();
    showModalBottomSheet(
      backgroundColor: Colors.white,
      showDragHandle: true,
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isApproving = false;
        bool isRejecting = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    'Review Reservation',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Design: ${reservation.design}'),
                  Text('Name: ${reservation.name}'),
                  // Text('Requested Qty: ${reservation.requestedQty}'),

                  Row(
                    children: [
                      Text('Stock Type: '),
                      Text(
                        '${reservation.stockType == 'prm' ? 'Premium' : 'Standard'}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Currently Available: '),
                      Text(
                        '${reservation.stockType == 'prm' ? reservation.prm : reservation.std}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Text('Requested Qty: '),
                      Text(
                        '${reservation.requestedQty}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _approvedQtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Approved Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: isRejecting
                            ? ShimmerText(
                                text: 'Rejecting...',
                                style: GoogleFonts.inter(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  setModalState(() {
                                    isRejecting = true;
                                  });

                                  final expiryDate = DateTime.now();
                                  final expiryStr =
                                      "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')} ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}:${expiryDate.second.toString().padLeft(2, '0')}";

                                  // var path = 'U3';
                                  // if (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified' || reservation.status.toLowerCase() == 'rejected') {
                                  //   path = 'U3.1';
                                  // }
                                  // print(
                                  //     "${APIUrls.orders}${APIUrls.pass}/U0.3/${reservation.id}/Rejected/0/${userId}/$expiryStr");
                                  final result = await get(
                                    Uri.parse(APIUrls.getUrl(
                                        "${APIUrls.orders}${APIUrls.pass}/U0.3/${reservation.id}/Rejected/0/${userId}/$expiryStr",
                                        {})),
                                    headers: {"Accept": "application/json"},
                                  );
                                  var jsonString = jsonDecode(result.body);
                                  var jsonObject = jsonString as Map;

                                  if (jsonObject['status'] == 200) {
                                    _replaceReservationInState(cartId,
                                      OrderedItem(
                                        id: reservation.id,
                                        design: reservation.design,
                                        name: reservation.name,
                                        requestedQty: reservation.requestedQty,
                                        status: 'Rejected',
                                        approvedQty: 0,
                                        stockType: reservation.stockType,
                                        createdOn: reservation.createdOn,
                                        modifiedOn: DateFormat('yyyy-MM-dd HH:mm:ss')
                                                .format(DateTime.now()),
                                        orderedBy: reservation.orderedBy,
                                        productionQty: reservation.productionQty,
                                        availabilityPercent: reservation.availabilityPercent,
                                        waitlistPosition: reservation.waitlistPosition,
                                        approvedOn:
                                            DateFormat('yyyy-MM-dd HH:mm:ss')
                                                .format(DateTime.now()),
                                        productId: reservation.productId,
                                        description: reservation.description,
                                        size: reservation.size,
                                        tags: reservation.tags,
                                        media: reservation.media,
                                        prm: reservation.prm,
                                        std: reservation.std,
                                        isActive: reservation.isActive,
                                        designType: reservation.designType,
                                        dealer: reservation.dealer,
                                        mobile: reservation.mobile,
                                        mapTo: reservation.mapTo,
                                        serialId: reservation.serialId,
                                        isDeleted: reservation.isDeleted,
                                      ),
                                    );

                                    showToast(context, 'Stock rejected.', Constants.success);

                                    Navigator.pop(context);

                                    // Navigator.of(context).pop(); // Close the dialog
                                  } else {
                                    showToast(
                                        context,
                                        'Failed to reject stock.',
                                        Constants.warning);
                                  }
                                  setModalState(() {
                                    isRejecting = false;
                                  });
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        const Color(0xFFEF5350))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsRegular.x,
                                        color: Colors.white),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'Reject',
                                      style: GoogleFonts.inter(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isApproving
                            ? ShimmerText(
                                text: 'Approving...',
                                style: GoogleFonts.inter(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  if (_approvedQtyController.text.isEmpty) {
                                    showToast(
                                        context,
                                        'Please enter approved quantity.',
                                        Constants.warning);
                                    return;
                                  }

                                  setModalState(() {
                                    isApproving = true;
                                  });

                                  final expiryDate = DateTime.now();
                                  final expiryStr =
                                      "${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')} ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}:${expiryDate.second.toString().padLeft(2, '0')}";

                                  var path = 'U3';
                                  if (reservation.status.toLowerCase() == 'approved' ||
                                      reservation.status.toLowerCase() ==
                                          'modified' ||
                                      reservation.status.toLowerCase() ==
                                          'rejected') {
                                    path = 'U3.1';
                                  }

                                  final result = await get(
                                    Uri.parse(APIUrls.getUrl(
                                        "${APIUrls.orders}${APIUrls.pass}/$path/${reservation.id}/${path == 'U3.1' ? 'Modified' : 'Approved'}/${_approvedQtyController.text.trim()}/${userId}/$expiryStr",
                                        {})),
                                    headers: {"Accept": "application/json"},
                                  );
                                  var jsonString = jsonDecode(result.body);
                                  var jsonObject = jsonString as Map;

                                  if (jsonObject['status'] == 200) {
                  _replaceReservationInState(cartId,
                    OrderedItem(
                    id: reservation.id,
                    design: reservation.design,
                    name: reservation.name,
                    requestedQty: reservation.requestedQty,
                    status: path == 'U3.1'
                      ? 'Modified'
                      : 'Approved',
                    approvedQty: int.parse(
                      _approvedQtyController.text.trim()),
                    stockType: reservation.stockType,
                    createdOn: reservation.createdOn,
                    approvedOn:
                      DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.now()),
                    modifiedOn: path == 'U3.1'
                      ? DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.now())
                      : reservation.modifiedOn,
                    orderedBy: reservation.orderedBy,
                    productionQty: reservation.productionQty,
                    availabilityPercent: reservation.availabilityPercent,
                    waitlistPosition: reservation.waitlistPosition,
                    productId: reservation.productId,
                    description: reservation.description,
                    size: reservation.size,
                    tags: reservation.tags,
                    media: reservation.media,
                    prm: reservation.prm,
                    std: reservation.std,
                    isActive: reservation.isActive,
                    designType: reservation.designType,
                    dealer: reservation.dealer,
                    mobile: reservation.mobile,
                    mapTo: reservation.mapTo,
                    serialId: reservation.serialId,
                    isDeleted: reservation.isDeleted,
                    ),
                  );

                                    showToast(context, 'Stock approved.',
                                        Constants.success);

                                    Navigator.pop(context);

                                    // Navigator.of(context).pop(); // Close the dialog
                                  } else {
                                    showToast(
                                        context,
                                        'Failed to approve stock.',
                                        Constants.warning);
                                  }
                                  setModalState(() {
                                    isApproving = false;
                                  });
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        const Color(0xFF048563))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsRegular.check,
                                        color: Colors.white),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'Approve',
                                      style: GoogleFonts.inter(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Color(0x55008060);
      case 'submitted':
        return Colors.grey.shade100;
      case 'modified':
        return Colors.orange.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      case 'rejected':
        return Colors.red.shade100;
      case 'outofstock':
        return Colors.grey.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: 
        Row(
          spacing: 8,
          children: [
            Text('Orders', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
            Container(
                height: 36,
                margin: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 6.0,
                      ),
                    ],
                ),
              child:
              DropdownButtonHideUnderline(
                child:
                DropdownButton(
                  icon: Container( padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                    child: const PhosphorIcon(PhosphorIconsRegular.caretDown, size: 20,)),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  value: selectedStatus,
                  onChanged: (String? newValue) {
                    setState(() {
                      // based on the choosen status, fetch the data incase already not fetched
                      // selectedStatus = value as String?;
                      selectedStatus = newValue!;
                      sortBy = 'createdOn';
                      offset = 0;
                      _onRefresh();
                      // _fetchReservations();
                    });
                  },
                  
                  items: 
                  statuses.map((status) => 
                    DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            textStyle: Theme.of(context).textTheme.bodyLarge,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ).toList()
                ),
              )
            )
          ]
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              offset = 0;
              _onRefresh();
              // _futureReservations = _fetchReservations();
            }),
          ),
        ],
      ),
      body: 
      // Expanded(
              // child: 
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : 
                        _buildList(_orders)
                    );
            // );
    
  }
}
