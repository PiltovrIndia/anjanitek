class PaymentsOnly {
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
  
  PaymentsOnly({this.paymentId, this.amount, this.amounts, this.type, this.id, this.invoiceNo,
  this.transactionId, this.paymentDate, this.adminId, this.particular, this.balance});

  PaymentsOnly.fromJson(Map<String, dynamic> json): 
  paymentId = json['paymentId'], 
  amount = (json['amount'] as num?)?.toDouble(), 
  amounts = json['amounts'], 
  type = json['type'], 
  id = json['id'], 
  invoiceNo = json['invoiceNo'],
  transactionId = json['transactionId'],
  paymentDate = json['paymentDate'],
  adminId = json['adminId'],
  particular = json['particular'],
  balance = (json['balance'] as num?)?.toDouble();

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
    data['adminId']= adminId;
    data['particular']= particular;
    data['balance']= balance;
    return data;
  }
}