class canConfigOrgNameModel {
  int? totalCount;
  List<Entities>? entities;

  canConfigOrgNameModel({this.totalCount, this.entities});

  canConfigOrgNameModel.fromJson(Map<String, dynamic> json) {
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
  String? name;
  String? createdDate;
  int? orgDeviceType;
  List<String>? canTabs;

  Entities({
    this.id,
    this.name,
    this.createdDate,
    this.orgDeviceType,
    this.canTabs,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdDate = json['createdDate'];
    orgDeviceType = json['orgDeviceType'];

    if (json['canTabs'] != null) {
      canTabs = List<String>.from(json['canTabs']);
    } else {
      canTabs = [];
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['createdDate'] = this.createdDate;
    data['orgDeviceType'] = this.orgDeviceType;
    data['canTabs'] = this.canTabs;
    return data;
  }
}
