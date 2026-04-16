class UserReportModel {
  List<Groups>? groups;
  List<String>? imeis;

  UserReportModel({this.groups, this.imeis});

  UserReportModel.fromJson(Map<String, dynamic> json) {
    if (json['groups'] != null) {
      groups = <Groups>[];
      json['groups'].forEach((v) {
        groups!.add(new Groups.fromJson(v));
      });
    }
    imeis = json['imeis'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groups != null) {
      data['groups'] = this.groups!.map((v) => v.toJson()).toList();
    }
    data['imeis'] = this.imeis;
    return data;
  }
}

class Groups {
  String? id;
  String? name;
  String? orgId;

  Groups({this.id, this.name, this.orgId});

  Groups.fromJson(Map<String, dynamic> json) {
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
