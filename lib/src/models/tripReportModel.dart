class TripReportModel {
  int totalCount;
  List<Entities> entities;

  TripReportModel({required this.totalCount, required this.entities});

  TripReportModel.fromJson(Map<String, dynamic> json)
    : totalCount = json['totalCount'] ?? 0,
      entities =
          json['entities'] != null
              ? List<Entities>.from(
                json['entities'].map((x) => Entities.fromJson(x)),
              )
              : [];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalCount'] = totalCount;
    data['entities'] = entities.map((v) => v.toJson()).toList();
    return data;
  }
}

class Entities {
  String id;
  String imei;
  String orgId;
  String tripStartTime;
  String tripEndTime;
  double tripDuration;
  double startOdoReading;
  double endOdoReading;
  int startSOCReading;
  int endSOCReading;
  int consumedSOC;
  double maxSpeed;
  double averageSpeed;
  int tripStatus;
  String deviceGroup;
  String startAddress;
  String endAddress;
  double totalDistance;
  int totalTime;

  Entities({
    required this.id,
    required this.imei,
    required this.orgId,
    required this.tripStartTime,
    required this.tripEndTime,
    required this.tripDuration,
    required this.startOdoReading,
    required this.endOdoReading,
    required this.startSOCReading,
    required this.endSOCReading,
    required this.consumedSOC,
    required this.maxSpeed,
    required this.averageSpeed,
    required this.tripStatus,
    required this.deviceGroup,
    required this.startAddress,
    required this.endAddress,
    required this.totalDistance,
    required this.totalTime,
  });

  Entities.fromJson(Map<String, dynamic> json)
    : id = json['id'] ?? '',
      imei = json['imei'] ?? '',
      orgId = json['orgId'] ?? '',
      tripStartTime = json['tripStartTime'] ?? '',
      tripEndTime = json['tripEndTime'] ?? '',
      tripDuration = (json['tripDuration'] as num?)?.toDouble() ?? 0.0,
      startOdoReading = (json['startOdoReading'] as num?)?.toDouble() ?? 0.0,
      endOdoReading = (json['endOdoReading'] as num?)?.toDouble() ?? 0.0,
      startSOCReading = json['startSOCReading'] ?? 0,
      endSOCReading = json['endSOCReading'] ?? 0,
      consumedSOC = json['consumedSOC'] ?? 0,
      maxSpeed = (json['maxSpeed'] as num?)?.toDouble() ?? 0.0,
      averageSpeed = (json['averageSpeed'] as num?)?.toDouble() ?? 0.0,
      tripStatus = json['tripStatus'] ?? 0,
      deviceGroup = json['deviceGroup'] ?? '',
      startAddress = json['startAddress'] ?? '',
      endAddress = json['endAddress'] ?? '',
      totalDistance = (json['totalDistance'] as num?)?.toDouble() ?? 0.0,
      totalTime = json['totalTime'] ?? 0;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['imei'] = imei;
    data['orgId'] = orgId;
    data['tripStartTime'] = tripStartTime;
    data['tripEndTime'] = tripEndTime;
    data['tripDuration'] = tripDuration;
    data['startOdoReading'] = startOdoReading;
    data['endOdoReading'] = endOdoReading;
    data['startSOCReading'] = startSOCReading;
    data['endSOCReading'] = endSOCReading;
    data['consumedSOC'] = consumedSOC;
    data['maxSpeed'] = maxSpeed;
    data['averageSpeed'] = averageSpeed;
    data['tripStatus'] = tripStatus;
    data['deviceGroup'] = deviceGroup;
    data['startAddress'] = startAddress;
    data['endAddress'] = endAddress;
    data['totalDistance'] = totalDistance;
    data['totalTime'] = totalTime;
    return data;
  }
}
