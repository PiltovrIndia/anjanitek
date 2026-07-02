class Product {
  int? productId;
  String? design;
  String? name;
  String? description;
  String? size;
  String? tags;
  String? media;
  String? createdOn;
  String? favorite;
  int? prm;
  int? std;
  int? designType;

  Product({this.productId, this.design, this.name, this.description, this.size, this.tags, this.media, this.createdOn, this.favorite, this.prm, this.std});

  Product.fromJson(Map<String, dynamic> json): 
  productId = json['productId'], 
  design = json['design'], 
  name = json['name'], 
  description = json['description'], 
  size = json['size'],
  tags = json['tags'],
  media = json['media'],
  createdOn = json['createdOn'],
  favorite = json['favorite'],
  prm = json['prm'],
  std = json['std'],
  designType = json['designType'] ?? 0;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['productId']= productId;
    data['design']= design;
    data['name']= name;
    data['description']= description;
    data['size']= size;
    data['tags']= tags;
    data['media']= media;
    data['createdOn']= createdOn;
    data['favorite']= favorite;
    data['prm']= prm;
    data['std']= std;
    data['designType']= designType;
    return data;
  }
}