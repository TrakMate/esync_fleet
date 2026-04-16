class alertReportModel {
  int totalCount;
  List<Entities> entities;

  alertReportModel({this.totalCount = 0, required this.entities});

  alertReportModel.fromJson(Map<String, dynamic> json)
    : totalCount = json['totalCount'] ?? 0,
      entities =
          (json['entities'] as List? ?? [])
              .map((v) => Entities.fromJson(v))
              .toList();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalCount'] = totalCount;
    data['entities'] = entities.map((v) => v.toJson()).toList();
    return data;
  }
}

class Entities {
  String imei;
  Null vehicleNumber;
  String alertType;
  String data;
  String time;
  String alertCategory;

  Entities({
    required this.imei,
    this.vehicleNumber,
    required this.alertType,
    required this.data,
    required this.time,
    required this.alertCategory,
  });

  Entities.fromJson(Map<String, dynamic> json)
    : imei = json['imei'] ?? '',
      vehicleNumber = json['vehicleNumber'],
      alertType = json['alertType'] ?? '',
      data = json['data'] ?? '',
      time = json['time'] ?? '',
      alertCategory = json['alertCategory'] ?? '';

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
