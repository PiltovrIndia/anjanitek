
class Target {
  int? id;
  String? userId;
  String? monthDate;
  int? categoryId;
  String? targetAmount;
  String? targetOpening;
  String? actualAmount;
  String? createdAt;
  String? updatedAt;
  String? name;
  String? mapTo;
  String? relatedTo;

  Target({this.id, this.name, this.targetAmount, this.targetOpening, this.actualAmount, this.createdAt, this.updatedAt, this.categoryId, this.userId, this.monthDate, this.mapTo, this.relatedTo});

  Target.fromJson(Map<String, dynamic> json):
    id = json['id'],
    name = json['name'],
    targetAmount = json['targetAmount'],
    targetOpening = json['targetOpening'],
    actualAmount = json['actualAmount'],
    createdAt = json['createdAt'],
    updatedAt = json['updatedAt'],
    categoryId = json['categoryId'],
    userId = json['userId'],
    monthDate = json['monthDate'],
    mapTo = json['mapTo'],
    relatedTo = json['relatedTo'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['targetAmount'] = targetAmount;
    data['targetOpening'] = targetOpening;
    data['actualAmount'] = actualAmount;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['categoryId'] = categoryId;
    data['userId'] = userId;
    data['monthDate'] = monthDate;
    data['mapTo'] = mapTo;
    data['relatedTo'] = relatedTo;

    return data;
  }
}


