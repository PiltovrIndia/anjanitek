class Notifications {
  int? notificationId;
  String? sender;
  String? receiver;
  String? sentAt;
  String? message;
  int? seen;


  Notifications({this.notificationId, this.sender, this.receiver, this.sentAt,
  this.message, this.seen});

  Notifications.fromJson(Map<String, dynamic> json): 
  notificationId = json['notificationId'], 
  sender = json['sender'], 
  receiver = json['receiver'], 
  sentAt = json['sentAt'],
  message = json['message'],
  seen = (json['seen'] as int);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['notificationId']= notificationId;
    data['sender']= sender;
    data['receiver']= receiver;
    data['sentAt']= sentAt;
    data['message']= message;
    return data;
  }
}