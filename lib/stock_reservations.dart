import 'dart:convert';

import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/modals/reservation_product.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/database_helper.dart';
import 'package:anjanitek/utils/dotted_line.dart';
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
  final List<ReservationProduct> items;

  const _ReservationGroup({
    required this.groupKey,
    required this.cartId,
    required this.items,
  });
}

/// A stateful widget that fetches and shows reservations from an API.
class StockReservationsPage extends StatefulWidget {
  const StockReservationsPage({super.key});

  @override
  _StockReservationsPageState createState() => _StockReservationsPageState();
}

class _StockReservationsPageState extends State<StockReservationsPage> {
  late SharedPreferences prefs;
  DatabaseHelper dbHelper = DatabaseHelper();
  static String name = '', id = '', role = 'Guest';
  List<ProductTag> productTags = [];
  List<ReservationProduct> _reservations = <ReservationProduct>[];
  int totalReservations = 0;
  int offset = 0;
  final int _limit = 20;
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
      });
    }

    _loadInitialReservations();
  }

  Future<void> _loadInitialReservations() async {
    setState(() {
      _isLoading = true;
      offset = 0;
      _hasMore = true;
      _reservations = [];
    });

    final page = await getProductTagsAndFetchReservations();
    setState(() {
      _reservations = page;
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
      _reservations.addAll(page);
      if (page.length < _limit) _hasMore = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
      offset = 0;
      _hasMore = true;
      _reservations = [];
    });
    await _loadInitialReservations();
  }

  // Get product tags
  Future<List<ReservationProduct>> getProductTagsAndFetchReservations() async {
      
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

  Future<List<ReservationProduct>> _fetchReservations() async {
    var result = await get(
      Uri.parse(APIUrls.getUrl(
          "${APIUrls.reservations}${APIUrls.pass}/U1/$id/$offset", {})),
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
        return showData
            .map<ReservationProduct>((json) => ReservationProduct.fromJson(json))
            .toList();
      } else {
        return [];
      }
    }
    return [];
  }

  // Future<void> _onRefresh() async {
  //   setState(() {
  //     _currentPage = 0;
  //     _futureReservations = _fetchReservations();
  //   });
  //   await _futureReservations;
  // }

  List<_ReservationGroup> _groupReservationsByCartId(List<ReservationProduct> items) {
    final groups = <_ReservationGroup>[];
    final groupedMap = <String, List<ReservationProduct>>{};
    final cartIds = <String, String?>{};

    for (final reservation in items) {
      final cartId = reservation.cartId?.trim();
      final key = (cartId != null && cartId.isNotEmpty)
          ? cartId
          : 'single-${reservation.id}';

      groupedMap.putIfAbsent(key, () => <ReservationProduct>[]).add(reservation);
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

  Widget _buildReservationCard(BuildContext context, ReservationProduct reservation) {
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
                Text('|', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.black26,),),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8,
                  children: [
                    HugeIcon(icon: HugeIconsStrokeRounded.weightScale01, size: 20, color: Colors.brown.shade400),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                            
                            Text('${formatTotalWeightForDesignType_Old([reservation], productTags)}'.split(' ').first, style: GoogleFonts.robotoMono(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w500, color: Colors.black87,),),
                            Text('${formatTotalWeightForDesignType_Old([reservation], productTags)}'.split(' ').last, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodySmall,fontWeight: FontWeight.w500,color: Colors.black54,),
                          ),
                          ],),
                          
                  ],
                ),
                
              ],
            ),
          ),
          
          sizedBox(16),

          Text(
            '${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.createdOn)!)}}',
            style: GoogleFonts.inter(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          
          // sizedBox(12),
          reservation.status != 'Submitted' ? const SizedBox(height: 12) : sizedBox(0),
          reservation.status != 'Submitted' ?  DottedLine() : sizedBox(0),
          // reservation.status != 'Submitted' ? const SizedBox(height: 12) : sizedBox(0),
          reservation.approvedQty == 0 ? sizedBox(0) : sizedBox(12),

          
          // reservation.status.toLowerCase() == 'rejected' ? sizedBox(12) : sizedBox(0),
          (reservation.status.toLowerCase() == 'rejected' || reservation.status.toLowerCase() == 'outofstock')
              ? Text(
                  reservation.status,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade800,
                  ),
                )
              : sizedBox(0),
          // sizedBox(4),
          (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified') && reservation.approvedQty > 0
              ? Text(
                  'Approved: ${reservation.approvedQty}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade800,
                  ),
                )
              : sizedBox(0),
          // sizedBox(4),
          (reservation.status.toLowerCase() == 'approved' || reservation.status.toLowerCase() == 'modified' || reservation.status.toLowerCase() == 'rejected' ||  reservation.status.toLowerCase() == 'outofstock')
              ? Text(
                  'On: ${DateFormat('d-MMM-yy hh:mm a', 'en_US').format(DateTime.tryParse(reservation.approvedOn!)!)}',
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                    fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildList(List<ReservationProduct> items) {
    // set a state variable with the data
    if (items.isEmpty) {
      return const Center(child: Text('No reservations'));
    }

    final groupedItems = _groupReservationsByCartId(items);

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
          final reservations = group.items;

          if (reservations.length == 1) {
            return _buildReservationCard(context, reservations.first);
          }

          final isExpanded = _isGroupExpanded(group.groupKey);

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
                  onTap: () => _toggleGroup(group.groupKey),
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
                              group.cartId?.isNotEmpty == true ? 
                              Text(
                                '${reservations.length} ${group.items.first.designType == 1 ? 'ATL' : 'VCL'} Designs • ${formatTotalWeightForDesignType_Old(group.items, productTags)}',
                                // group.cartId?.isNotEmpty == true ? 'Cart ${group.cartId}' : 'Single reservation',
                                style: GoogleFonts.robotoMono(
                                  textStyle: Theme.of(context).textTheme.bodyLarge,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ) : sizedBox(0),
                              
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
                      child: _buildReservationCard(context, reservation),
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
    final currentOrders = _reservations
        .where((reservation) => (reservation.isProduction ?? 0) == 0)
        .toList();
    final futureOrders = _reservations
        .where((reservation) => (reservation.isProduction ?? 0) == 1)
        .toList();

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
      //         // _futureReservations = _fetchReservations();
      //         _onRefresh();
      //       }),
      //     ),
      //   ],
      // ),

      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text('Orders', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              // _futureReservations = _fetchReservations();
              _onRefresh();
            }),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Total stock reservations till date ${totalReservations > 0 ? '$totalReservations' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    indicator: BoxDecoration(
                      color: const Color(0xFF048563),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF048563).withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child:
                              Text('Current orders (${currentOrders.length})'),
                        ),
                      ),
                      Tab(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Future orders (${futureOrders.length})'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildList(currentOrders),
                          _buildList(futureOrders),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
