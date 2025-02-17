class Dealers {
  String? dealerId;
  String? userId;
  String? accountName;
  String? salesId;
  String? address1;
  String? address2;
  String? address3;
  String? city;
  String? state;
  String? gst;


  Dealers({this.dealerId, this.userId, this.accountName, this.salesId, this.address1,
  this.address2, this.address3, this.city, this.state, this.gst});

  Dealers.fromJson(Map<String, dynamic> json): 
  dealerId = json['dealerId'], 
  userId = json['userId'], 
  accountName = json['accountName'], 
  salesId = json['salesId'], 
  address1 = json['address1'],
  address2 = json['address2'],
  address3 = json['address3'],
  city = json['city'],
  state = json['state'],
  gst = json['gst'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['dealerId']= dealerId;
    data['userId']= userId;
    data['accountName']= accountName;
    data['salesId']= salesId;
    data['address1']= address1;
    data['address2']= address2;
    data['address3']= address3;
    data['city']= city;
    data['state']= state;
    data['gst']= gst;
    return data;
  }
}