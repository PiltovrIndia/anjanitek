import 'dart:convert';

import 'package:anjanitek/card_interactive.dart';
import 'package:anjanitek/modals/product.dart';
import 'package:anjanitek/modals/product_tag.dart';
import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/design_details.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/shimmer_text.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProductsListing extends StatefulWidget {

  final List<int> alreadySelectedTagIds;
  ProductsListing({required this.alreadySelectedTagIds});

  @override
  _ProductsListingState createState() => _ProductsListingState();
}

class _ProductsListingState extends State<ProductsListing> {
  bool _isLoadingTags = true;
  bool _isLoadingProducts = true;
  int offset = 0;
  int searchOffset = 0;
  int listingCount = 0;
  String searchPrompt = '';
  TextEditingController searchController = TextEditingController();
  // List<ProductTag> productTags = [
  //   ProductTag(tagId: 1, name: 'Small', description: 'Small Size', type: 'Size'),
  //   ProductTag(tagId: 2, name: 'Medium', description: 'Medium Size', type: 'Size'),
  //   ProductTag(tagId: 3, name: 'Large', description: 'Large Size', type: 'Size'),
  //   ProductTag(tagId: 4, name: 'Red', description: 'Red Color', type: 'Color'),
  //   ProductTag(tagId: 5, name: 'Blue', description: 'Blue Color', type: 'Color'),
  //   ProductTag(tagId: 6, name: 'Cotton', description: 'Cotton Material', type: 'Material'),
  //   ProductTag(tagId: 7, name: 'Polyester', description: 'Polyester Material', type: 'Material'),
  //   ProductTag(tagId: 8, name: 'T-Shirt', description: 'T-Shirt Type', type: 'Type'),
  //   ProductTag(tagId: 9, name: 'Jeans', description: 'Jeans Type', type: 'Type'),
  //   ProductTag(tagId: 10, name: 'Nike', description: 'Nike Brand', type: 'Brand'),
  //   ProductTag(tagId: 11, name: 'Adidas', description: 'Adidas Brand', type: 'Brand'),
  //   ProductTag(tagId: 12, name: 'Men', description: 'Men Category', type: 'Category'),
  //   ProductTag(tagId: 13, name: 'Women', description: 'Women Category', type: 'Category'),
  // ];
  // List<String> uniqueProductTypes = ['Size', 'Color', 'Material', 'Type', 'Brand', 'Category'];
  
  List<Product> filteredProducts = [];
  List<Product> products = [];
  List<ProductTag> productTags = [];
  List<String> uniqueProductTypes = [];
  List<int> selectedTagIds = [];

  @override
  void initState() {
    super.initState();

    setState(() {
      selectedTagIds = widget.alreadySelectedTagIds;
    });
    getProducts(context);
    getProductTags(context);
  }

  // Get product tags
  void getProductTags(BuildContext context) async {

      setState(() { _isLoadingTags = true; });
      
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
                  uniqueProductTypes = productTagsList.map((tag) => tag.type).whereType<String>().toSet().toList();
                  // sizes = productTagsList.where((tag) => tag.type == 'Size').toList();
                  _isLoadingTags = false;
              });
            }
      }
      else {
          setState(() { _isLoadingTags = false;
            // showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }
  
  // Get products using applied filters
  void getProducts(BuildContext context) async {

      setState(() { _isLoadingProducts = true; });
      
      Map<String, String> queryParams = { };
      var ids = selectedTagIds.isNotEmpty ? selectedTagIds.join(',') : '39';
      // API call
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U3/$ids/$offset", queryParams)), headers: {"Accept": "application/json"});
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      if(jsonObject['status'] == 200){
          var showCataloguesData = jsonObject['data'] as List;
      
            if(showCataloguesData.isNotEmpty){
            
              List<Product> productsList = showCataloguesData.map<Product>((json) => Product.fromJson(json)).toList();
              setState(() {
                  // Append to the existing list
                    products.addAll(productsList);
                    filteredProducts.addAll(productsList);
                    listingCount = jsonObject['count'] as int;
                  _isLoadingProducts = false;
                });
            }
      }
      else {
          setState(() { _isLoadingProducts = false;
            // showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }
  
  // Get products using search prompt
  void getProductsBySearch(BuildContext context) async {
// print("Yes");
      setState(() { _isLoadingProducts = true; });
      
      // API call
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U4/${searchController.text.trim()}/$searchOffset", {})), headers: {"Accept": "application/json"});
      Map<String, dynamic> jsonObject = jsonDecode(result.body);
      // print(result.body);
      if(jsonObject['status'] == 200){
          var showCataloguesData = jsonObject['data'] as List;
      
            if(showCataloguesData.isNotEmpty){
            
              List<Product> productsList = showCataloguesData.map<Product>((json) => Product.fromJson(json)).toList();
              setState(() {
                  // Append to the existing list
                    // products.addAll(productsList);
                    filteredProducts.addAll(productsList);
                    _isLoadingProducts = false;
                });
            }
      }
      else {
          setState(() { _isLoadingProducts = false;
            // showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Designs', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.bold),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          _isLoadingProducts ? 
              Center(
                child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // sizedBox(16),
                      AppProgress(height: 24, width: 24),
                      // sizedBox(16),
                      // ShimmerText(text: 'Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), ),
                      // Text('Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black, fontWeight: FontWeight.w500), ),
                    ],
                  ) 
                ) :
          ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color(0xFF048563))),
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      showDragHandle: true,
                      useSafeArea: true,
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Container(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Filter Designs',
                            style: GoogleFonts.inter(
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                          fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    offset = 0;
                                    searchOffset = 0;
                                    products = [];
                                    filteredProducts = [];
                                    selectedTagIds = [];
                                  });
                                  getProducts(context);
                                },
                                child: Text('Clear Filters', style: TextStyle(color: Color(0xFFF36C31))),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(child: 
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFF36C31), // Dark background color
                                        
                                        textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 5, // Shadow depth
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                          setState(() {
                                            offset = 0;
                                            searchOffset = 0;
                                            products = [];
                                            filteredProducts = [];
                                          });
                                          getProducts(context);
                                      },
                                      child: Text('Apply', style: TextStyle(color: Colors.white)),
                                    ),
                              
                              ),
                            ],
                          ),
                          (_isLoadingTags && productTags.length == 0)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isLoadingTags
                                  ? 
                                  ShimmerText(text: 'Loading product categories...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), )
                                  // const AppProgress(height: 30, width: 30,)
                                  : SizedBox(height: 0,),
                                  Text(
                                    'Loading product categories!',
                                    style: GoogleFonts.inter(
                                  textStyle: Theme.of(context).textTheme.bodyMedium,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: uniqueProductTypes.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                padding: EdgeInsets.only(bottom: 16.0),
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text( uniqueProductTypes[index], style: GoogleFonts.inter( textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.bold, ), ),
                                SizedBox(height: 8.0),
                                Container(
                                  height: 52,
                                  margin: EdgeInsets.only(bottom: 4.0),
                                  child: 
                                    
                                    // Wrap(
                                    // spacing: 8.0,
                                    // runSpacing: 4.0,
                                    // children: productTags
                                    //   .where((tag) => tag.type == uniqueProductTypes[index])
                                    //   .map((filteredTag) {
                                    //   bool isSelected = selectedTagIds.contains(filteredTag.tagId);
                                    //   return GestureDetector(
                                    //   onTap: () {
                                    //     setState(() {
                                    //     if (isSelected) {
                                    //       selectedTagIds.remove(filteredTag.tagId);
                                    //     } else {
                                    //       selectedTagIds.add(filteredTag.tagId!);
                                    //     }
                                    //     });
                                    //   },
                                    //   child: Container(
                                    //     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                                    //     decoration: BoxDecoration(
                                    //     color: isSelected ? Color(0xFF048563) : Colors.white,
                                    //     borderRadius: BorderRadius.circular(20),
                                    //     boxShadow: [
                                    //       BoxShadow(
                                    //       color: Colors.black12,
                                    //       spreadRadius: 2,
                                    //       blurRadius: 5,
                                    //       offset: Offset(0, 3),
                                    //       ),
                                    //     ],
                                    //     ),
                                    //     alignment: Alignment.center,
                                    //     child: Text(
                                    //     filteredTag.name!,
                                    //     style: TextStyle(
                                    //       color: isSelected ? Colors.white : Colors.black,
                                    //     ),
                                    //     ),
                                    //   ),
                                    //   );
                                    // }).toList(),
                                    // ),
                                  ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount: productTags .where((tag) => tag.type == uniqueProductTypes[index]) .length,
                                            itemBuilder: (context, tagIndex) {
                                                    var filteredTags = productTags
                                                    .where((tag) => tag.type == uniqueProductTypes[index])
                                                    .toList();
                                                    bool isSelected = selectedTagIds.contains(filteredTags[tagIndex].tagId);
                                                    return GestureDetector(
                                                      onTap: () {
                                                    setState(() {
                                                      if (isSelected) {
                                                        selectedTagIds.remove(filteredTags[tagIndex].tagId);
                                                      } else {
                                                        selectedTagIds.add(filteredTags[tagIndex].tagId!);
                                                      }
                                                      // print(selectedTagIds.length);
                                                      // print(filteredTags[tagIndex].name);
                                                    });
                                                      },
                                                      child: Container(
                                                              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                                                              decoration: BoxDecoration(
                                                                color: isSelected ? Color(0xFF048563) : Colors.white,
                                                                borderRadius: BorderRadius.circular(20),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                  color: Colors.black12,
                                                                  spreadRadius: 2,
                                                                  blurRadius: 5,
                                                                  offset: Offset(0, 3),
                                                                  ),
                                                                ],
                                                              ),
                                                              alignment: Alignment.center,
                                                              child: Text( filteredTags[tagIndex].name!, style: TextStyle(
                                                                  color: isSelected ? Colors.white : Colors.black,
                                                                ),
                                                              ),
                                                      ),
                                                    );
                                            },
                                  ),
                                ),
                              ],
                                ),
                              );
                            },
                              ),
                            ),
                          SizedBox(height: 36.0),
                          // Row(
                          //   children: [
                          //     TextButton(
                          //       onPressed: () {
                          //         Navigator.pop(context);
                          //         setState(() {
                          //           offset = 0;
                          //           searchOffset = 0;
                          //           products = [];
                          //           filteredProducts = [];
                          //           selectedTagIds = [];
                          //         });
                          //         getProducts(context);
                          //       },
                          //       child: Text('Clear Filters', style: TextStyle(color: Color(0xFFF36C31))),
                          //     ),
                          //     SizedBox(width: 16.0),
                          //     Expanded(child: 
                          //         ElevatedButton(
                          //             style: ElevatedButton.styleFrom(
                          //               backgroundColor: Color(0xFFF36C31), // Dark background color
                                        
                          //               textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
                          //               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          //               shape: RoundedRectangleBorder(
                          //                 borderRadius: BorderRadius.circular(16),
                          //               ),
                          //               elevation: 5, // Shadow depth
                          //             ),
                          //             onPressed: () {
                          //               Navigator.pop(context);
                          //                 setState(() {
                          //                   offset = 0;
                          //                   searchOffset = 0;
                          //                   products = [];
                          //                   filteredProducts = [];
                          //                 });
                          //                 getProducts(context);
                          //             },
                          //             child: Text('Apply', style: TextStyle(color: Colors.white)),
                          //           ),
                              
                          //     ),
                          //   ],
                          // )
                        ],
                          ),
                        );
                      },
                        );
                      },
                    );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          // selectedTagIds.length > 0 ?
                          // Row(
                          //   children: [
                          //     Text(selectedTagIds.length.toString(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black, fontWeight: FontWeight.w500), ),
                          //     SizedBox(width: 8.0),
                              
                          //   ],
                          // ) : sizedBox(0),
                          // Text('Filter', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w500), ),
                          // SizedBox(width: 8.0),
                          Icon(PhosphorIconsRegular.funnel, color: Colors.white),
                        ],
                      )
                      
                    )
        ],
      ),
      body: 
      Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: EdgeInsets.all(16.0),
              child:
                  TextField(
                    controller: searchController,
                      onSubmitted: (value) {
                        
                        // setState(() {
                        //   searchPrompt = value;
                        //   filteredProducts = products.where((product) {
                        //   return product.name!.toLowerCase().contains(value.toLowerCase()) ||
                        //   product.design!.toLowerCase().contains(value.toLowerCase());
                        //   }).toList();
                        // });

                        // After inline search, check if filteredProducts is empty, call the API with searchPrompt
                          // if (filteredProducts.isEmpty) {
                            setState(() {
                              searchOffset = 0;
                              filteredProducts = [];
                            });
                            getProductsBySearch(context);
                          // }
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                      hintText: 'Search products...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: searchPrompt.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                        setState(() {
                          searchPrompt = '';
                          searchOffset = 0;
                          searchController.clear();
                          filteredProducts = products;
                        });
                        },
                      )
                      : null,
                    ),
                  ),
                ),
              
              // Text('Showing ${listingCount} Designs', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black45, fontWeight: FontWeight.w500), ),
              (!_isLoadingProducts && filteredProducts.isEmpty) ?
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLoadingProducts
                    ? 
                    ShimmerText(text: 'Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), )
                    // const AppProgress(height: 30, width: 30,)
                    : SizedBox(height: 0,),
                    Text( 'No product match found!', style: GoogleFonts.inter( textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14, ),),
                    ElevatedButton(
                        style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.black12)),
                        onPressed: () {
                            setState(() {
                              selectedTagIds = [];
                              offset = 0;
                              searchOffset = 0;
                            });
                            getProducts(context);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                      
                          Text('Clear filters', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w500), ),
                        ],
                      )
                      
                    )
                  ],
                ),
              )
              :
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoadingProducts) {
                    setState(() {
                       offset += 20;
                       searchOffset += 20;
                      _isLoadingProducts = true;
                    });
                    getProducts(context);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                    return 
                    InkWell(
                      onTap: () {

                        // navigate to product details page
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DesignDetails(product: filteredProducts[index], productTags: productTags)));
                        
                        // showModalBottomSheet(
                        //   backgroundColor: Colors.white,
                        //     // backgroundColor: () {
                              
                        //     //     var colorTag = productTags.firstWhere((tag) => filteredProducts[index].tags?.split(',').contains(tag.tagId.toString()) == true && tag.type == 'Color', orElse: () => ProductTag(description: 'FFFFFF'));
                        //     //   return Color(int.parse('0xFF${colorTag.description ?? 'FFFFFF'}'));
                        //     // }(),
                        //   useSafeArea: true,
                        //   isScrollControlled: true,
                        //   showDragHandle: true,
                        //   context: context,
                        //   builder: (BuildContext context) {
                        //   return SingleChildScrollView(
                        //     child: Container(
                        //       color: () {
                              
                        //         var colorTag = productTags.firstWhere((tag) => filteredProducts[index].tags?.split(',').contains(tag.tagId.toString()) == true && tag.type == 'Color', orElse: () => ProductTag(description: 'FFFFFF'));
                        //       return Color(int.parse('0x22${colorTag.description ?? 'FFFFFF'}'));

                        //     // var ≈ = productTags.firstWhere(
                        //     //   (tag) => tag.tagId.toString() == filteredProducts[index].tags && tag.type == 'Color',
                        //     //   orElse: () => ProductTag(description: 'FFFFFF'),
                        //     // );
                        //     // return Color(int.parse('0xFF${colorTag.description ?? 'FFFFFF'}'));
                        //     }(),
                        //     padding: EdgeInsets.all(16.0),
                        //     child: Column(
                        //       mainAxisSize: MainAxisSize.max,
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       mainAxisAlignment: MainAxisAlignment.start,
                        //       children: [
                        //       Center(
                        //         child: Transform.rotate(
                        //         angle: -0.1, child:
                        //         CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!.split(',')[0],  imageHeight: double.parse(filteredProducts[index].size!.split('x')[1]), imageWidth: double.parse(filteredProducts[index].size!.split('x')[0]), zoom:2),
                        //         // CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!.split(',')[0],  imageHeight: MediaQuery.of(context).size.height * 0.5, imageWidth: MediaQuery.of(context).size.width * 0.6),
                        //         // CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!,  imageHeight: 120, imageWidth: 60),
                        //         // CardInteractive(imageUrl: filteredProducts[index].imageUrls!.split(',')[0], imageHeight: MediaQuery.of(context).size.height * 0.5, imageWidth: MediaQuery.of(context).size.width * 0.6),
                        //         )
                        //       ),
                        //       sizedBox(16),
                        //       Center(
                        //         child: Text(filteredProducts[index].name ?? 'No Name', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.headlineMedium, fontWeight: FontWeight.bold)),
                        //       ),
                        //       sizedBox(8),
                        //       Text(filteredProducts[index].description ?? 'No Description', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                        //       sizedBox(8),
                        //       Column(
                        //         mainAxisSize: MainAxisSize.max,
                        //         crossAxisAlignment: CrossAxisAlignment.start,
                        //         mainAxisAlignment: MainAxisAlignment.start,
                        //         spacing: 8,
                        //         children: filteredProducts[index].tags?.split(',').map((tagId) {
                        //         var tag = productTags.firstWhere((tag) => tag.tagId.toString() == tagId, orElse: () => ProductTag(name: 'Unknown'));
                        //         return Container(
                        //           padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        //           decoration: BoxDecoration(
                        //           // color: Colors.grey[200],
                        //           borderRadius: BorderRadius.circular(8.0),
                        //           ),
                        //           child: Column(
                        //             mainAxisSize: MainAxisSize.max,
                        //             crossAxisAlignment: CrossAxisAlignment.start,
                        //             mainAxisAlignment: MainAxisAlignment.start,
                        //             children: [
                        //               Text('${tag.type}: ${tag.name}', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                        //               sizedBox(8),
                        //               DottedLine(),
                        //             ],
                        //           )
                                  
                        //         );
                        //         }).toList() ?? [
                        //         Container(
                        //           padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        //           decoration: BoxDecoration(
                        //           color: Colors.grey[200],
                        //           borderRadius: BorderRadius.circular(8.0),
                        //           ),
                        //           child: Text('No Tags', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge)),
                        //         )
                        //         ],
                        //       ),
                        //       sizedBox(48),
                        //       ],
                        //     ),
                        //     ),
                        //   );
                        //   },
                        // );
                      },
                      child:
                        Container(
                          // padding: EdgeInsets.all(8.0),
                          margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                          decoration: BoxDecoration(
                          // color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          // boxShadow: [
                          //   BoxShadow(
                          //   color: Colors.grey.withOpacity(0.5),
                          //   spreadRadius: 2,
                          //   blurRadius: 5,
                          //   offset: Offset(0, 3),
                          //   ),
                          // ],
                          ),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              
                              children: [
                                // CardInteractive(imageUrl: filteredProducts[index].imageUrls!.split(',')[0], imageHeight: 120, imageWidth: 120),
                                // CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!,  imageHeight: MediaQuery.of(context).size.height * 0.5, imageWidth: MediaQuery.of(context).size.width * 0.6),
                                
                                
                                CardInteractive(design: filteredProducts[index].design!, media: filteredProducts[index].media!.split(',')[0],  imageHeight: double.parse(filteredProducts[index].size!.split('x')[1]), imageWidth: double.parse(filteredProducts[index].size!.split('x')[0]), zoom:1, productSize: filteredProducts[index].size),
                                SizedBox(width: 8.0),
                                Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Text( '${filteredProducts[index].name!} - ${filteredProducts[index].design!}', style: GoogleFonts.inter( textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black, fontWeight: FontWeight.w600, ), ),
                                  SizedBox(height: 8.0),
                                  // Text(
                                  //   filteredProducts[index].description ?? '',
                                  //   style: GoogleFonts.inter(
                                  //   textStyle: Theme.of(context).textTheme.bodyMedium,
                                  //   color: Colors.black54,
                                  //   ),
                                  // ),
                                  // SizedBox(height: 4.0),
                                  Text( filteredProducts[index].size ?? '', style: GoogleFonts.inter( textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black87, ), ),
                                  SizedBox(height: 4.0),
                                  // Text( filteredProducts[index].tags ?? '', style: GoogleFonts.inter( textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black54, ), ),
                                  // SizedBox(height: 24.0),
                                  ],
                                ),
                                ),
                              ],
                              ),
                          ),
                        );
                    },
                  ),
                  ),
              ),
              sizedBox(16),
              // _isLoadingProducts ? 
              // Center(
              //   child:
              //     Row(
              //       children: [
              //         // sizedBox(16),
              //         // AppProgress(height: 24, width: 24),
              //         // sizedBox(16),
              //         ShimmerText(text: 'Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), ),
              //         // Text('Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black, fontWeight: FontWeight.w500), ),
              //       ],
              //     ) 
              //   ) 
              // : sizedBox(0),
            ],
          ),
          
          // Positioned(
          //   bottom: 16.0,
          //   left: 0,
          //   right: 0,
          //   child: 
          //   _isLoadingProducts ? 
          //     Center(
          //       child:
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             // sizedBox(16),
          //             // AppProgress(height: 24, width: 24),
          //             // sizedBox(16),
          //             ShimmerText(text: 'Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), ),
          //             // Text('Loading...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black, fontWeight: FontWeight.w500), ),
          //           ],
          //         ) 
          //       ) :
          //   Center(
          //       child: ElevatedButton(
          //         style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Color(0xFF048563))),
          //         onPressed: () {
          //           showModalBottomSheet(
          //             backgroundColor: Colors.white,
          //             showDragHandle: true,
          //             useSafeArea: true,
          //             context: context,
          //             isScrollControlled: true,
          //             builder: (BuildContext context) {
          //               return StatefulBuilder(
          //             builder: (BuildContext context, StateSetter setState) {
          //               return Container(
          //                 padding: EdgeInsets.all(16.0),
          //                 child: Column(
          //               mainAxisSize: MainAxisSize.min,
          //               children: [
          //                 Text(
          //                   'Filter Designs',
          //                   style: GoogleFonts.inter(
          //                 textStyle: Theme.of(context).textTheme.bodyLarge,
          //                 fontWeight: FontWeight.bold,
          //                   ),
          //                 ),
          //                 SizedBox(height: 16.0),
          //                 (_isLoadingTags && productTags.length == 0)
          //                 ? Center(
          //                     child: Column(
          //                   mainAxisAlignment: MainAxisAlignment.center,
          //                   children: [
          //                     _isLoadingTags
          //                     ? 
          //                     ShimmerText(text: 'Loading product categories...', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), )
          //                     // const AppProgress(height: 30, width: 30,)
          //                     : SizedBox(height: 0,),
          //                     Text(
          //                       'Loading product categories!',
          //                       style: GoogleFonts.inter(
          //                     textStyle: Theme.of(context).textTheme.bodyMedium,
          //                     color: Colors.black54,
          //                     fontWeight: FontWeight.w500,
          //                     fontSize: 14,
          //                       ),
          //                     ),
          //                   ],
          //                     ),
          //                   )
          //                 : Expanded(
          //                     child: ListView.builder(
          //                   shrinkWrap: true,
          //                   itemCount: uniqueProductTypes.length,
          //                   itemBuilder: (context, index) {
          //                     return Container(
          //                       margin: EdgeInsets.only(bottom: 16.0),
          //                       padding: EdgeInsets.only(bottom: 16.0),
          //                       child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text( uniqueProductTypes[index], style: GoogleFonts.inter( textStyle: Theme.of(context).textTheme.bodySmall, fontWeight: FontWeight.bold, ), ),
          //                       SizedBox(height: 8.0),
          //                       Container(
          //                         height: 52,
          //                         margin: EdgeInsets.only(bottom: 4.0),
          //                         child: 
                                    
          //                           // Wrap(
          //                           // spacing: 8.0,
          //                           // runSpacing: 4.0,
          //                           // children: productTags
          //                           //   .where((tag) => tag.type == uniqueProductTypes[index])
          //                           //   .map((filteredTag) {
          //                           //   bool isSelected = selectedTagIds.contains(filteredTag.tagId);
          //                           //   return GestureDetector(
          //                           //   onTap: () {
          //                           //     setState(() {
          //                           //     if (isSelected) {
          //                           //       selectedTagIds.remove(filteredTag.tagId);
          //                           //     } else {
          //                           //       selectedTagIds.add(filteredTag.tagId!);
          //                           //     }
          //                           //     });
          //                           //   },
          //                           //   child: Container(
          //                           //     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          //                           //     decoration: BoxDecoration(
          //                           //     color: isSelected ? Color(0xFF048563) : Colors.white,
          //                           //     borderRadius: BorderRadius.circular(20),
          //                           //     boxShadow: [
          //                           //       BoxShadow(
          //                           //       color: Colors.black12,
          //                           //       spreadRadius: 2,
          //                           //       blurRadius: 5,
          //                           //       offset: Offset(0, 3),
          //                           //       ),
          //                           //     ],
          //                           //     ),
          //                           //     alignment: Alignment.center,
          //                           //     child: Text(
          //                           //     filteredTag.name!,
          //                           //     style: TextStyle(
          //                           //       color: isSelected ? Colors.white : Colors.black,
          //                           //     ),
          //                           //     ),
          //                           //   ),
          //                           //   );
          //                           // }).toList(),
          //                           // ),
          //                         ListView.builder(
          //                                   shrinkWrap: true,
          //                                   scrollDirection: Axis.horizontal,
          //                                   itemCount: productTags .where((tag) => tag.type == uniqueProductTypes[index]) .length,
          //                                   itemBuilder: (context, tagIndex) {
          //                                           var filteredTags = productTags
          //                                           .where((tag) => tag.type == uniqueProductTypes[index])
          //                                           .toList();
          //                                           bool isSelected = selectedTagIds.contains(filteredTags[tagIndex].tagId);
          //                                           return GestureDetector(
          //                                             onTap: () {
          //                                           setState(() {
          //                                             if (isSelected) {
          //                                               selectedTagIds.remove(filteredTags[tagIndex].tagId);
          //                                             } else {
          //                                               selectedTagIds.add(filteredTags[tagIndex].tagId!);
          //                                             }
          //                                             // print(selectedTagIds.length);
          //                                             // print(filteredTags[tagIndex].name);
          //                                           });
          //                                             },
          //                                             child: Container(
          //                                                     margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          //                                                     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          //                                                     decoration: BoxDecoration(
          //                                                       color: isSelected ? Color(0xFF048563) : Colors.white,
          //                                                       borderRadius: BorderRadius.circular(20),
          //                                                       boxShadow: [
          //                                                         BoxShadow(
          //                                                         color: Colors.black12,
          //                                                         spreadRadius: 2,
          //                                                         blurRadius: 5,
          //                                                         offset: Offset(0, 3),
          //                                                         ),
          //                                                       ],
          //                                                     ),
          //                                                     alignment: Alignment.center,
          //                                                     child: Text( filteredTags[tagIndex].name!, style: TextStyle(
          //                                                         color: isSelected ? Colors.white : Colors.black,
          //                                                       ),
          //                                                     ),
          //                                             ),
          //                                           );
          //                                   },
          //                         ),
          //                       ),
          //                     ],
          //                       ),
          //                     );
          //                   },
          //                     ),
          //                   ),
          //                 SizedBox(height: 16.0),
          //                 Row(
          //                   children: [
          //                     TextButton(
          //                       onPressed: () {
          //                         Navigator.pop(context);
          //                         setState(() {
          //                           offset = 0;
          //                           searchOffset = 0;
          //                           products = [];
          //                           filteredProducts = [];
          //                           selectedTagIds = [];
          //                         });
          //                         getProducts(context);
          //                       },
          //                       child: Text('Clear Filters', style: TextStyle(color: Color(0xFFF36C31))),
          //                     ),
          //                     SizedBox(width: 16.0),
          //                     Expanded(child: 
          //                         ElevatedButton(
          //                             style: ElevatedButton.styleFrom(
          //                               backgroundColor: Color(0xFFF36C31), // Dark background color
                                        
          //                               textStyle: TextStyle( fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold, ),
          //                               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          //                               shape: RoundedRectangleBorder(
          //                                 borderRadius: BorderRadius.circular(16),
          //                               ),
          //                               elevation: 5, // Shadow depth
          //                             ),
          //                             onPressed: () {
          //                               Navigator.pop(context);
          //                                 setState(() {
          //                                   offset = 0;
          //                                   searchOffset = 0;
          //                                   products = [];
          //                                   filteredProducts = [];
          //                                 });
          //                                 getProducts(context);
          //                             },
          //                             child: Text('Apply', style: TextStyle(color: Colors.white)),
          //                           ),
                              
          //                     ),
          //                   ],
          //                 )
          //               ],
          //                 ),
          //               );
          //             },
          //               );
          //             },
          //           );
          //             },
          //             child: Row(
          //               mainAxisSize: MainAxisSize.min,
          //               children: [
                          
          //                 // selectedTagIds.length > 0 ?
          //                 // Row(
          //                 //   children: [
          //                 //     Text(selectedTagIds.length.toString(), style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.black, fontWeight: FontWeight.w500), ),
          //                 //     SizedBox(width: 8.0),
                              
          //                 //   ],
          //                 // ) : sizedBox(0),
          //                 Text('Filter', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyMedium, color: Colors.white, fontWeight: FontWeight.w500), ),
          //                 SizedBox(width: 8.0),
          //                 Icon(PhosphorIconsRegular.funnel, color: Colors.white),
          //               ],
          //             )
                      
          //           ),
          //         ),
          // ),
        ],
      ),

      
                    
    );
  }
}



// import 'dart:convert';

// import 'package:anjanitek/utils/api_urls.dart';
// import 'package:anjanitek/utils/progress.dart';
// import 'package:anjanitek/utils/utils.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart';

// class ProductsListing extends StatefulWidget {
//   @override
//   _ProductsListingState createState() => _ProductsListingState();
// }

// class _ProductsListingState extends State<ProductsListing> {
//   bool _isLoadingTags = true;
//   bool _isLoadingProducts = true;
//   // List<ProductTag> productTags = [
//   //   ProductTag(tagId: 1, name: 'Small', description: 'Small Size', type: 'Size'),
//   //   ProductTag(tagId: 2, name: 'Medium', description: 'Medium Size', type: 'Size'),
//   //   ProductTag(tagId: 3, name: 'Large', description: 'Large Size', type: 'Size'),
//   //   ProductTag(tagId: 4, name: 'Red', description: 'Red Color', type: 'Color'),
//   //   ProductTag(tagId: 5, name: 'Blue', description: 'Blue Color', type: 'Color'),
//   //   ProductTag(tagId: 6, name: 'Cotton', description: 'Cotton Material', type: 'Material'),
//   //   ProductTag(tagId: 7, name: 'Polyester', description: 'Polyester Material', type: 'Material'),
//   //   ProductTag(tagId: 8, name: 'T-Shirt', description: 'T-Shirt Type', type: 'Type'),
//   //   ProductTag(tagId: 9, name: 'Jeans', description: 'Jeans Type', type: 'Type'),
//   //   ProductTag(tagId: 10, name: 'Nike', description: 'Nike Brand', type: 'Brand'),
//   //   ProductTag(tagId: 11, name: 'Adidas', description: 'Adidas Brand', type: 'Brand'),
//   //   ProductTag(tagId: 12, name: 'Men', description: 'Men Category', type: 'Category'),
//   //   ProductTag(tagId: 13, name: 'Women', description: 'Women Category', type: 'Category'),
//   // ];
//   // List<String> uniqueProductTypes = ['Size', 'Color', 'Material', 'Type', 'Brand', 'Category'];
  
//   List<Product> products = [];
//   List<ProductTag> productTags = [];
//   List<String> uniqueProductTypes = [];
//   List<int> selectedTagIds = [39];

//   @override
//   void initState() {
//     super.initState();
//     getProducts(context);
//     getProductTags(context);
//   }

//   // Get product tags
//   void getProductTags(BuildContext context) async {

//       setState(() { _isLoadingTags = true; });
      
//       Map<String, String> queryParams = { };
//       // API call
//       print("${APIUrls.products}${APIUrls.pass}/U0");
//       var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U0", queryParams)), headers: {"Accept": "application/json"});
//       Map<String, dynamic> jsonObject = jsonDecode(result.body);
      
//       if(jsonObject['status'] == 200){
//           var showCataloguesData = jsonObject['data'] as List;
      
//             if(showCataloguesData.isNotEmpty){
            
//               List<ProductTag> productTagsList = showCataloguesData.map<ProductTag>((json) => ProductTag.fromJson(json)).toList();
//               setState(() {
//                   // Get new user data
//                   productTags = productTagsList;
//                     uniqueProductTypes = productTagsList.map((tag) => tag.type).whereType<String>().toSet().toList();
//                     // sizes = productTagsList.where((tag) => tag.type == 'Size').toList();
//                   _isLoadingTags = false;
//                 });
//             }
//       }
//       else {
//           setState(() { _isLoadingTags = false;
//             // showToast(context, 'Error, try again later!',Constants.error);
//           });
//       }
//     }
  
//   // Get products using applied filters
//   void getProducts(BuildContext context) async {

//       setState(() { _isLoadingProducts = true; });
      
//       Map<String, String> queryParams = { };
//       // API call
//       var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U3/${selectedTagIds.join(',')}", queryParams)), headers: {"Accept": "application/json"});
//       Map<String, dynamic> jsonObject = jsonDecode(result.body);
      
//       if(jsonObject['status'] == 200){
//           var showCataloguesData = jsonObject['data'] as List;
      
//             if(showCataloguesData.isNotEmpty){
            
//               List<Product> productsList = showCataloguesData.map<Product>((json) => Product.fromJson(json)).toList();
//               setState(() {
//                   // Get new user data
//                   products = productsList;
//                     // uniqueProductTypes = productsList.map((tag) => tag.type).whereType<String>().toSet().toList();
//                     // sizes = productTagsList.where((tag) => tag.type == 'Size').toList();
//                   _isLoadingProducts = false;
//                 });
//             }
//       }
//       else {
//           setState(() { _isLoadingProducts = false;
//             // showToast(context, 'Error, try again later!',Constants.error);
//           });
//       }
//     }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Designs'),
//       ),
//       body: 


            
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       showCupertinoModalPopup(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return StatefulBuilder(
//                             builder: (BuildContext context, StateSetter setState) {
//                               return CupertinoActionSheet(
//                                 title: Text('Filter Designs'),
//                                 message: (_isLoadingTags && productTags.length == 0)
//                                     ? Center(
//                                         child: Column(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             _isLoadingTags
//                                                 ? const AppProgress(height: 30, width: 30,)
//                                                 : SizedBox(height: 0,),
//                                             Text(
//                                               'Loading product categories!',
//                                               style: GoogleFonts.inter(
//                                                 textStyle: Theme.of(context).textTheme.bodyLarge,
//                                                 color: Colors.black54,
//                                                 fontWeight: FontWeight.w500,
//                                                 fontSize: 14,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       )
//                                     : ListView.builder(
//                                         shrinkWrap: true,
//                                         itemCount: uniqueProductTypes.length,
//                                         itemBuilder: (context, index) {
//                                           return Container(
//                                             // padding: const EdgeInsets.all(20),
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   uniqueProductTypes[index],
//                                                   style: GoogleFonts.inter(
//                                                     textStyle: Theme.of(context).textTheme.bodyLarge,
//                                                     color: Colors.black87,
//                                                     fontWeight: FontWeight.bold,
//                                                     fontSize: 14,
//                                                   ),
//                                                 ),
//                                                 Container(
//                                                   height: 100,
//                                                   child: ListView.builder(
//                                                     shrinkWrap: true,
//                                                     scrollDirection: Axis.horizontal,
//                                                     itemCount: productTags
//                                                         .where((tag) => tag.type == uniqueProductTypes[index])
//                                                         .length,
//                                                     itemBuilder: (context, tagIndex) {
//                                                       var filteredTags = productTags
//                                                           .where((tag) => tag.type == uniqueProductTypes[index])
//                                                           .toList();
//                                                       bool isSelected = selectedTagIds.contains(filteredTags[tagIndex].tagId);
//                                                       return GestureDetector(
//                                                         onTap: () {
//                                                           setState(() {
//                                                             if (isSelected) {
//                                                               selectedTagIds.remove(filteredTags[tagIndex].tagId);
//                                                             } else {
//                                                               selectedTagIds.add(filteredTags[tagIndex].tagId!);
//                                                             }
//                                                             print(selectedTagIds.length);
//                                                             print(filteredTags[tagIndex].name);
//                                                           });
//                                                         },
//                                                         child: Container(
//                                                           height: 40,
//                                                           width: 100,
//                                                           decoration: BoxDecoration(
//                                                             color: isSelected ? Colors.blue : Colors.grey,
//                                                             borderRadius: BorderRadius.circular(8),
//                                                           ),
//                                                           alignment: Alignment.center,
//                                                           child: Text(
//                                                             filteredTags[tagIndex].name!,
//                                                             style: TextStyle(
//                                                               color: isSelected ? Colors.white : Colors.black,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                 cancelButton: CupertinoActionSheetAction(
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                   },
//                                   child: Text('Apply changes'),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       );
//                     },
//                     child: Text('Show Designs'),
//                   ),
//                 )
                      
                    
//     );
//   }
// }


// class Product {
//   int? productId;
//   String? design;
//   String? name;
//   String? description;
//   String? size;
//   String? tags;
//   String? imageUrls;
//   String? createdOn;

//   Product({this.productId, this.design, this.name, this.description, this.size, this.tags, this.imageUrls, this.createdOn});

//   Product.fromJson(Map<String, dynamic> json): 
//   productId = json['productId'], 
//   design = json['design'], 
//   name = json['name'], 
//   description = json['description'], 
//   size = json['size'],
//   tags = json['tags'],
//   imageUrls = json['imageUrls'],
//   createdOn = json['createdOn'];

//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> data = new Map<String, dynamic>();
//     data['productId']= productId;
//     data['design']= design;
//     data['name']= name;
//     data['description']= description;
//     data['size']= size;
//     data['tags']= tags;
//     data['imageUrls']= imageUrls;
//     data['createdOn']= createdOn;
//     return data;
//   }
// }

// class ProductTag {
//   int? tagId;
//   String? name;
//   String? description;
//   String? type;

//   ProductTag({this.tagId, this.name, this.description, this.type});

//   ProductTag.fromJson(Map<String, dynamic> json): 
//   tagId = json['tagId'], 
//   name = json['name'], 
//   description = json['description'], 
//   type = json['type'];

//   Map<String, dynamic> toJson() {
//     Map<String, dynamic> data = new Map<String, dynamic>();
//     data['tagId']= tagId;
//     data['name']= name;
//     data['description']= description;
//     data['type']= type;
//     return data;
//   }
// }