import 'dart:convert';
import 'dart:ui';
import 'package:anjanitek/modals/target.dart';
import 'package:anjanitek/utils/app_header.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'package:anjanitek/utils/utils.dart';

// this is
class TargetsDealer extends StatefulWidget {
  final String? userId;
  const TargetsDealer(this.userId, {super.key});

  @override
  _TargetsDealerState createState() => _TargetsDealerState();
}

class _TargetsDealerState extends State<TargetsDealer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controllerCards;
  static String id = '';
  bool targetsDataProgress = false;
  ScrollController? scrollController;

  int offset = 0;
  bool connectionStatus = true;

  // Use DateFormat to parse the dates to ensure accuracy
  DateFormat format = DateFormat("yyyy-MM-dd");
  List<Target> targetsDataList = [];

  TextEditingController mobileController = TextEditingController();
  // Create a FocusNode
  final FocusNode otpFocusNode = FocusNode();
  late SharedPreferences prefs;

  @override
  void initState() {
    // get reference to internal database
    getUsers();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();

    // CurvedAnimation(
    //         parent: _visible ? Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //           parent: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
    //           curve: Curves.easeIn, // Use Curves.easeIn for ease-in animation
    //         )) : Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
    //           parent: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
    //           curve: Curves.easeIn,
    //         )),
    //       );
    _controllerCards = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controllerCards.forward();

    scrollController = new ScrollController()..addListener(_scrollListener);

    super.initState();
  }

  @override
  void dispose() {
    otpFocusNode.dispose(); // Dispose of the FocusNode
    _controllerCards.dispose();
    super.dispose();
  }

  // get user details
  void getUsers() async {
    // fetch from internal db
    // final dbHelper = DatabaseInternal.instance;
    // final allRows = await dbHelper.queryAllRows();
// print('users count ${allRows.length}');

    // no profile exists
    prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Constants.name)) {
      setState(() {
        id = prefs.get(Constants.id) as String;
      });
    }
    refreshUserTargetsDealer(context);
  }

  // refresh the list
  Future<void> _refreshList() async {
    // Add your refresh logic here, e.g. fetching new data from a server

    // set the offset to 0 as we are refreshing to start from first
    setState(() {
      offset = 0;
      targetsDataList.clear();
      targetsDataProgress = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    refreshUserTargetsDealer(context);
  }

  // find the user
  void refreshUserTargetsDealer(BuildContext context) async {
    if (await checkInternetConnectivity()) {
      setState(() {
        targetsDataProgress = true;
      });

      // API call
      // print("${APIUrls.amount}${APIUrls.pass}/U2.2/$id/$offset");
      var result = await get(
          Uri.parse(APIUrls.getUrl(
              "${APIUrls.targets}${APIUrls.pass}/T1/All/${widget.userId}", {})),
          headers: {"Accept": "application/json"});
      // print(result.body);
      // Decode the JSON string into a Map using the jsonDecode function
      var jsonString = jsonDecode(result.body);

      // convert jsonString to Map
      var jsonObject = jsonString as Map;

      // check if the api returned success
      // check if the api returned success
      if (jsonObject['success']) {
        // get the user data from jsonObject
        var targetsData = jsonObject['data'] as List;
        var targets = targetsData[0]['targets'] as List;

        setState(() {
          targetsDataList = _filterTargetsUpToCurrentMonth(
            targets.map<Target>((json) => Target.fromJson(json)).toList(),
          );

          targetsDataProgress = false;
          connectionStatus = true;
        });
      } else if (jsonObject['status'] == 201 || jsonObject['status'] == 402) {
        // no data exists
        setState(() {
          // get the error message
          targetsDataProgress = false;
          connectionStatus = true;
          showToast(context, 'No more invoices', Constants.success);
        });
      } else if (jsonObject['status'] == 404) {
        // no data exists
        setState(() {
          // get the error message
          targetsDataProgress = false;
          connectionStatus = true;
        });
      } else {
        setState(() {
          targetsDataProgress = false;
          connectionStatus = true;
          showToast(context, 'Error, try again later!', Constants.error);
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 5), () {
        refreshUserTargetsDealer(context);

        // set the connection Status variable to false
        setState(() {
          connectionStatus = false;
        });
      });
    }
  }

  // detect scroll to end and load more items
  void _scrollListener() {
    if (scrollController!.position.pixels ==
        scrollController!.position.maxScrollExtent) {
      setState(() {
        // increment offset by 5
        // if(targetsDataList.length-50 == offset){
        //   offset = offset+50;
        //   // show up the loader
        //   startLoader();
        // }
        // else {
        //   //print('do nothing');
        // }
      });
    }
  }

  // show the loader while loading more items
  void startLoader() {
    setState(() {
      targetsDataProgress = !targetsDataProgress;
      refreshUserTargetsDealer(context);
    });
  }

  String _categoryName(Target target) {
    if (target.categoryId == 1) return 'VCL';
    if (target.categoryId == 2) return 'ATL';
    if (target.categoryId == 3) return 'Collections';
    return target.name ?? 'Unknown';
  }

  double _targetAmount(Target target) =>
      double.tryParse(target.targetAmount ?? '0') ?? 0;

  double _achievedAmount(Target target) =>
      double.tryParse(target.actualAmount ?? '0') ?? 0;

  bool _isCollectionCategory(Target target) => target.categoryId == 3;

  String _formatMetric(Target target, double value) {
    if (_isCollectionCategory(target)) {
      return '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(value)}';
    }
    return '${NumberFormat("#,##0.##", "en_IN").format(value)} boxes';
  }

  String _formatBoxesValue(double value) {
    return '${NumberFormat("#,##0.##", "en_IN").format(value)} boxes';
  }

  String _formatCollectionValue(double value) {
    return '₹ ${NumberFormat("#,##,##0.00", "en_IN").format(value)}';
  }

  String _monthKey(Target target) {
    final parsed = DateTime.tryParse(target.monthDate ?? '');
    if (parsed == null) return 'Unknown Month';
    return DateFormat('MMMM yyyy').format(parsed);
  }

  List<Target> _filterTargetsUpToCurrentMonth(List<Target> targets) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return targets.where((target) {
      final parsed = DateTime.tryParse(target.monthDate ?? '');
      if (parsed == null) return false;

      final targetMonth = DateTime(parsed.year, parsed.month);
      return !targetMonth.isAfter(currentMonth);
    }).toList();
  }

  List<MapEntry<String, List<Target>>> _groupedTargetsByMonth() {
    final grouped = <String, List<Target>>{};

    for (final target in targetsDataList) {
      final key = _monthKey(target);
      grouped.putIfAbsent(key, () => []).add(target);
    }

    final entries = grouped.entries.toList();
    entries.sort((a, b) {
      final aDate =
          DateTime.tryParse(a.value.first.monthDate ?? '') ?? DateTime(1900);
      final bDate =
          DateTime.tryParse(b.value.first.monthDate ?? '') ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
    return entries;
  }

  Widget _buildSegmentedProgressBar(double safeProgress, Color progressColor) {
    const totalSegments = 50;
    const gap = 1.2;
    final filledSegments =
        (safeProgress * totalSegments).round().clamp(0, totalSegments);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(14),
      //   color: Colors.white.withValues(alpha: 0.45),
      //   border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      //   boxShadow: [
      //     BoxShadow(
      //       color: progressColor.withValues(alpha: 0.12),
      //       blurRadius: 14,
      //       spreadRadius: 0.5,
      //       offset: const Offset(0, 4),
      //     ),
      //   ],
      // ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGap = (totalSegments - 1) * gap;
          final segmentWidth =
              ((constraints.maxWidth - totalGap) / totalSegments)
                  .clamp(1.0, 6.0);

          return Row(
            children: List.generate(totalSegments, (index) {
              final isFilled = index < filledSegments;

              return Container(
                width: segmentWidth,
                height: 12,
                margin: EdgeInsets.only(
                    right: index == totalSegments - 1 ? 0 : gap),
                decoration: BoxDecoration(
                  color: isFilled
                      ? progressColor
                      : progressColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2.5),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.25),
                            blurRadius: 2,
                            spreadRadius: 0.3,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTargetItem(
    BuildContext context,
    Target target,
    String categoryName,
    double achieved,
    double targetAmount,
    double progress,
    Color progressColor,
  ) {
    final safeProgress = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    return Container(
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(20),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha: 0.12),
      //       blurRadius: 24,
      //       spreadRadius: 0.2,
      //       offset: const Offset(0, 10),
      //     ),
      //   ],
      // ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.12),
            blurRadius: 14,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.68),
                  Colors.white.withValues(alpha: 0.52),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: GoogleFonts.inter(
                        textStyle: Theme.of(context).textTheme.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: progressColor.withValues(alpha: 0.25),
                                blurRadius: 12,
                                spreadRadius: 0.2,
                              )
                            ],
                          ),
                          child: Text(
                            '${(safeProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodySmall,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                sizedBox(12),
                _buildSegmentedProgressBar(safeProgress, progressColor),
                sizedBox(12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achieved',
                            style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodySmall,
                              color: Colors.black54,
                            ),
                          ),
                          sizedBox(4),
                          Text(
                            _formatMetric(target, achieved),
                            style: GoogleFonts.montserrat(
                              textStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target',
                            style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodySmall,
                              color: Colors.black54,
                            ),
                          ),
                          sizedBox(4),
                          Text(
                            _formatMetric(target, targetAmount),
                            style: GoogleFonts.montserrat(
                              textStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthTargetsCard(
      BuildContext context, String monthLabel, List<Target> monthTargets) {
    final boxTargets =
        monthTargets.where((target) => !_isCollectionCategory(target)).toList();
    final collectionTargets =
        monthTargets.where(_isCollectionCategory).toList();

    final totalBoxesAchieved = boxTargets.fold<double>(
        0, (sum, target) => sum + _achievedAmount(target));
    final totalBoxesTarget = boxTargets.fold<double>(
        0, (sum, target) => sum + _targetAmount(target));
    final totalCollectionsAchieved = collectionTargets.fold<double>(
        0, (sum, target) => sum + _achievedAmount(target));
    final totalCollectionsTarget = collectionTargets.fold<double>(
        0, (sum, target) => sum + _targetAmount(target));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(
          color: Colors.black12, // Set the color of the border here
          width: 1, // Set the width of the border here
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0.0, 0.0),
            blurRadius: 24.0,
            spreadRadius: 0.3,
          ),
          // borderRadius: BorderRadius.all(Radius.circular(24)),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black12,
          //     offset: Offset(0.0, 0.0),
          //     blurRadius: 12.0,
          //     spreadRadius: 0.3,
          //   ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: GoogleFonts.montserrat(
                    textStyle: Theme.of(context).textTheme.titleLarge,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Container(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //   decoration: BoxDecoration(
              //     color: const Color(0x14008060),
              //     borderRadius: BorderRadius.circular(99),
              //   ),
              //   child: Text(
              //     '${monthTargets.length} categories',
              //     style: GoogleFonts.inter(
              //       textStyle: Theme.of(context).textTheme.bodySmall,
              //       fontWeight: FontWeight.w600,
              //       color: const Color(0xFF008060),
              //     ),
              //   ),
              // ),
            ],
          ),
          sizedBox(12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (boxTargets.isNotEmpty)
                _buildMonthSummaryChip(
                  context,
                  'Boxes',
                  '${_formatBoxesValue(totalBoxesAchieved)} / ${_formatBoxesValue(totalBoxesTarget)}',
                  const Color(0xFF2563EB),
                ),
              if (collectionTargets.isNotEmpty)
                _buildMonthSummaryChip(
                  context,
                  'Collections',
                  '${_formatCollectionValue(totalCollectionsAchieved)} / ${_formatCollectionValue(totalCollectionsTarget)}',
                  const Color(0xFF008060),
                ),
            ],
          ),
          sizedBox(16),
          ...monthTargets.map((target) {
            final achieved = _achievedAmount(target);
            final targetAmount = _targetAmount(target);
            final progress = targetAmount <= 0 ? 0.0 : achieved / targetAmount;
            final progressColor =
                progress < 0.5 ? Colors.red : const Color(0xFF008060);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTargetItem(
                context,
                target,
                _categoryName(target),
                achieved,
                targetAmount,
                progress,
                progressColor,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryChip(
    BuildContext context,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              textStyle: Theme.of(context).textTheme.bodySmall,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          sizedBox(4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              textStyle: Theme.of(context).textTheme.titleSmall,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // get the selected theme
    // final themeChange = Provider.of<DarkThemeProvider>(context);
    // bool value = themeChange.darkTheme;
    // var theme = Theme.of(context);

    // Uri facebookUrl;
    return Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
            opacity: _controller,
            child:

                // Stack(

                //   children: [

                //       FadeTransition(opacity: _controller,
                //         child:
                //         ScaleTransition(scale: CurvedAnimation(
                //                         parent: _controllerCards,
                //                         curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                       ),alignment: Alignment.center,
                //           child:

                //             Container(
                //               width: 350.0, // Replace with your desired size
                //               height: 350.0, // Replace with your desired size
                //               decoration: BoxDecoration(
                //                 boxShadow: [
                //                   BoxShadow(
                //                     color: const Color(0xFFFF93F4).withOpacity(0.5),
                //                     offset: const Offset(0.0, 0.0),
                //                     blurRadius: 44.0,
                //                     spreadRadius: 27.3,
                //                   ),
                //                 ],
                //                 // border: Border.all(color: Colors.black, width: 2.0),
                //                 shape: BoxShape.circle,
                //                 color: const Color(0xFFFF93F4).withOpacity(0.0),
                //               ),
                //             ),
                //         )
                //       ),
                //     Positioned(
                //       top: MediaQuery.of(context).size.height/2, // Randomly set top position
                //       left: (MediaQuery.of(context).size.width/2),
                //       child:
                //         FadeTransition(opacity: _controller,
                //           child:
                //           ScaleTransition(scale: CurvedAnimation(
                //                       parent: _controllerCards,
                //                       curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                     ),alignment: Alignment.center,
                //             child:

                //               Container(
                //                 width: 1250.0, // Replace with your desired size
                //                 height: 1250.0, // Replace with your desired size
                //                 decoration: BoxDecoration(
                //                   boxShadow: [
                //                     BoxShadow(
                //                       color: const Color(0xFF7CE3FF).withOpacity(0.3),
                //                       offset: const Offset(0.0, 0.0),
                //                       blurRadius: 44.0,
                //                       spreadRadius: 27.3,
                //                     ),
                //                   ],
                //                   // border: Border.all(color: Colors.black, width: 2.0),
                //                   shape: BoxShape.circle,
                //                   color: const Color(0xFF7CE3FF).withOpacity(0.0),
                //                 ),
                //               ),
                //           )
                //         ),
                //     ),
                // Positioned(
                //     top: MediaQuery.of(context).size.height/2, // Randomly set top position
                //     left: 0,
                //     child:
                //     FadeTransition(opacity: _controller,
                //       child:
                //       ScaleTransition(scale: CurvedAnimation(
                //                       parent: _controllerCards,
                //                       curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                     ),alignment: Alignment.center,
                //         child:

                //               Container(
                //                 width: 250.0, // Replace with your desired size
                //                 height: 250.0, // Replace with your desired size
                //                 decoration: BoxDecoration(
                //                   boxShadow: [
                //                     BoxShadow(
                //                       color: const Color(0xFFB07CFF).withOpacity(0.3),
                //                       offset: const Offset(0.0, 0.0),
                //                       blurRadius: 44.0,
                //                       spreadRadius: 27.3,
                //                     ),
                //                   ],
                //                   // border: Border.all(color: Colors.black, width: 2.0),
                //                   shape: BoxShape.circle,
                //                   color: const Color(0xFFB07CFF).withOpacity(0.0),
                //                 ),
                //               ),
                //           )
                //       )
                //     ),

                //     Positioned(
                //     top: MediaQuery.of(context).size.height/2 - 200, // Randomly set top position
                //     left: MediaQuery.of(context).size.width - 300,
                //     // right: 0,
                //     child:

                //       FadeTransition(opacity: _controller,
                //       child:
                //       ScaleTransition(scale: CurvedAnimation(
                //                       parent: _controllerCards,
                //                       curve: Curves.ease, // Use Curves.easeIn for ease-in animation
                //                     ),alignment: Alignment.center,
                //         child:
                //           Container(
                //             width: 350.0, // Replace with your desired size
                //             height: 350.0, // Replace with your desired size
                //             decoration: BoxDecoration(
                //               boxShadow: [
                //                 BoxShadow(
                //                   color: const Color(0xFFFFCB7C).withOpacity(0.4),
                //                   offset: const Offset(0.0, 0.0),
                //                   blurRadius: 44.0,
                //                   spreadRadius: 27.3,
                //                 ),
                //               ],
                //               // border: Border.all(color: Colors.black, width: 2.0),
                //               shape: BoxShape.circle,
                //               color: const Color(0xFFFFCB7C).withOpacity(0.0),
                //             ),
                //           ),
                //         )
                //       ),
                //     ),

                Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                  child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Column(
                            // child: CardRound(Palette.lightBackground, Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              AppHeader('Targets Report', '', 1),
                              Text(
                                'Targets Summary Report',
                                style: GoogleFonts.inter(
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF008060)),
                              ),
                              Center(
                                child: connectionStatus
                                    ? sizedBox(0)
                                    : Text(
                                        'No network detected. Try again later!',
                                        style: GoogleFonts.inter(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),

                          sizedBox(8),
                          targetsDataList.isNotEmpty
                              ? Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Total Boxes till date:',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500)),
                                        Text(
                                            ' ${_formatBoxesValue(targetsDataList.where((target) => !_isCollectionCategory(target)).fold<double>(0, (sum, target) => sum + _achievedAmount(target)))}',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Total Collections till date:',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500)),
                                        Text(
                                            ' ${_formatCollectionValue(targetsDataList.where(_isCollectionCategory).fold<double>(0, (sum, target) => sum + _achievedAmount(target)))}',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                )
                              : sizedBox(0),
                          sizedBox(8),
                          Expanded(
                            child: targetsDataList.isEmpty
                                ? Center(
                                    child: Text(
                                      'No targets available',
                                      style: GoogleFonts.inter(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : Container(
                                    margin:
                                        const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                    // color: Colors.white10,
                                    child: RefreshIndicator(
                                      onRefresh: _refreshList,
                                      child: ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        controller: scrollController,
                                        children: _groupedTargetsByMonth()
                                            .map((entry) =>
                                                _buildMonthTargetsCard(context,
                                                    entry.key, entry.value))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                          ),

                          // loader while fetching data
                          targetsDataProgress
                              ? const AppProgress(
                                  height: 30,
                                  width: 30,
                                )
                              : new SizedBox(
                                  height: 0,
                                ),
                        ],
                      ))),
            )));
  }
}

// getting image
Map<String, bool> imageExistenceCache =
    {}; // A cache to store image existence results
