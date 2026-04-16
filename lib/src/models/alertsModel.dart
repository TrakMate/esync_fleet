// class AlertsModel {
//   int? totalAlerts;
//   int? criticalAlerts;
//   int? nonCriticalAlerts;
//   int? attentionNeededVehicles;
//   List<Alerts>? alerts;

//   AlertsModel({
//     this.totalAlerts,
//     this.criticalAlerts,
//     this.nonCriticalAlerts,
//     this.attentionNeededVehicles,
//     this.alerts,
//   });

//   AlertsModel.fromJson(Map<String, dynamic> json) {
//     totalAlerts = json['totalAlerts'];
//     criticalAlerts = json['criticalAlerts'];
//     nonCriticalAlerts = json['nonCriticalAlerts'];
//     attentionNeededVehicles = json['attentionNeededVehicles'];
//     if (json['alerts'] != null) {
//       alerts = <Alerts>[];
//       json['alerts'].forEach((v) {
//         alerts!.add(new Alerts.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['totalAlerts'] = this.totalAlerts;
//     data['criticalAlerts'] = this.criticalAlerts;
//     data['nonCriticalAlerts'] = this.nonCriticalAlerts;
//     data['attentionNeededVehicles'] = this.attentionNeededVehicles;
//     if (this.alerts != null) {
//       data['alerts'] = this.alerts!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class Alerts {
//   String? imei;
//   String? vehicleNumber;
//   String? alertType;
//   String? data;
//   String? time;
//   String? alertCategory;

//   Alerts({
//     this.imei,
//     this.vehicleNumber,
//     this.alertType,
//     this.data,
//     this.time,
//     this.alertCategory,
//   });

//   Alerts.fromJson(Map<String, dynamic> json) {
//     imei = json['imei'];
//     vehicleNumber = json['vehicleNumber'];
//     alertType = json['alertType'];
//     data = json['data'];
//     time = json['time'];
//     alertCategory = json['alertCategory'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['imei'] = this.imei;
//     data['vehicleNumber'] = this.vehicleNumber;
//     data['alertType'] = this.alertType;
//     data['data'] = this.data;
//     data['time'] = this.time;
//     data['alertCategory'] = this.alertCategory;
//     return data;
//   }
// }
class AlertsModel {
  int? totalAlerts;
  int? criticalAlerts;
  int? nonCriticalAlerts;
  int? attentionNeededVehicles;
  List<Alerts>? alerts;
  List<SpeedAlerts>? speedAlerts;
  List<GeoFenceAlerts>? geoFenceAlerts;

  AlertsModel({
    this.totalAlerts,
    this.criticalAlerts,
    this.nonCriticalAlerts,
    this.attentionNeededVehicles,
    this.alerts,
    this.speedAlerts,
    this.geoFenceAlerts,
  });

  AlertsModel.fromJson(Map<String, dynamic> json) {
    totalAlerts = json['totalAlerts'];
    criticalAlerts = json['criticalAlerts'];
    nonCriticalAlerts = json['nonCriticalAlerts'];
    attentionNeededVehicles = json['attentionNeededVehicles'];
    if (json['alerts'] != null) {
      alerts = <Alerts>[];
      json['alerts'].forEach((v) {
        alerts!.add(Alerts.fromJson(v));
      });
    }
    if (json['speedalerts'] != null) {
      speedAlerts = <SpeedAlerts>[];
      json['speedalerts'].forEach((v) {
        speedAlerts!.add(SpeedAlerts.fromJson(v));
      });
    }
    if (json['geofencealerts'] != null) {
      geoFenceAlerts = <GeoFenceAlerts>[];
      json['geofencealerts'].forEach((v) {
        geoFenceAlerts!.add(GeoFenceAlerts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalAlerts'] = totalAlerts;
    data['criticalAlerts'] = criticalAlerts;
    data['nonCriticalAlerts'] = nonCriticalAlerts;
    data['attentionNeededVehicles'] = attentionNeededVehicles;
    if (alerts != null) {
      data['alerts'] = alerts!.map((v) => v.toJson()).toList();
    }
    if (speedAlerts != null) {
      data['speedalerts'] = speedAlerts!.map((v) => v.toJson()).toList();
    }
    if (geoFenceAlerts != null) {
      data['geofencealerts'] = geoFenceAlerts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Alerts {
  String? imei;
  String? vehicleNumber;
  String? alertType;
  String? data;
  String? time;
  String? alertCategory;

  Alerts({
    this.imei,
    this.vehicleNumber,
    this.alertType,
    this.data,
    this.time,
    this.alertCategory,
  });

  Alerts.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    vehicleNumber = json['vehicleNumber'];
    alertType = json['alertType'];
    data = json['data'];
    time = json['time'];
    alertCategory = json['alertCategory'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['imei'] = imei;
    data['vehicleNumber'] = vehicleNumber;
    data['alertType'] = alertType;
    data['data'] = this.data;
    data['time'] = time;
    data['alertCategory'] = alertCategory;
    return data;
  }
}

class SpeedAlerts {
  String? imei;
  String? vehicleNumber;
  String? alertType;
  String? data;
  String? time;
  String? alertCategory;

  SpeedAlerts({
    this.imei,
    this.vehicleNumber,
    this.alertType,
    this.data,
    this.time,
    this.alertCategory,
  });

  SpeedAlerts.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    vehicleNumber = json['vehicleNumber'];
    alertType = json['alertType'];
    data = json['data'];
    time = json['time'];
    alertCategory = json['alertCategory'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['imei'] = imei;
    data['vehicleNumber'] = vehicleNumber;
    data['alertType'] = alertType;
    data['data'] = this.data;
    data['time'] = time;
    data['alertCategory'] = alertCategory;
    return data;
  }
}

class GeoFenceAlerts {
  String? imei;
  String? vehicleNumber;
  String? alertType;
  String? data;
  String? time;
  String? alertCategory;
  String? geoFenceName;

  GeoFenceAlerts({
    this.imei,
    this.vehicleNumber,
    this.alertType,
    this.data,
    this.time,
    this.alertCategory,
    this.geoFenceName,
  });

  GeoFenceAlerts.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    vehicleNumber = json['vehicleNumber'];
    alertType = json['alertType'];
    data = json['data'];
    time = json['time'];
    alertCategory = json['alertCategory'];
    geoFenceName = json['geoFenceName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['imei'] = imei;
    data['vehicleNumber'] = vehicleNumber;
    data['alertType'] = alertType;
    data['data'] = this.data;
    data['time'] = time;
    data['alertCategory'] = alertCategory;
    data['geoFenceName'] = geoFenceName;
    return data;
  }
}
