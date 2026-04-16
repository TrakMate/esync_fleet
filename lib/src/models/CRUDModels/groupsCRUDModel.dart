class GroupsCRUDModel {
  int? totalCount;
  List<GroupEntity>? entities;

  GroupsCRUDModel({this.totalCount, this.entities});

  GroupsCRUDModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['entities'] != null) {
      entities = <GroupEntity>[];
      json['entities'].forEach((v) {
        entities!.add(new GroupEntity.fromJson(v));
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

class GroupEntity {
  String? id;
  String? name;
  String? orgId;

  GroupEntity({this.id, this.name, this.orgId});

  GroupEntity.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    orgId = json['orgId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['orgId'] = this.orgId;
    return data;
  }
}
