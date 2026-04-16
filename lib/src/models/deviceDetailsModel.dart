class DeviceDetailsModel {
  String? status;
  String? batteryTime;
  String? imei;
  String? vehicleNumber;
  double? lat;
  double? long;

  DeviceDetailsModel({
    this.status,
    this.batteryTime,
    this.imei,
    this.vehicleNumber,
    this.lat,
    this.long,
  });

  DeviceDetailsModel.fromJson(Map<String, dynamic> json) {
    status = json['Status'];
    batteryTime = json['battery_time'];
    imei = json['imei'];
    vehicleNumber = json['vehicleNumber'];
    lat = json['lat'];
    long = json['long'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Status'] = this.status;
    data['battery_time'] = this.batteryTime;
    data['imei'] = this.imei;
    data['vehicleNumber'] = this.vehicleNumber;
    data['lat'] = this.lat;
    data['long'] = this.long;
    return data;
  }
}
