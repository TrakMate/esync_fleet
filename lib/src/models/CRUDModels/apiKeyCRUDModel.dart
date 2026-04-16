class APIKeyCRUDModel {
  int? totalCount;
  List<Entities>? entities;

  APIKeyCRUDModel({this.totalCount, this.entities});

  APIKeyCRUDModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['entities'] != null) {
      entities = <Entities>[];
      json['entities'].forEach((v) {
        entities!.add(new Entities.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    if (this.entities != null) {
      data['entities'] = this.entities!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Entities {
  String? id;
  String? apiKey;
  String? createdDate;
  String? lastUsed;
  String? orgId;
  String? userId;

  Entities({
    this.id,
    this.apiKey,
    this.createdDate,
    this.lastUsed,
    this.orgId,
    this.userId,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    apiKey = json['apiKey'];
    createdDate = json['createdDate'];
    lastUsed = json['lastUsed'];
    orgId = json['orgId'];
    userId = json['userId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['apiKey'] = this.apiKey;
    data['createdDate'] = this.createdDate;
    data['lastUsed'] = this.lastUsed;
    data['orgId'] = this.orgId;
    data['userId'] = this.userId;
    return data;
  }
}
