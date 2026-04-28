class DeviceOverviewModel {
  double? vehvoltage;
  double? odometer;
  double? soc;
  int? speed;
  double? voltage;

  DeviceOverviewModel({
    this.vehvoltage,
    this.odometer,
    this.soc,
    this.speed,
    this.voltage,
  });

  DeviceOverviewModel.fromJson(Map<String, dynamic> json) {
    vehvoltage = json['vehvoltage'];
    odometer = json['odometer'];
    soc = json['soc'];
    speed = json['speed'];
    voltage = json['voltage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['vehvoltage'] = this.vehvoltage;
    data['odometer'] = this.odometer;
    data['soc'] = this.soc;
    data['speed'] = this.speed;
    data['voltage'] = this.voltage;
    return data;
  }
}
