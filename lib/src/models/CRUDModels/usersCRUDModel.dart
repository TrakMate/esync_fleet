class UserCRUDModel {
  int? totalCount;
  List<Entities>? entities;

  UserCRUDModel({this.totalCount, this.entities});

  UserCRUDModel.fromJson(Map<String, dynamic> json) {
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
  String? userName;
  Null? password;
  String? name;
  String? phone;
  bool? active;
  String? role;
  String? createdDate;
  int? loginCount;
  String? loginDate;
  String? profileImage;
  String? org;
  List<String>? groups;
  String? orgName;
  String? id;
  List<GroupsDetails>? groupsDetails;

  Entities({
    this.userName,
    this.password,
    this.name,
    this.phone,
    this.active,
    this.role,
    this.createdDate,
    this.loginCount,
    this.loginDate,
    this.profileImage,
    this.org,
    this.groups,
    this.orgName,
    this.id,
    this.groupsDetails,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    userName = json['userName'];
    password = json['password'];
    name = json['name'];
    phone = json['phone'];
    active = json['active'];
    role = json['role'];
    createdDate = json['createdDate'];
    loginCount = json['loginCount'];
    loginDate = json['loginDate'];
    profileImage = json['profileImage'];
    org = json['org'];

    // groups = json['groups'].cast<String>();

    // SAFE GROUPS PARSING
    groups = (json['groups'] as List?)?.map((e) => e.toString()).toList() ?? [];

    orgName = json['orgName'];
    id = json['id'];

    // if (json['groupsDetails'] != null) {
    //   groupsDetails = <GroupsDetails>[];
    //   json['groupsDetails'].forEach((v) {
    //     groupsDetails!.add(new GroupsDetails.fromJson(v));
    //   });
    // }

    // SAFE GROUP DETAILS PARSING
    groupsDetails =
        (json['groupsDetails'] as List?)
            ?.map((v) => GroupsDetails.fromJson(v))
            .toList() ??
        [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userName'] = this.userName;
    data['password'] = this.password;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['active'] = this.active;
    data['role'] = this.role;
    data['createdDate'] = this.createdDate;
    data['loginCount'] = this.loginCount;
    data['loginDate'] = this.loginDate;
    data['profileImage'] = this.profileImage;
    data['org'] = this.org;
    data['groups'] = this.groups;
    data['orgName'] = this.orgName;
    data['id'] = this.id;
    if (this.groupsDetails != null) {
      data['groupsDetails'] =
          this.groupsDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GroupsDetails {
  String? id;
  String? name;
  String? orgId;

  GroupsDetails({this.id, this.name, this.orgId});

  GroupsDetails.fromJson(Map<String, dynamic> json) {
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
