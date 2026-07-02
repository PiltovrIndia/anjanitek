
class ProductTag {
  int? tagId;
  String? name;
  String? description;
  String? type;
  String? image;

  ProductTag({this.tagId, this.name, this.description, this.type, this.image});

  ProductTag.fromJson(Map<String, dynamic> json): 
  tagId = json['tagId'], 
  name = json['name'], 
  description = json['description'], 
  type = json['type'],
  image = json['image'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['tagId']= tagId;
    data['name']= name;
    data['description']= description;
    data['type']= type;
    data['image']= image;
    return data;
  }
}