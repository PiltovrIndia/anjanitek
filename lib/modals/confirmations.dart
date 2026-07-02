class Confirmation {
  int? id;
  int? eventId;
  String? eventDate;
  double? anjaniAmount;
  String? confirmationOn;
  String? dealer;
  double? dealerAmount;
  String? response;
  String? responseReason;
  String? comment;
  String? media;


  Confirmation({this.id, this.eventId, this.eventDate, this.anjaniAmount, this.confirmationOn,
  this.dealer, this.dealerAmount, this.response, this.responseReason, this.comment, this.media});

  Confirmation.fromJson(Map<String, dynamic> json): 
  id = json['id'], 
  eventId = json['eventId'], 
  eventDate = json['eventDate'], 
  anjaniAmount = (json['anjaniAmount'] as num?)?.toDouble(),
  confirmationOn = json['confirmationOn'], 
  dealer = json['dealer'], 
  dealerAmount = (json['dealerAmount'] as num?)?.toDouble(),
  response = json['response'],
  responseReason = json['responseReason'],
  comment = json['comment'],
  media = (json['media']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id']= id;
    data['eventId']= eventId;
    data['eventDate']= eventDate;
    data['anjaniAmount']= anjaniAmount;
    data['confirmationOn']= confirmationOn;
    data['dealer']= dealer;
    data['dealerAmount']= dealerAmount;
    data['response']= response;
    data['responseReason']= responseReason;
    data['comment']= comment;
    data['media']= media;
    return data;
  }
}