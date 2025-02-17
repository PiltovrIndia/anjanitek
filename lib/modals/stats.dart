class Stats {
  String? state;
  int? invoices;
  int? dealers;
  int? dealersDue;
  double? pendingATL;
  double? pendingVCL;
  

  Stats({this.state, this.invoices, this.dealers, this.dealersDue, this.pendingATL, this.pendingVCL});

  Stats.fromJson(Map<String, dynamic> json): 
  state = json['state'], 
  invoices = json['invoices'], 
  dealers = json['dealers'], 
  dealersDue = json['dealersDue'],
  pendingATL = (json['pendingATL'] as num?)?.toDouble(),
  pendingVCL = (json['pendingVCL'] as num?)?.toDouble();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['state']= state;
    data['invoices']= invoices;
    data['dealers']= dealers;
    data['pendingATL']= pendingATL;
    data['pendingVCL']= pendingVCL;
    return data;
  }


}
