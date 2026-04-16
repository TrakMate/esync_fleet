class AlertCountModel {
  int? lowBattery;
  int? lowFuel;
  int? highTemperature;
  int? batteryFault;
  int? fall;
  int? soS;

  AlertCountModel({
    this.lowBattery,
    this.lowFuel,
    this.highTemperature,
    this.batteryFault,
    this.fall,
    this.soS,
  });

  AlertCountModel.fromJson(Map<String, dynamic> json) {
    lowBattery = json['LowBattery'];
    lowFuel = json['LowFuel'];
    highTemperature = json['HighTemperature'];
    batteryFault = json['BatteryFault'];
    fall = json['Fall'];
    soS = json['SoS'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['LowBattery'] = this.lowBattery;
    data['LowFuel'] = this.lowFuel;
    data['HighTemperature'] = this.highTemperature;
    data['BatteryFault'] = this.batteryFault;
    data['Fall'] = this.fall;
    data['SoS'] = this.soS;
    return data;
  }
}
