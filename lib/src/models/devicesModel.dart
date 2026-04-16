class DevicesModel {
  int? totalCount;
  List<DeviceEntity>? entities;

  DevicesModel({this.totalCount, this.entities});

  DevicesModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['entities'] != null) {
      entities =
          (json['entities'] as List)
              .map((e) => DeviceEntity.fromJson(e))
              .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'entities': entities?.map((e) => e.toJson()).toList(),
    };
  }
}

class DeviceEntity {
  String? id;
  String? imei;
  String? vehicleNumber;
  String? speed;
  String? odometer;
  String? temperature;

  /// Non-EV specific
  Tafe? tafe;

  /// EV specific
  String? soc;
  String? soh;
  String? current;
  String? voltage;

  /// Common
  String? status;
  String? location;
  double? lat;
  double? lng;
  String? address;
  bool? dop;
  int? totalTrips;
  int? totalAlerts;
  String? batteryLogDate;
  String? locationLogDate;

  DeviceEntity({
    this.id,
    this.imei,
    this.vehicleNumber,
    this.speed,
    this.odometer,
    this.temperature,
    this.tafe,
    this.soc,
    this.soh,
    this.current,
    this.voltage,
    this.status,
    this.location,
    this.lat,
    this.lng,
    this.address,
    this.dop,
    this.totalTrips,
    this.totalAlerts,
    this.batteryLogDate,
    this.locationLogDate,
  });

  /// 🔥 EV detection helper
  bool get isEV => soc != null || soh != null;

  DeviceEntity.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    imei = json['imei'];
    vehicleNumber = json['vehicleNumber'];
    speed = json['speed'];
    odometer = json['odometer'];
    temperature = json['temperature'];

    tafe = json['tafe'] != null ? Tafe.fromJson(json['tafe']) : null;

    soc = json['soc'];
    soh = json['soh'];
    current = json['current'];
    voltage = json['voltage'];

    status = json['status'];
    location = json['location'];
    lat = (json['lat'] as num?)?.toDouble();
    lng = (json['lng'] as num?)?.toDouble();
    address = json['address'];
    dop = json['dop'];
    totalTrips = json['totalTrips'];
    totalAlerts = json['totalAlerts'];
    batteryLogDate = json['batteryLogDate'];
    locationLogDate = json['locationLogDate'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'vehicleNumber': vehicleNumber,
      'speed': speed,
      'odometer': odometer,
      'temperature': temperature,
      'tafe': tafe?.toJson(),
      'soc': soc,
      'soh': soh,
      'current': current,
      'voltage': voltage,
      'status': status,
      'location': location,
      'lat': lat,
      'lng': lng,
      'address': address,
      'dop': dop,
      'totalTrips': totalTrips,
      'totalAlerts': totalAlerts,
      'batteryLogDate': batteryLogDate,
      'locationLogDate': locationLogDate,
    };
  }
}

class Tafe {
  int? rpm;
  int? fuellevel;
  bool? w4d;
  bool? sos;
  bool? pto;

  Tafe({this.rpm, this.fuellevel, this.w4d, this.sos, this.pto});

  Tafe.fromJson(Map<String, dynamic> json) {
    rpm = json['rpm'];
    fuellevel = json['fuellevel'];
    w4d = json['w4d'];
    sos = json['sos'];
    pto = json['pto'];
  }

  Map<String, dynamic> toJson() {
    return {
      'rpm': rpm,
      'fuellevel': fuellevel,
      'w4d': w4d,
      'sos': sos,
      'pto': pto,
    };
  }
}
