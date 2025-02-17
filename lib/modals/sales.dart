class Sales {
  String? saleId;
  String? productCode;
  String? productName;
  String? HSN;
  String? UOM;
  double? quantity;
  double? rate;
  double? value;
  double? discount;
  double? taxableValue;
  double? taxPercent;
  double? gst;
  double? total;


  Sales({this.saleId, this.productCode, this.productName, this.HSN, this.UOM,
  this.quantity, this.rate, this.value, this.discount, this.taxableValue, this.taxPercent, 
  this.gst, this.total});

  Sales.fromJson(Map<String, dynamic> json): 
  saleId = json['saleId'], 
  productCode = json['productCode'], 
  productName = json['productName'], 
  HSN = json['HSN'], 
  UOM = json['UOM'],
  quantity = (json['quantity'] as int).toDouble(),
  rate = (json['rate'] as int).toDouble(),
  value = (json['value'] as int).toDouble(),
  discount = (json['discount'] as int).toDouble(),
  taxableValue = (json['taxableValue'] as int).toDouble(),
  taxPercent = (json['taxPercent'] as int).toDouble(),
  gst = (json['gst'] as int).toDouble(),
  total = (json['total'] as int).toDouble();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['saleId']= saleId;
    data['productCode']= productCode;
    data['productName']= productName;
    data['HSN']= HSN;
    data['UOM']= UOM;
    data['quantity']= quantity;
    data['rate']= rate;
    data['value']= value;
    data['discount']= discount;
    data['taxableValue']= taxableValue;
    data['taxPercent']= taxPercent;
    data['gst']= gst;
    data['total']= total;
    return data;
  }
}