
class Catalogue {
  int? id;
  String? name;
  String? imageUrl;
  String? documentUrl;
  int? type;

  Catalogue({this.id, this.name, this.imageUrl, this.documentUrl, this.type});

  Catalogue.fromJson(Map<String, dynamic> json): 
  id = json['id'], 
  name = json['name'], 
  imageUrl = json['imageUrl'], 
  documentUrl = json['documentUrl'], 
  type = json['type'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data['id']= id;
    data['name']= name;
    data['imageUrl']= imageUrl;
    data['documentUrl']= documentUrl;
    data['type']= type;
    return data;
  }
}
