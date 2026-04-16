class VehicleSummaryModel {
  int? totalCount;
  List<Entities>? entities;

  VehicleSummaryModel({this.totalCount, this.entities});

  VehicleSummaryModel.fromJson(Map<String, dynamic> json) {
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
  String? imei;
  double? lat;
  double? long;
  String? location;
  String? speed;
  String? odometer;
  String? vehicleNumber;
  String? current;
  String? voltage;
  String? soc;
  String? soh;
  String? temperature;
  String? batteryLogTime;
  String? chargingStatus;

  Entities({
    this.id,
    this.imei,
    this.lat,
    this.long,
    this.location,
    this.speed,
    this.odometer,
    this.vehicleNumber,
    this.current,
    this.voltage,
    this.soc,
    this.soh,
    this.temperature,
    this.batteryLogTime,
    this.chargingStatus,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    imei = json['imei'];
    lat = json['lat'];
    long = json['long'];
    location = json['location'];
    speed = json['speed'];
    odometer = json['odometer'];
    vehicleNumber = json['vehicleNumber'];
    current = json['current'];
    voltage = json['voltage'];
    soc = json['soc'];
    soh = json['soh'];
    temperature = json['temperature'];
    batteryLogTime = json['batteryLogTime'];
    chargingStatus = json['chargingStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['imei'] = this.imei;
    data['lat'] = this.lat;
    data['long'] = this.long;
    data['location'] = this.location;
    data['speed'] = this.speed;
    data['odometer'] = this.odometer;
    data['vehicleNumber'] = this.vehicleNumber;
    data['current'] = this.current;
    data['voltage'] = this.voltage;
    data['soc'] = this.soc;
    data['soh'] = this.soh;
    data['temperature'] = this.temperature;
    data['batteryLogTime'] = this.batteryLogTime;
    data['chargingStatus'] = this.chargingStatus;
    return data;
  }
}
