class DeviceOverviewModel {
  String? date;
  double? vehvoltage;
  double? avgvehvoltage;
  double? avgvoltage;
  double? odometer;
  double? soc;
  double? avgsoc;
  double? speed;
  double? avgspeed;
  double? batteryBackUp;
  double? voltage;

  DeviceOverviewModel({
    this.date,
    this.vehvoltage,
    this.avgvehvoltage,
    this.avgvoltage,
    this.odometer,
    this.soc,
    this.avgsoc,
    this.speed,
    this.avgspeed,
    this.batteryBackUp,
    this.voltage,
  });

  DeviceOverviewModel.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    vehvoltage = json['vehvoltage'];
    avgvehvoltage = json['avgvehvoltage'];
    avgvoltage = json['avgvoltage'];
    odometer = json['odometer'];
    soc = json['soc'];
    avgsoc = json['avgsoc'];
    speed = json['speed'];
    avgspeed = json['avgspeed'];
    batteryBackUp = json['batteryBackUp'];
    voltage = json['voltage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['vehvoltage'] = this.vehvoltage;
    data['avgvehvoltage'] = this.avgvehvoltage;
    data['avgvoltage'] = this.avgvoltage;
    data['odometer'] = this.odometer;
    data['soc'] = this.soc;
    data['avgsoc'] = this.avgsoc;
    data['speed'] = this.speed;
    data['avgspeed'] = this.avgspeed;

    data['batteryBackUp'] = this.batteryBackUp;
    data['voltage'] = this.voltage;
    return data;
  }
}
