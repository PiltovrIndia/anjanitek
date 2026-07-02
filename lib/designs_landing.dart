import 'dart:convert';
import 'dart:ui';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/offers.dart';
import 'package:anjanitek/designs.dart';
import 'package:anjanitek/orders.dart';
import 'package:anjanitek/orders_admin.dart';
import 'package:anjanitek/stock_reservations.dart';
import 'package:anjanitek/stock_reservations_admin.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/design_details.dart';
import 'package:anjanitek/utils/designoftheday.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;

class DesignsLanding extends StatefulWidget {
  const DesignsLanding({super.key});


  @override
  _DesignsLandingState createState() => _DesignsLandingState();
}

class _DesignsLandingState extends State<DesignsLanding> with TickerProviderStateMixin {
  bool _isLoadingTags = true;
  List<ProductTag> DesignsLanding = [];
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
    _controller = AnimationController( vsync: this, duration: const Duration(milliseconds: 1300),)..repeat(reverse: false); // Loop the animation for a dynamic effect
    
      checkForUser();
      getProductTags(context);
  }

    // get user details
    void checkForUser() async {
        // no profile exists
        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
            name = prefs.get(Constants.name) as String;
            id = prefs.get(Constants.id) as String;
            role = prefs.get(Constants.role) as String;
            isActive = prefs.get(Constants.isActive) as int;
            
          });
        }

        getDesignOfTheDay().then((value) {
          // print(value);
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
      setState(() { _isLoadingTags = true; });
      
      Map<String, String> queryParams = { };
      // API call
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U0", queryParams)), headers: {"Accept": "application/json"});
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      
      if(jsonObject['status'] == 200){
          var showCataloguesData = jsonObject['data'] as List;
      
            if(showCataloguesData.isNotEmpty){
            
              List<ProductTag> productTagsList = showCataloguesData.map<ProductTag>((json) => ProductTag.fromJson(json)).toList();
              setState(() {
                  // Get new user data
                    productTags = productTagsList;
                    uniqueProductTypes = productTagsList.map((tag) => tag.type).whereType<String>().toSet().toList();
                    DesignsLanding = productTagsList.where((tag) => tag.type == 'Series').toList();
                    DesignsLanding.sort((a, b) => a.name!.compareTo(b.name!));
                  _isLoadingTags = false;


                  for (int i = 0; i < DesignsLanding.length; i++) {
                    final controller = AnimationController( vsync: this, duration: const Duration(milliseconds: 600), );
                    final animation = Tween<Offset>( begin: const Offset(0, 0.3), end: Offset.zero, ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
                    final fade = Tween<double>( begin: 0, end: 1, ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

                    _controllers.add(controller);
                    _slideAnimations.add(animation);
                    _fadeAnimations.add(fade);

                    Future.delayed(Duration(milliseconds: i * 100), () {
                      controller.forward();
                    });
                  }
                });
            }
      }
      else {
          setState(() { _isLoadingTags = false;
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
    //           items: DesignsLanding,
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
        title: Text('Designs', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
      ),
      body: 
      
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: 
            Container(
              //   alignment: Alignment.center,
            //   width: MediaQuery.of(context).size.width-32,
                    // padding: EdgeInsets.all(16),
                    // color: Color(0xFF048563),
                    // color: Colors.white,
                    // decoration: const BoxDecoration(
                    //   // ),
                    //     gradient: LinearGradient(
                    //     colors: [Color(0xFFF36C31), Color(0xFFFF7043), Color(0xFFFF8B59)],
                    //     begin: Alignment.topCenter,
                    //     end: Alignment.bottomCenter,
                    //     stops: [0.0, 0.5, 1.0],
                    //     ),
                    //                   ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 16,
                          children: [


                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                decoration: BoxDecoration(
                                // color: const Color(0xFFFEFEFE),

                                        border: Border.all(color: Colors.white, width: 0.5),
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          colors: [const Color.fromARGB(255, 255, 238, 212), Colors.pink.shade200],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12, // Shadow color
                                            // color: Colors.black12, // Shadow color
                                            spreadRadius: 5, // How much the shadow spreads
                                            blurRadius: 10, // How blurred the shadow is
                                            offset: Offset(0, 10), // Offset in x, y direction
                                          ),
                                        ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Image.asset('assets/designday.webp',width: 120.0), sizedBox(4),
                                      Expanded(child: 
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 6,
                                        children: [
                                          
                                          Text('Design of the day!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                                          
                                          Text('Check out today\'s exciting design.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                                          sizedBox(8),

                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                                              
                                              textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              elevation: 5, // Shadow depth
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
                                            child: 
                                            checkDesignOfTheDayList == false ?
                                            const AppProgress(height: 30, width: 30,) : 
                                            const Text('View Design', style: TextStyle(color: Colors.black)),
                                          ),
                                          
                                        ]
                                            
                                      )
                                      )
                                    ],
                                  )
                                  
                            ),

                            Container(
                              // height: 200,
                              width: MediaQuery.of(context).size.width-32,
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              // padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange, width: 0.5),
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  colors: [Colors.orange.shade200, Colors.deepOrangeAccent.shade100],
                                  // colors: [Color(0xFF008060), Colors.green.shade800],
                                  // colors: [Colors.amber.shade400, Colors.green.shade800],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12, // Shadow color
                                    // color: Colors.black12, // Shadow color
                                    spreadRadius: 5, // How much the shadow spreads
                                    blurRadius: 10, // How blurred the shadow is
                                    offset: Offset(0, 10), // Offset in x, y direction
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 8),
                                  child: 
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(12,24,12,12),
                                    color: Colors.white10, // Translucent effect
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 250,
                                          // color: Colors.blue,
                                          child: Stack(
                                            children: [
                                              Transform.rotate(
                                                angle: -0.4,
                                                child: Container(
                                                        width: 100.0, // Adjust the size as needed
                                                        height: 100.0, // Adjust the size as needed
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          image: const DecorationImage(
                                                            image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F81001.jpeg?alt=media'),
                                                            fit: BoxFit.cover,
                                                          ),
                                                          borderRadius: BorderRadius.circular(16),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              color: Colors.black12, // Shadow color
                                                              spreadRadius: 5, // How much the shadow spreads
                                                              blurRadius: 20, // How blurred the shadow is
                                                              offset: Offset(0, 10), // Offset in x, y direction
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ),

                                                  Positioned(top: 0, left: 60, right: 60,
                                                  child: Transform.rotate(
                                                          angle: -0.3,
                                                          child: Container(
                                                                  width: 100.0, // Adjust the size as needed
                                                                  height: 100.0, // Adjust the size as needed
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    image: const DecorationImage(
                                                                      
                                                                      image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F51007_F10.jpeg?alt=media'),
                                                                      fit: BoxFit.cover,
                                                                    ),
                                                                    borderRadius: BorderRadius.circular(16),
                                                                    boxShadow: const [
                                                                      BoxShadow(
                                                                        color: Colors.black12, // Shadow color
                                                                        spreadRadius: 5, // How much the shadow spreads
                                                                        blurRadius: 20, // How blurred the shadow is
                                                                        offset: Offset(0, 10), // Offset in x, y direction
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ),
                                                  ),
                                                  Positioned(top: 0, right: 0,
                                                  child: Transform.rotate(
                                                          angle: 0.1,
                                                          child: Container(
                                                                  width: 100.0, // Adjust the size as needed
                                                                  height: 100.0, // Adjust the size as needed
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    image: const DecorationImage(
                                                                      image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/tiles%2F21033.jpeg?alt=media'),
                                                                      // image: NetworkImage('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/51010.jpeg?alt=media'),
                                                                      fit: BoxFit.cover,
                                                                    ),
                                                                    borderRadius: BorderRadius.circular(16),
                                                                    boxShadow: const [
                                                                      BoxShadow(
                                                                        color: Colors.black12, // Shadow color
                                                                        spreadRadius: 5, // How much the shadow spreads
                                                                        blurRadius: 20, // How blurred the shadow is
                                                                        offset: Offset(0, 10), // Offset in x, y direction
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                            ),
                                                  ),
                                            ],
                                          ),
                                        ),
                                            
                                        
                                        sizedBox(24),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                                            
                                            textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            elevation: 5, // Shadow depth
                                          ),
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const Designs()));
                                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                                          },
                                          child: const Text('Browse Designs', style: TextStyle(color: Colors.black)),
                                        ),

                                        (role.toLowerCase() == Constants.superAdmin.toLowerCase() || role.toLowerCase() == Constants.dealer.toLowerCase()
                                         || role.toLowerCase() == Constants.salesExecutive.toLowerCase() || role.toLowerCase() == Constants.salesManager.toLowerCase() || role.toLowerCase() == Constants.stateHead.toLowerCase()) ?
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                                            
                                            textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            elevation: 5, // Shadow depth
                                          ),
                                          onPressed: () {
                                            role.toLowerCase() == Constants.dealer.toLowerCase() ?
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const Orders()))
                                            :
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersAdmin()));
                                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                                          },
                                          child: const Text('Stock Reservations', style: TextStyle(color: Colors.black)),
                                        )
                                         : sizedBox(0)
                                         ,
                                        
                                        
                                      ],
                                    )
                                    
                                  ),
                                ),
                              ),
                            ),

                          name.isEmpty ? sizedBox(0) : 
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 200),
                                decoration: BoxDecoration(
                                // color: const Color(0xFFFEFEFE),

                                        border: Border.all(color: Colors.white, width: 0.5),
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          // colors: [Color(0xFFF6F1E7), Colors.orange],
                                          colors: [const Color.fromARGB(255, 255, 238, 212), Colors.pink.shade200],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12, // Shadow color
                                            // color: Colors.black12, // Shadow color
                                            spreadRadius: 5, // How much the shadow spreads
                                            blurRadius: 10, // How blurred the shadow is
                                            offset: Offset(0, 10), // Offset in x, y direction
                                          ),
                                        ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: 
                              Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      Image.asset('assets/offers.webp',width: 120.0), sizedBox(4),
                                      Expanded(child: 
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 6,
                                        children: [
                                          
                                          Text('Grab the offers!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontSize: 20, fontWeight: FontWeight.w600)),
                                          
                                          Text('AnjaniTek brings exciting offers to you.', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87)),
                                          sizedBox(8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFFFFF), // Dark background color
                                              
                                              textStyle: const TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              elevation: 5, // Shadow depth
                                            ),
                                            onPressed: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => const OffersForDealer()));
                                              // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListing()));
                                            },
                                            child: const Text('View Offers', style: TextStyle(color: Colors.black)),
                                          ),
                                          
                                        ]
                                            
                                      )
                                      )
                                    ],
                                  )
                            ),



                             
                          ]
                              ),
                              ),

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

  const CardStack({required this.items, required this.animationValue});

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
      duration: const Duration(milliseconds: 500), // Animation duration for page transitions
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
      child: 
    PageView.builder(
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
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0); // Scale and opacity based on distance
                    }

                    return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
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
    )
    );
  }
}





class CrazyPageViewScreen extends StatefulWidget {
  final List<ProductTag> items;
  
  const CrazyPageViewScreen({required this.items});

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
    _pageController = PageController(viewportFraction: 0.8); // Show 80% of each page
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Animation duration for page transitions
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
        color: Colors.deepOrange, // Black background for contrast (optional, match your design)
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
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0); // Scale and opacity based on distance
                    }

                    return Transform.scale(
                      scale: value, // Scale down cards further from the center
                      child: Opacity(
                        opacity: value, // Fade out cards further from the center
                        child: Transform.translate(
                          offset: Offset(0, -50 * (1 - value)), // Vertical offset for layering effect
                          child: CardWidget(
                            imagePath: 'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/${widget.items[index].image}?alt=media',
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

  const CardWidget({required this.imagePath, required this.isCenter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, // Card width (adjust as needed)
      height: 450, // Card height (adjust as needed)
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isCenter ? Colors.blueAccent : Colors.transparent, // Highlight center card
          width: 2,
        ),
      ),
      child: isCenter
          ? const Center(
              child: Text('Check text',
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
