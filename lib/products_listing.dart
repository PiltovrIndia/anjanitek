import 'dart:convert';

import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/progress.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';

class ProductsListing extends StatefulWidget {
  @override
  _ProductsListingState createState() => _ProductsListingState();
}

class _ProductsListingState extends State<ProductsListing> {
  bool _isLoading = true;
  List<ProductTag> productTags = [
    ProductTag(tagId: 1, name: 'Small', description: 'Small Size', type: 'Size'),
    ProductTag(tagId: 2, name: 'Medium', description: 'Medium Size', type: 'Size'),
    ProductTag(tagId: 3, name: 'Large', description: 'Large Size', type: 'Size'),
    ProductTag(tagId: 4, name: 'Red', description: 'Red Color', type: 'Color'),
    ProductTag(tagId: 5, name: 'Blue', description: 'Blue Color', type: 'Color'),
    ProductTag(tagId: 6, name: 'Cotton', description: 'Cotton Material', type: 'Material'),
    ProductTag(tagId: 7, name: 'Polyester', description: 'Polyester Material', type: 'Material'),
    ProductTag(tagId: 8, name: 'T-Shirt', description: 'T-Shirt Type', type: 'Type'),
    ProductTag(tagId: 9, name: 'Jeans', description: 'Jeans Type', type: 'Type'),
    ProductTag(tagId: 10, name: 'Nike', description: 'Nike Brand', type: 'Brand'),
    ProductTag(tagId: 11, name: 'Adidas', description: 'Adidas Brand', type: 'Brand'),
    ProductTag(tagId: 12, name: 'Men', description: 'Men Category', type: 'Category'),
    ProductTag(tagId: 13, name: 'Women', description: 'Women Category', type: 'Category'),
  ];
  List<String> uniqueProductTypes = ['Size', 'Color', 'Material', 'Type', 'Brand', 'Category'];
  List<int> selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    // getProductTags(context);
  }

  // Future<void> _fetchProducts() async {
  //   await Future.delayed(Duration(seconds: 2)); // Simulate network delay
  //   setState(() {
  //     _products = List.generate(10, (index) => 'Product $index');
  //     _isLoading = false;
  //   });
  // }

  void getProductTags(BuildContext context) async {

      setState(() {
        _isLoading = true;
      });
      
      Map<String, String> queryParams = {
        
        };

      // API call
      // print("${APIUrls.user}${APIUrls.pass}/U4/${widget.selectedDealerId}");
      var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.products}${APIUrls.pass}/U0", queryParams)), headers: {"Accept": "application/json"});
      // print(result.body);
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
                  _isLoading = false;
                });
            }
      }
      else if(jsonObject['status'] == 402){
        // no data exists
        setState(() {
          // get the error message
          _isLoading = false;
        });
        
      }
      else if(jsonObject['status'] == 404){
        // no data exists
        setState(() {
          // get the error message
          _isLoading = false;
        });
        
      }
      else {

          setState(() {
            _isLoading = false;
            // showToast(context, 'Error, try again later!',Constants.error);
          });
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: 


            (_isLoading && productTags.length == 0) ? 
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(PhosphorIconsRegular.chatsTeardrop, color: Color(0xFFAAAAAA), size: 32, ),
                        // sizedBox(8),
                        _isLoading? const AppProgress(height: 30, width: 30,) : new SizedBox(height: 0,),
                        Text('Loading product catagories!', style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 14), ),
                        
                      ],
                    )
                  )
                  : 
                    ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueProductTypes.length,
                    itemBuilder: (context, index) {
                      return 
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: 
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(uniqueProductTypes[index], style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14), ),
                              (productTags[index].type == uniqueProductTypes[index]) ?
                              Container(
                                height: 100,
                                child: 
                                ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: productTags.length,
                                    itemBuilder: (context, index) {
                                      bool isSelected = selectedTagIds.contains(productTags[index].tagId);
                                      return GestureDetector(
                                        onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                          selectedTagIds.remove(productTags[index].tagId);
                                          } else {
                                          selectedTagIds.add(productTags[index].tagId!);
                                          }
                                        });
                                        },
                                        child: Container(
                                        height: 40,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blue : Colors.grey,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          productTags[index].name!,
                                          style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        ),
                                      );
                                    },
                                    )
                               ) : sizedBox(0),
                            ],
                          )
                          
                        );
                    }
                    ),
                      
                      
                    
    );
  }
}


class ProductTag {
  int? tagId;
  String? name;
  String? description;
  String? type;

  ProductTag({this.tagId, this.name, this.description, this.type});

  ProductTag.fromJson(Map<String, dynamic> json): 
  tagId = json['tagId'], 
  name = json['name'], 
  description = json['description'], 
  type = json['type'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['tagId']= tagId;
    data['name']= name;
    data['description']= description;
    data['type']= type;
    return data;
  }
}