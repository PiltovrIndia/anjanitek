import 'dart:convert';

import 'package:anjanitek/modals/ordered_item.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/reservation_product.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/database_helper.dart';
import 'package:anjanitek/utils/dotted_line.dart';
import 'package:anjanitek/utils/segment_progressbar.dart';
import 'package:anjanitek/utils/shimmer_text.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

class _ReservationGroup {
  final String groupKey;
  final String? cartId;
  final List<CartItem> items;

  const _ReservationGroup({
    required this.groupKey,
    required this.cartId,
    required this.items,
  });
}

/// A stateful widget that fetches and shows reservations from an API.
class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  late SharedPreferences prefs;
  DatabaseHelper dbHelper = DatabaseHelper();
  static String name = '', id = '', role = 'Guest';
  List<ProductTag> productTags = [];
  List<CartItem> _orders = <CartItem>[];
  int totalReservations = 0;
  int offset = 0;
  final int _limit = 20;
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
  late ScrollController _scrollController;
  bool _isLoading = false; // initial load
  bool _isLoadingMore = false; // loading next page
  bool _hasMore = true;
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
        name = prefs.get(Constants.name) as String;
        role = prefs.get(Constants.role) as String;
      });
    }

    _loadInitialReservations();
  }

  Future<void> _loadInitialReservations() async {
    setState(() {
      _isLoading = true;
      offset = 0;
      _hasMore = true;
      _orders = [];
    });

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
    final page = await _fetchOrders();
    setState(() {
      _orders.addAll(page);
      if (page.length < _limit) _hasMore = false;
      _isLoadingMore = false;
    });
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

            return await _fetchOrders();
      }
      else {
        // showToast("Failed to fetch product tags");
        return [];
      }
    }

  Future<List<CartItem>> _fetchOrders() async {
    // var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.orders}${APIUrls.pass}/U0/$id/createdOn", {})),
    // print("${APIUrls.orders}${APIUrls.pass}/U0/$selectedStatus/$offset/$role/$id/$sortBy");
    var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.orders}${APIUrls.pass}/U0/$selectedStatus/$offset/$role/$id/$sortBy", {})),
      headers: {"Accept": "application/json"},
    );
    var jsonString = jsonDecode(result.body);
    var jsonObject = jsonString as Map;
    if (jsonObject['status'] == 200) {
      var showData = jsonObject['data'] as List;
      var total = jsonObject['count'] as int;

      setState(() {
        totalReservations = total;
      });

      if (showData.isNotEmpty) {
        return showData.map<CartItem>((json) => CartItem.fromJson(json)).toList();
      } else {
        return [];
      }
    }
    return [];
  }

  // Future<void> _onRefresh() async {
  //   setState(() {
  //     _currentPage = 0;
  //     _futureReservations = _fetchOrders();
  //   });
  //   await _futureReservations;
  // }

  List<_ReservationGroup> _groupReservationsByCartId(List<CartItem> items) {
    final groups = <_ReservationGroup>[];
    final groupedMap = <String, List<CartItem>>{};
    final cartIds = <String, String?>{};

    for (final reservation in items) {
      final cartId = reservation.cartId?.trim();
      final key = (cartId != null && cartId.isNotEmpty)
          ? cartId
          : 'single-${reservation.cartId}';

      groupedMap.putIfAbsent(key, () => <CartItem>[]).add(reservation);
      cartIds[key] = cartId;
    }

    groupedMap.forEach((key, value) {
      groups.add(_ReservationGroup(
        groupKey: key,
        cartId: cartIds[key],
        items: value,
      ));
    });

    return groups;
  }

  bool _isGroupExpanded(String groupKey) {
    return _expandedGroups[groupKey] ?? true;
  }

  void _toggleGroup(String groupKey) {
    setState(() {
      _expandedGroups[groupKey] = !(_expandedGroups[groupKey] ?? true);
    });
  }

  Widget _buildReservationCard(BuildContext context, String? userId, String? cartId,  OrderedItem reservation, {bool isGrouped = false}) {

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
                  spacing: 4,
                  children: [
                    (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified')
                        ? Icon(PhosphorIconsRegular.check, size: 15, color: Colors.black)
                        : sizedBox(0),
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
            '${reservation.design} • ${reservation.stockType == 'prm' ? 'PRM' : 'STD'} • ${reservation.designType == 1 ? 'ATL' : 'VCL'}',
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
          
          sizedBox(16),

          Text(
            // DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.createdOn)!),
            '${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.createdOn)!)} • ${reservation.orderedBy ?? ''}',
            style: GoogleFonts.inter(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          
          // sizedBox(12),
          // reservation.status != 'Submitted' ? const SizedBox(height: 12) : sizedBox(0),
          // reservation.status != 'Submitted' ?  DottedLine() : sizedBox(0),
          // // reservation.status != 'Submitted' ? const SizedBox(height: 12) : sizedBox(0),
          // reservation.approvedQty == 0 ? sizedBox(0) : 
          sizedBox(12),

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
                            'Waitlist', //: #${reservation.waitlistPosition}',
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
              (reservation.status.toLowerCase() == 'rejected')
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

              
              // sizedBox(4),
              (reservation.status.toLowerCase() == 'modified')
                  ? Text(
                      'Updated on: ${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.modifiedOn!)!)}',
                      style: GoogleFonts.inter(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    )
                  : sizedBox(0),

            ],
          ),
              
          
        ],
      ),
    );
  }

  Widget _buildList(List<CartItem> items) {
    // set a state variable with the data
    if (items.isEmpty) {
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
            return _buildReservationCard(context, group.cartId, group.cartId, reservations.first, isGrouped: true);
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              group.cartId.isNotEmpty == true ? 
                              Text(
                                // '${reservations.length} ${group.orderedItems!.first.designType == 1 ? 'ATL' : 'VCL'} Designs • ${formatTotalWeightForDesignType(group.orderedItems!, productTags)}',
                                '${reservations.length} ${group.orderedItems!.first.designType == 1 ? 'ATL' : 'VCL'} Designs ${group.orderedItems!.first.designType == 1 ? '' : ' • ${formatTotalWeightForDesignType(group.orderedItems!, productTags)}'}',
                                // group.cartId?.isNotEmpty == true ? 'Cart ${group.cartId}' : 'Single reservation',
                                style: GoogleFonts.robotoMono(
                                  textStyle: Theme.of(context).textTheme.bodyLarge,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ) : sizedBox(0),

                              group.cartId.isNotEmpty == true ? 
                              Text(
                                '#${group.cartId}',
                                // group.cartId?.isNotEmpty == true ? 'Cart ${group.cartId}' : 'Single reservation',
                                style: GoogleFonts.robotoMono(
                                  textStyle: Theme.of(context).textTheme.bodyMedium,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black45,
                                ),
                              ) : sizedBox(0),
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
                        //     'Grouped',
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
                      child: _buildReservationCard(context, group.cartId, group.cartId, reservation, isGrouped: false),
                    );
                  }),
                ],
              ],
            ),
          );
          // ListTile(
          //   leading: CircleAvatar(child: Text(r.requestedQty.toString())),
          //   title: Text(r.name),
          //   subtitle: Text('${r.userId}$time'),
          //   trailing: Chip(
          //     label: Text(r.status),
          //     backgroundColor: _statusColor(r.status),
          //   ),
          //   onTap: () {
          //     // placeholder for details
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(content: Text('Reservation ${r.id} tapped')),
          //     );
          //   },
          // );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'modified':
        return Colors.orange.shade100;
      case 'submitted':
        return Colors.grey.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      case 'rejected':
        return Colors.red.shade200;
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
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   title: Text(
      //     'Stock Orders',
      //     style: GoogleFonts.inter(
      //         textStyle: Theme.of(context).textTheme.bodyLarge,
      //         color: Colors.black,
      //         fontWeight: FontWeight.bold),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: () => setState(() {
      //         // _futureReservations = _fetchOrders();
      //         _onRefresh();
      //       }),
      //     ),
      //   ],
      // ),

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
          ],
        ),
        
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              // _futureReservations = _fetchOrders();
              _onRefresh();
            }),
          ),
        ],
      ),
      body: SafeArea(
          child: 
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     const SizedBox(height: 12),
          //     Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       child: Text(
          //         'Total stock reservations till date ${totalReservations > 0 ? '$totalReservations' : ''}',
          //         style: GoogleFonts.inter(
          //           fontSize: 16,
          //           fontWeight: FontWeight.w500,
          //           color: Colors.black87,
          //         ),
          //       ),
          //     ),
          //     const SizedBox(height: 12),
               _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    :
                          _buildList(_orders),
              //  ]
              // ),
            
          ),
        
      
    );
  }
}
