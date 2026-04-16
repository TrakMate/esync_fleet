class IMEIAlertsDetailsModel {
  int? totalAlerts;
  int? criticalAlerts;
  int? nonCriticalAlerts;
  int? attentionNeededVehicles;
  List<Alerts>? alerts;

  IMEIAlertsDetailsModel({
    this.totalAlerts,
    this.criticalAlerts,
    this.nonCriticalAlerts,
    this.attentionNeededVehicles,
    this.alerts,
  });

  IMEIAlertsDetailsModel.fromJson(Map<String, dynamic> json) {
    totalAlerts = json['totalAlerts'];
    criticalAlerts = json['criticalAlerts'];
    nonCriticalAlerts = json['nonCriticalAlerts'];
    attentionNeededVehicles = json['attentionNeededVehicles'];
    if (json['alerts'] != null) {
      alerts = <Alerts>[];
      json['alerts'].forEach((v) {
        alerts!.add(new Alerts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalAlerts'] = this.totalAlerts;
    data['criticalAlerts'] = this.criticalAlerts;
    data['nonCriticalAlerts'] = this.nonCriticalAlerts;
    data['attentionNeededVehicles'] = this.attentionNeededVehicles;
    if (this.alerts != null) {
      data['alerts'] = this.alerts!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imei'] = this.imei;
    data['vehicleNumber'] = this.vehicleNumber;
    data['alertType'] = this.alertType;
    data['data'] = this.data;
    data['time'] = this.time;
    data['alertCategory'] = this.alertCategory;
    return data;
  }
}
