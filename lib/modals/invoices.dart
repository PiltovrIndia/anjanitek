class Invoices {
  int? invoiceId;
  String? invoiceNo;
  String? invoiceType;
  String? invoiceDate;
  String? PoNo;
  String? vehicleNo;
  String? transport;
  String? LRNo;
  String? billTo;
  String? shipTo;
  double? totalAmount;
  double? amountPaid;
  double? pending;
  String? status;
  String? expiryDate;
  String? sales;

  double? appliedAmount;
  double? remaining;


  Invoices({this.invoiceId, this.invoiceNo, this.invoiceType, this.invoiceDate, this.PoNo, this.vehicleNo,
  this.transport, this.LRNo, this.billTo, this.shipTo, this.totalAmount, this.amountPaid, 
  this.pending, this.status, this.expiryDate, this.sales, this.appliedAmount, this.remaining});

  Invoices.fromJson(Map<String, dynamic> json): 
  invoiceId = json['invoiceId'], 
  invoiceNo = json['invoiceNo'], 
  invoiceType = json['invoiceType'], 
  invoiceDate = json['invoiceDate'], 
  PoNo = json['PoNo'], 
  vehicleNo = json['vehicleNo'],
  transport = json['transport'],
  LRNo = json['LRNo'],
  billTo = json['billTo'],
  shipTo = json['shipTo'],
  totalAmount = (json['totalAmount'] as num?)?.toDouble(),
  amountPaid = (json['amountPaid'] as num?)?.toDouble(),
  pending = (json['pending'] as num?)?.toDouble(),
  status = json['status'],
  expiryDate = json['expiryDate'],
  sales = json['sales'],
  appliedAmount = (json['appliedAmount'] as num?)?.toDouble(),
  remaining = (json['remaining'] as num?)?.toDouble();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['invoiceId']= invoiceId;
    data['invoiceNo']= invoiceNo;
    data['invoiceType']= invoiceType;
    data['invoiceDate']= invoiceDate;
    data['PoNo']= PoNo;
    data['vehicleNo']= vehicleNo;
    data['transport']= transport;
    data['LRNo']= LRNo;
    data['billTo']= billTo;
    data['shipTo']= shipTo;
    data['totalAmount']= totalAmount;
    data['amountPaid']= amountPaid;
    data['pending']= pending;
    data['status']= status;
    data['expiryDate']= expiryDate;
    data['sales']= sales;
    data['appliedAmount']= appliedAmount;
    data['remaining']= remaining;
    return data;
  }


}
