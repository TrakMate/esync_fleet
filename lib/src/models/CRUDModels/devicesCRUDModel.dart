class DevicesCRUDModel {
  int? totalCount;
  List<Entities>? entities;

  DevicesCRUDModel({this.totalCount, this.entities});

  DevicesCRUDModel.fromJson(Map<String, dynamic> json) {
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
  String? imei;
  String? deviceType;
  String? vehicleNo;
  String? batteryNo;
  String? org;
  String? createdDate;
  String? group;
  String? simno;
  String? product;
  String? fwver;
  String? hwver;
  String? vehicleModel;
  String? dealerCode;
  String? rtoNumber;
  String? fgCode;
  String? orgName;
  String? id;
  GroupDetails? groupDetails;

  Entities({
    this.imei,
    this.deviceType,
    this.vehicleNo,
    this.batteryNo,
    this.org,
    this.createdDate,
    this.group,
    this.simno,
    this.product,
    this.fwver,
    this.hwver,
    this.vehicleModel,
    this.dealerCode,
    this.rtoNumber,
    this.fgCode,
    this.orgName,
    this.id,
    this.groupDetails,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    deviceType = json['deviceType'];
    vehicleNo = json['vehicleNo'];
    batteryNo = json['batteryNo'];
    org = json['org'];
    createdDate = json['createdDate'];
    group = json['group'];
    simno = json['simno'];
    product = json['product'];
    fwver = json['fwver'];
    hwver = json['hwver'];
    vehicleModel = json['vehicleModel'];
    dealerCode = json['dealerCode'];
    rtoNumber = json['rtoNumber'];
    fgCode = json['fgCode'];
    orgName = json['orgName'];
    id = json['id'];
    groupDetails =
        json['groupDetails'] != null
            ? new GroupDetails.fromJson(json['groupDetails'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imei'] = this.imei;
    data['deviceType'] = this.deviceType;
    data['vehicleNo'] = this.vehicleNo;
    data['batteryNo'] = this.batteryNo;
    data['org'] = this.org;
    data['createdDate'] = this.createdDate;
    data['group'] = this.group;
    data['simno'] = this.simno;
    data['product'] = this.product;
    data['fwver'] = this.fwver;
    data['hwver'] = this.hwver;
    data['vehicleModel'] = this.vehicleModel;
    data['dealerCode'] = this.dealerCode;
    data['rtoNumber'] = this.rtoNumber;
    data['fgCode'] = this.fgCode;
    data['orgName'] = this.orgName;
    data['id'] = this.id;
    if (this.groupDetails != null) {
      data['groupDetails'] = this.groupDetails!.toJson();
    }
    return data;
  }
}

class GroupDetails {
  String? id;
  String? name;
  String? orgId;

  GroupDetails({this.id, this.name, this.orgId});

  GroupDetails.fromJson(Map<String, dynamic> json) {
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
