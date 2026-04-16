class TripsModel {
  int? totalCount;
  List<Entities>? entities;

  TripsModel({this.totalCount, this.entities});

  TripsModel.fromJson(Map<String, dynamic> json) {
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
  String? orgId;
  String? tripStartTime;
  String? tripEndTime;
  int? influxStartTime;
  int? influxEndTime;
  double? startOdoReading;
  double? endOdoReading;
  int? startSOCReading;
  int? endSOCReading;
  String? startSOCReadingTime;
  String? endSOCReadingTime;
  StartLocation? startLocation;
  StartLocation? endLocation;
  num? maxSpeed;
  num? averageSpeed;
  int? tripStatus;
  String? deviceGroup;
  String? startAddress;
  String? endAddress;
  String? tripEndReason;
  int? idleTime;
  int? movingTime;
  int? haltedTime;
  int? soh;
  double? dte;
  double? totalDistance;
  num? totalTime;
  Null? grafanaURL;

  Entities({
    this.id,
    this.imei,
    this.orgId,
    this.tripStartTime,
    this.tripEndTime,
    this.influxStartTime,
    this.influxEndTime,
    this.startOdoReading,
    this.endOdoReading,
    this.startSOCReading,
    this.endSOCReading,
    this.startSOCReadingTime,
    this.endSOCReadingTime,
    this.startLocation,
    this.endLocation,
    this.maxSpeed,
    this.averageSpeed,
    this.tripStatus,
    this.deviceGroup,
    this.startAddress,
    this.endAddress,
    this.tripEndReason,
    this.idleTime,
    this.movingTime,
    this.haltedTime,
    this.soh,
    this.dte,
    this.totalDistance,
    this.totalTime,
    this.grafanaURL,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    imei = json['imei'];
    orgId = json['orgId'];
    tripStartTime = json['tripStartTime'];
    tripEndTime = json['tripEndTime'];
    influxStartTime = json['influxStartTime'];
    influxEndTime = json['influxEndTime'];
    startOdoReading = json['startOdoReading'];
    endOdoReading = json['endOdoReading'];
    startSOCReading = json['startSOCReading'];
    endSOCReading = json['endSOCReading'];
    startSOCReadingTime = json['startSOCReadingTime'];
    endSOCReadingTime = json['endSOCReadingTime'];
    startLocation =
        json['startLocation'] != null
            ? new StartLocation.fromJson(json['startLocation'])
            : null;
    endLocation =
        json['endLocation'] != null
            ? new StartLocation.fromJson(json['endLocation'])
            : null;
    maxSpeed = json['maxSpeed'];
    averageSpeed = json['averageSpeed'];
    tripStatus = json['tripStatus'];
    deviceGroup = json['deviceGroup'];
    startAddress = json['startAddress'];
    endAddress = json['endAddress'];
    tripEndReason = json['tripEndReason'];
    idleTime = json['idleTime'];
    movingTime = json['movingTime'];
    haltedTime = json['haltedTime'];
    soh = json['soh'];
    dte = json['dte'];
    totalDistance = json['totalDistance'];
    totalTime = json['totalTime'];
    grafanaURL = json['grafanaURL'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['imei'] = this.imei;
    data['orgId'] = this.orgId;
    data['tripStartTime'] = this.tripStartTime;
    data['tripEndTime'] = this.tripEndTime;
    data['influxStartTime'] = this.influxStartTime;
    data['influxEndTime'] = this.influxEndTime;
    data['startOdoReading'] = this.startOdoReading;
    data['endOdoReading'] = this.endOdoReading;
    data['startSOCReading'] = this.startSOCReading;
    data['endSOCReading'] = this.endSOCReading;
    data['startSOCReadingTime'] = this.startSOCReadingTime;
    data['endSOCReadingTime'] = this.endSOCReadingTime;
    if (this.startLocation != null) {
      data['startLocation'] = this.startLocation!.toJson();
    }
    if (this.endLocation != null) {
      data['endLocation'] = this.endLocation!.toJson();
    }
    data['maxSpeed'] = this.maxSpeed;
    data['averageSpeed'] = this.averageSpeed;
    data['tripStatus'] = this.tripStatus;
    data['deviceGroup'] = this.deviceGroup;
    data['startAddress'] = this.startAddress;
    data['endAddress'] = this.endAddress;
    data['tripEndReason'] = this.tripEndReason;
    data['idleTime'] = this.idleTime;
    data['movingTime'] = this.movingTime;
    data['haltedTime'] = this.haltedTime;
    data['soh'] = this.soh;
    data['dte'] = this.dte;
    data['totalDistance'] = this.totalDistance;
    data['totalTime'] = this.totalTime;
    data['grafanaURL'] = this.grafanaURL;
    return data;
  }
}

class StartLocation {
  double? x;
  double? y;

  StartLocation({this.x, this.y});

  StartLocation.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['x'] = this.x;
    data['y'] = this.y;
    return data;
  }
}
