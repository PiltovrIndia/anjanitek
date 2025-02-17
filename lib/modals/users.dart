class Users {
  String? id;
  String? name;
  String? email;
  String? mobile;
  String? role;
  String? designation;
  String? mapTo;
  String? userImage;
  String? gcmRegId;
  int? isActive;
  String? mapName;
  String? mapMobile;


  Users({this.id, this.name, this.email, this.mobile,
  this.role, this.designation, this.mapTo, this.userImage, this.gcmRegId, this.isActive, this.mapName, this.mapMobile});

  Users.fromJson(Map<String, dynamic> json): 
  id = json['id'], 
  name = json['name'], 
  email = json['email'], 
  mobile = json['mobile'],
  role = json['role'],
  designation = json['designation'],
  mapTo = json['mapTo'],
  userImage = json['userImage'],
  gcmRegId = json['gcm_regId'],
  isActive = json['isActive'],
  mapName = json['mapName'],
  mapMobile = json['mapMobile'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = new Map<String, dynamic>();
    data['id']= id;
    data['name']= name;
    data['email']= email;
    data['mobile']= mobile;
    data['role']= role;
    data['designation']= designation;
    data['mapTo']= mapTo;
    data['gcm_regId']= gcmRegId;
    data['isActive']= isActive;
    data['mapName']= mapName;
    data['mapMobile']= mapMobile;
    return data;
  }
}