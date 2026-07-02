class Offer {
  int? id;
  String? title;
  String? description;
  String? media;
  int? isOpen;
  String? createdBy;
  String? createdOn;


  Offer({this.id, this.title, this.description, this.media, this.isOpen,
  this.createdBy, this.createdOn});

  Offer.fromJson(Map<String, dynamic> json): 
  id = json['id'] as int?, 
  title = json['title'], 
  description = json['description'], 
  media = json['media'], 
  isOpen = json['isOpen'] as int?,
  createdBy = json['createdBy'],
  createdOn = json['createdOn'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id']= id;
    data['title']= title;
    data['description']= description;
    data['media']= media;
    data['isOpen']= isOpen;
    data['createdBy']= createdBy;
    data['createdOn']= createdOn;
    return data;
  }
}