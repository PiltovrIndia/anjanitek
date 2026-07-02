import 'dart:convert';

import 'package:anjanitek/collection_card.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/offers.dart';
import 'package:anjanitek/designs_listing.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/design_details.dart';
import 'package:anjanitek/utils/designoftheday.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:anjanitek/utils/shimmer_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

class ProductCollections extends StatefulWidget {
  const ProductCollections({super.key});

  @override
  _ProductCollectionsState createState() => _ProductCollectionsState();
}

class _ProductCollectionsState extends State<ProductCollections>
    with TickerProviderStateMixin {
  bool _isLoadingTags = true;
  List<ProductTag> productCollections = [];
  List<ProductTag> productTags = [];
  List<String> uniqueProductTypes = [];
  List<int> selectedTagIds = [];
  late AnimationController _controller;

  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _slideAnimations = [];
  List<Animation<double>> _fadeAnimations = [];

  late SharedPreferences prefs;
  String name = '', id = '', role = '';
  int isActive = 1;

  List<Product> designOfTheDayList = [];
  List<ProductTag> productTagsList = [];
  bool checkDesignOfTheDayList = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1300),
    )..repeat(reverse: false); // Loop the animation for a dynamic effect

    checkForUser();
    getProductTags(context);
  }

  // get user details
  void checkForUser() async {
    // no profile exists
    prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(Constants.name)) {
      setState(() {
        name = prefs.get(Constants.name) as String;
        id = prefs.get(Constants.id) as String;
        role = prefs.get(Constants.role) as String;
        isActive = prefs.get(Constants.isActive) as int;
      });
    }

    getDesignOfTheDay().then((value) {
      
      final Map<String, dynamic> map = value as Map<String, dynamic>;
        
      setState(() {
        designOfTheDayList = map['products'] as List<Product>? ?? [];
        productTagsList = map['tags'] as List<ProductTag>? ?? [];
        checkDesignOfTheDayList = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _controllers.forEach((controller) {
      controller.dispose();
    });
    _slideAnimations.clear();
    _fadeAnimations.clear();
    super.dispose();
  }

  // Get product tags
  void getProductTags(BuildContext context) async {
// print('checking1');
    setState(() {
      _isLoadingTags = true;
    });

    Map<String, String> queryParams = {};
    // API call
    var result = await get(
        Uri.parse(APIUrls.getUrl(
            "${APIUrls.products}${APIUrls.pass}/U0", queryParams)),
        headers: {"Accept": "application/json"});
    Map<String, dynamic> jsonObject = jsonDecode(result.body);
    // print(result.body);

    if (jsonObject['status'] == 200) {
      var showCataloguesData = jsonObject['data'] as List;

      if (showCataloguesData.isNotEmpty) {
        List<ProductTag> productTagsList = showCataloguesData
            .map<ProductTag>((json) => ProductTag.fromJson(json))
            .toList();
        setState(() {
          // Get new user data
          productTags = productTagsList;
          uniqueProductTypes = productTagsList
              .map((tag) => tag.type)
              .whereType<String>()
              .toSet()
              .toList();
          productCollections =
              productTagsList.where((tag) => tag.type == 'Series').toList();
          productCollections.sort((a, b) => a.name!.compareTo(b.name!));
          _isLoadingTags = false;

          for (int i = 0; i < productCollections.length; i++) {
            final controller = AnimationController(
              vsync: this,
              duration: Duration(milliseconds: 600),
            );
            final animation = Tween<Offset>(
              begin: Offset(0, 0.3),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut));
            final fade = Tween<double>(
              begin: 0,
              end: 1,
            ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeIn));

            _controllers.add(controller);
            _slideAnimations.add(animation);
            _fadeAnimations.add(fade);

            Future.delayed(Duration(milliseconds: i * 100), () {
              mounted ? controller.forward() : null;
            });
          }
        });
      }
    } else {
      setState(() {
        _isLoadingTags = false;
        // showToast(context, 'Error, try again later!',Constants.error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   backgroundColor: Colors.deepOrange,
    //   body:
    //   Center(
    //           child: CardStack(
    //           items: productCollections,
    //           animationValue: _controller.value,
    //           ),
    //         ),
    // );

    return Scaffold(
      backgroundColor: Colors.white,
      // backgroundColor: Color(0xFFF36C31),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: Text(
          'Designs',
          style: GoogleFonts.montserrat(
              textStyle: Theme.of(context).textTheme.headlineSmall,
              fontWeight: FontWeight.bold),
        ),
      ),
      body:

          // Expanded(
          //   child:
          Container(
        // padding: EdgeInsets.all(16),
        // color: Color(0xFF048563),
        decoration: const BoxDecoration(
          color: Colors.white,
          // gradient: LinearGradient(
          //   colors: [Color(0xFFF36C31), Color(0xFFFF7043), Color(0xFFFF8B59)],
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   stops: [0.0, 0.5, 1.0],
          // ),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Container(
              //     margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              //     decoration: BoxDecoration(
              //       // color: const Color(0xFFFEFEFE),

              //       border: Border.all(color: Colors.white, width: 0.5),
              //       borderRadius: BorderRadius.circular(24),
              //       gradient: LinearGradient(
              //         colors: [
              //           const Color.fromARGB(255, 255, 238, 212),
              //           Colors.pink.shade200
              //         ],
              //         begin: Alignment.topLeft,
              //         end: Alignment.bottomRight,
              //       ),
              //       boxShadow: const [
              //         BoxShadow(
              //           color: Colors.black12, // Shadow color
              //           // color: Colors.black12, // Shadow color
              //           spreadRadius: 5, // How much the shadow spreads
              //           blurRadius: 10, // How blurred the shadow is
              //           offset: Offset(0, 10), // Offset in x, y direction
              //         ),
              //       ],
              //     ),
              //     child:
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image.asset('assets/designday.webp',width: 60.0), sizedBox(4),
                    // Expanded(child:
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if(checkDesignOfTheDayList == false){
                            getDesignOfTheDay().then((value) {
                            // print(value);
                              final Map<String, dynamic> map = value as Map<String, dynamic>;
                              
                                
                              setState(() {
                                designOfTheDayList = map['products'] as List<Product>? ?? [];
                                productTagsList = map['tags'] as List<ProductTag>? ?? [];
                                checkDesignOfTheDayList = true;
                              });

                              if(designOfTheDayList.isEmpty){
                                showToast(context, 'No Design of the Day available!', Constants.warning);
                                return;
                              }
                              Navigator.push(context, MaterialPageRoute(builder: (context) => DesignDetails(product: designOfTheDayList[0], productTags: productTagsList)));
                            });
                          }
                          else {
                            
                            if(designOfTheDayList.isEmpty){
                                showToast(context, 'No Design of the Day available!', Constants.warning);
                                return;
                              }
                              Navigator.push(context, MaterialPageRoute(builder: (context) => DesignDetails(product: designOfTheDayList[0], productTags: productTagsList)));
                          }
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                // Color(0xFFF8F8F8),
                                // Color(0xFFE7EEF9),
                                Color.fromARGB(255, 255, 238, 212),
                                Color.fromRGBO(244, 143, 177, 1),

                                // Color.fromRGBO(255, 204, 128, 1), Color.fromRGBO(255, 158, 128, 1)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/designday.webp',
                                      width: 40.0),
                                  sizedBox(4),
                                  checkDesignOfTheDayList == false
                                      ? const AppProgress(
                                          height: 30,
                                          width: 30,
                                        )
                                      : const Text('Design of the day',
                                          style:
                                              TextStyle(color: Colors.black)),
                                ]),
                          ),
                        )),

                    // const SizedBox(width: 8),

                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent, // Dark background color
                              shadowColor: Colors.transparent, // Remove shadow
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 5, // Shadow depth
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const OffersForDealer()));
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                // Color(0xFFF8F8F8),
                                // Color(0xFFE7EEF9),
                                // Color.fromARGB(255, 255, 238, 212),
                                // Color.fromRGBO(244, 143, 177, 1),

                                Color.fromRGBO(255, 204, 128, 1), Color.fromRGBO(255, 158, 128, 1)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/offers.webp',
                                      width: 40.0),
                                  sizedBox(4),
                                  checkDesignOfTheDayList == false
                                      ? const AppProgress(
                                          height: 30,
                                          width: 30,
                                        )
                                      : const Text('Grab the offers',
                                          style:
                                              TextStyle(color: Colors.black)),
                                ]),
                          ),
                        )),
                    // )
                  ],
                ),
                // )
              )
              ,

              (_isLoadingTags && productCollections.isEmpty)
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // _isLoadingTags? const AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                        ShimmerText(
                          text: 'Loading collections..',
                          style: GoogleFonts.inter(
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14),
                        ),
                      ],
                    ))
                  : Expanded(
                      // height: MediaQuery.of(context).size.height - 120,

                      child: SingleChildScrollView(
                        child: SizedBox(
                          height: productCollections.length * 140.0 + 300,
                          width: MediaQuery.of(context).size.width,
                          child: Stack(
                            children: List.generate(productCollections.length,
                                (index) {
                              final double topOffset = index * 140;
                              return AnimatedPositioned(
                                duration:
                                    Duration(milliseconds: 500 + (index * 100)),
                                curve: Curves.easeInOut,
                                left: 16,
                                right: 16,
                                top: topOffset,
                                bottom:
                                    null, // Ensure bottom is null if not used
                                child: GestureDetector(
                                  // onTap: () {
                                  //   setState(() {
                                  //     // Update the topOffset or other properties dynamically here
                                  //   });
                                  // },
                                  onTap: () {
                                    selectedTagIds.clear();
                                    selectedTagIds
                                        .add(productCollections[index].tagId!);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DesignsListing(
                                                  alreadySelectedTagIds:
                                                      selectedTagIds,
                                                )));
                                  },
                                  child: AnimatedOpacity(
                                      opacity: 1.0,
                                      duration: Duration(
                                          milliseconds: 500 + (index * 100)),
                                      curve: Curves.easeInOut,
                                      child: SlideTransition(
                                        position: _slideAnimations[index],
                                        child: FadeTransition(
                                          opacity: _fadeAnimations[index],
                                          child: Card(
                                            elevation: 12,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(50),
                                                topRight: Radius.circular(50),
                                                bottomLeft: Radius.circular(50),
                                                bottomRight:
                                                    Radius.circular(50),
                                              ),
                                            ),
                                            child: Container(
                                              height: 300,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(50),
                                                  topRight: Radius.circular(50),
                                                  bottomLeft:
                                                      Radius.circular(50),
                                                  bottomRight:
                                                      Radius.circular(50),
                                                ),
                                                // gradient: LinearGradient(
                                                //   colors: [productCollections[index], productCollections[index].withOpacity(0.7)],
                                                //   begin: Alignment.topLeft,
                                                //   end: Alignment.bottomRight,
                                                // ),
                                              ),
                                              // padding: EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  CollectionCard(

                                                      // imageUrl: productCollections[index].image!,
                                                      design:
                                                          productCollections[
                                                              index],
                                                      media: productCollections[
                                                              index]
                                                          .image!,
                                                      // media: 1,
                                                      imageHeight:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.6,
                                                      imageWidth:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.8,
                                                      zoom: 2
                                                      // elevation: 4.0,
                                                      // onTap: () {
                                                      //   // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails(product: products[index])));
                                                      // },
                                                      ),

                                                  // if (productCollections[index].isNotEmpty)
                                                  // Column(
                                                  //   crossAxisAlignment: CrossAxisAlignment.start,
                                                  //   children: [
                                                  //     // Text('Total Balance', style: TextStyle( color: Colors.white60, fontSize: 14)),
                                                  //     Text(productCollections[index].description!, style: TextStyle( fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                                                  //   ],
                                                  // )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // ListView.builder(
                      //   scrollDirection: Axis.horizontal,
                      //   itemCount: productCollections.length,
                      //   itemBuilder: (context, index) {
                      //     return
                      //     InkWell(
                      //       onTap: () {
                      //         selectedTagIds.clear();
                      //         selectedTagIds.add(productCollections[index].tagId!);
                      //         Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing(alreadySelectedTagIds: selectedTagIds,)));
                      //       },
                      //       child:
                      //     Container(
                      //     // margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      //     child:
                      //     Column(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         CardInteractive(

                      //           // imageUrl: productCollections[index].image!,
                      //           design: productCollections[index].image!,
                      //           media: productCollections[index].image!,
                      //           // media: 1,
                      //           imageHeight: MediaQuery.of(context).size.height * 0.6,
                      //           imageWidth: MediaQuery.of(context).size.width * 0.8,
                      //           zoom:2
                      //           // elevation: 4.0,
                      //           // onTap: () {
                      //           //   // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails(product: products[index])));
                      //           // },
                      //           ),
                      //           Text(productCollections[index].name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18), ),
                      //           Text(productCollections[index].description!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), ),
                      //       ],
                      //     )

                      //     ),
                      //     );
                      //   },
                      //   ),

                      // Stack(
                      //   children: productCollections.asMap().entries.map((entry) {
                      //   int index = entry.key;
                      //   ProductTag product = entry.value;
                      //   return Positioned(
                      //     top: index * 40.0, // Adjust the value to control the overlap
                      //     left: 0,
                      //     right: 0,
                      //     child: InkWell(
                      //     onTap: () {
                      //       selectedTagIds.clear();
                      //       selectedTagIds.add(product.tagId!);
                      //       Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing(alreadySelectedTagIds: selectedTagIds,)));
                      //     },
                      //     child: Transform(
                      //       transform: Matrix4.rotationY(0.1 * index), // Apply y rotation
                      //       alignment: Alignment.center,
                      //       child: Container(
                      //       child: Column(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //         CardInteractive(
                      //           imageUrl: product.image!,
                      //           imageHeight: MediaQuery.of(context).size.height * 0.6,
                      //           imageWidth: MediaQuery.of(context).size.width * 0.8,
                      //         ),
                      //         Text(product.name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18), ),
                      //         Text(product.description!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), ),
                      //         ],
                      //       ),
                      //       ),
                      //     ),
                      //     ),
                      //   );
                      //   }).toList(),

                      // ),
                      // children: productCollections.asMap().entries.map((entry) {
                      //   int index = entry.key;
                      //   ProductTag product = entry.value;
                      //   return Positioned(
                      //   top: index * 40.0, // Adjust the value to control the overlap
                      //   left: 0,
                      //   right: 0,
                      //   child: InkWell(
                      //     onTap: () {
                      //     selectedTagIds.clear();
                      //     selectedTagIds.add(product.tagId!);
                      //     Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing(alreadySelectedTagIds: selectedTagIds,)));
                      //     },
                      //     child: Container(
                      //     child: Column(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //       CardInteractive(
                      //         imageUrl: product.image!,
                      //         imageHeight: MediaQuery.of(context).size.height * 0.6,
                      //         imageWidth: MediaQuery.of(context).size.width * 0.8,
                      //       ),
                      //       Text(product.name!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18), ),
                      //       Text(product.description!, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), ),
                      //       ],
                      //     ),
                      //     ),
                      //   ),
                      //   );
                      // }
                      // ).toList(),
                      // ),
                    ),
            ]),

        // sizedBox(16),

        // )

        // ),
      ),
      // sizedBox(16),

      //   ],
      // ),
    );
  }
}

class CardStack extends StatefulWidget {
  final List<ProductTag> items;
  final double animationValue;

  CardStack({required this.items, required this.animationValue});

  @override
  _CardStackState createState() => _CardStackState();
}

class _CardStackState extends State<CardStack> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 500), // Animation duration for page transitions
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        // width: MediaQuery.of(context).size.width * 0.8,
        child: PageView.builder(
          hitTestBehavior: HitTestBehavior.translucent,
          pageSnapping: true,
          controller: _pageController,
          itemCount: widget.items.length,
          onPageChanged: (int index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            double scale = _currentPage == index ? 1.0 : 0.9;
            double opacity = _currentPage == index ? 1.0 : 0.5;

            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.3))
                      .clamp(0.0, 1.0); // Scale and opacity based on distance
                }

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/${widget.items[index].image}?alt=media',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

            // return Transform.scale(
            //   scale: scale,
            //   child: Opacity(
            //     opacity: opacity,
            //     child: Container(
            //       height: MediaQuery.of(context).size.height * 0.5,
            //       width: MediaQuery.of(context).size.width,
            //       margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(10),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.black.withOpacity(0.3),
            //             spreadRadius: 2,
            //             blurRadius: 5,
            //             offset: Offset(0, 3),
            //           ),
            //         ],
            //       ),
            //       child: ClipRRect(
            //         borderRadius: BorderRadius.circular(10),
            //         child: Image.network(
            //           'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/${widget.items[index].image}?alt=media',
            //           fit: BoxFit.cover,
            //         ),
            //       ),
            //     ),
            //   ),
            // );
          },
        ));
  }
}

class CrazyPageViewScreen extends StatefulWidget {
  final List<ProductTag> items;

  CrazyPageViewScreen({required this.items});

  @override
  _CrazyPageViewScreenState createState() => _CrazyPageViewScreenState();
}

class _CrazyPageViewScreenState extends State<CrazyPageViewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(viewportFraction: 0.8); // Show 80% of each page
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 500), // Animation duration for page transitions
    )..repeat(reverse: true); // Loop for subtle animation
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors
            .deepOrange, // Black background for contrast (optional, match your design)
        child: Center(
          child: SizedBox(
            height: 500, // Adjust height as needed for your cards
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(
                          0.0, 1.0); // Scale and opacity based on distance
                    }

                    return Transform.scale(
                      scale: value, // Scale down cards further from the center
                      child: Opacity(
                        opacity:
                            value, // Fade out cards further from the center
                        child: Transform.translate(
                          offset: Offset(
                              0,
                              -50 *
                                  (1 -
                                      value)), // Vertical offset for layering effect
                          child: CardWidget(
                            imagePath:
                                'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/${widget.items[index].image}?alt=media',
                            isCenter: index == _pageController.page?.round(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final String imagePath;
  final bool isCenter;

  CardWidget({required this.imagePath, required this.isCenter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, // Card width (adjust as needed)
      height: 450, // Card height (adjust as needed)
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath), // Use your image assets here
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isCenter
              ? Colors.blueAccent
              : Colors.transparent, // Highlight center card
          width: 2,
        ),
      ),
      child: isCenter
          ? Center(
              child: Text(
                'Check text',
                // 'Card ${items.indexOf(imagePath) + 1}', // Optional text for the center card
                style: TextStyle(color: Colors.white, fontSize: 20, shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ]),
              ),
            )
          : null,
    );
  }
}
