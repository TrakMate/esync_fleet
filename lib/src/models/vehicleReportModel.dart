class VehicleReportModel {
  int totalCount;
  List<Entities>? entities;

  VehicleReportModel({required this.totalCount, this.entities});

  factory VehicleReportModel.fromJson(Map<String, dynamic> json) {
    return VehicleReportModel(
      totalCount: json['totalCount'] ?? 0,
      entities:
          json['entities'] != null
              ? (json['entities'] as List)
                  .map((v) => Entities.fromJson(v))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalCount'] = totalCount;
    if (entities != null) {
      data['entities'] = entities!.map((v) => v.toJson()).toList();
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

  // Factory constructor for JSON parsing
  factory Entities.fromJson(Map<String, dynamic> json) {
    return Entities(
      id: json['id'],
      imei: json['imei'],
      lat: json['lat']?.toDouble(),
      long: json['long']?.toDouble(),
      location: json['location'],
      speed: json['speed']?.toString(),
      odometer: json['odometer']?.toString(),
      vehicleNumber: json['vehicleNumber'],
      current: json['current']?.toString(),
      voltage: json['voltage']?.toString(),
      soc: json['soc']?.toString(),
      soh: json['soh']?.toString(),
      temperature: json['temperature']?.toString(),
      batteryLogTime: json['batteryLogTime'],
      chargingStatus: json['chargingStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['imei'] = imei;
    data['lat'] = lat;
    data['long'] = long;
    data['location'] = location;
    data['speed'] = speed;
    data['odometer'] = odometer;
    data['vehicleNumber'] = vehicleNumber;
    data['current'] = current;
    data['voltage'] = voltage;
    data['soc'] = soc;
    data['soh'] = soh;
    data['temperature'] = temperature;
    data['batteryLogTime'] = batteryLogTime;
    data['chargingStatus'] = chargingStatus;
    return data;
  }
}
