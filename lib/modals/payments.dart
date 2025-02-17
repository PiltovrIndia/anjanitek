class Payments {
  int? paymentId;
  double? amount;
  String? amounts;
  String? type;
  String? id;
  String? invoiceNo;
  String? transactionId;
  String? paymentDate;
  String? adminId;
  String? particular;
  double? balance;

  String? dealerId;
  String? accountName;
  String? salesId;
  String? address1;
  String? address2;
  String? address3;
  String? city;
  String? district;
  String? state;
  String? gst;


  Payments({this.paymentId, this.amount, this.amounts, this.type, this.id, this.invoiceNo,
  this.transactionId, this.paymentDate, this.adminId, this.particular, this.balance,
  this.dealerId, this.accountName, this.salesId, this.address1, this.address2, this.address3, this.city, this.district, this.state, this.gst});

  Payments.fromJson(Map<String, dynamic> json): 
  paymentId = json['paymentId'], 
  amount = (json['amount'] as num?)?.toDouble(), 
  amounts = json['amounts'], 
  type = json['type'], 
  id = json['id'], 
  invoiceNo = json['invoiceNo'],
  transactionId = json['transactionId'],
  paymentDate = json['paymentDate'],
  adminId = json['gcm_regId'],
  particular = json['particular'],
  balance = (json['balance'] as num?)?.toDouble(),
  
  dealerId = json['dealerId'],
  accountName = json['accountName'],
  salesId = json['salesId'],
  address1 = json['address1'],
  address2 = json['address2'],
  address3 = json['address3'],
  city = json['city'],
  district = json['district'],
  state = json['state'],
  gst = json['gst'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['paymentId']= paymentId;
    data['amount']= amount;
    data['type']= type;
    data['amounts']= amounts;
    data['id']= id;
    data['invoiceNo']= invoiceNo;
    data['transactionId']= transactionId;
    data['paymentDate']= paymentDate;
    data['gcm_regId']= adminId;
    data['particular']= particular;
    data['balance']= balance;
    
    data['dealerId']= dealerId;
    data['accountName']= accountName;
    data['salesId']= salesId;
    data['address1']= address1;
    data['address2']= address2;
    data['address3']= address3;
    data['city']= city;
    data['district']= district;
    data['state']= state;
    data['gst']= gst;

    return data;
  }
}