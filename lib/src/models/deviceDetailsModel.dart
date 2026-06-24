class DeviceDetailsModel {
  String? status;
  String? address;
  String? batteryTime;
  String? imei;
  String? lstatus;
  String? vehicleNumber;
  double? lat;
  double? long;
  String? locationTime;

  DeviceDetailsModel({
    this.status,
    this.address,
    this.batteryTime,
    this.imei,
    this.lstatus,
    this.vehicleNumber,
    this.lat,
    this.long,
    this.locationTime,
  });

  DeviceDetailsModel.fromJson(Map<String, dynamic> json) {
    status = json['Status'];
    address = json['address'];
    batteryTime = json['battery_time'];
    imei = json['imei'];
    lstatus = json['Lstatus'];
    vehicleNumber = json['vehicleNumber'];
    lat = json['lat'];
    long = json['long'];
    locationTime = json['location_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Status'] = this.status;
    data['address'] = this.address;
    data['battery_time'] = this.batteryTime;
    data['imei'] = this.imei;
    data['Lstatus'] = this.lstatus;
    data['vehicleNumber'] = this.vehicleNumber;
    data['lat'] = this.lat;
    data['long'] = this.long;
    data['location_time'] = this.locationTime;
    return data;
  }
}
