class IMEITripDetailsModel {
  Summary? summary;
  Trips? trips;

  IMEITripDetailsModel({this.summary, this.trips});

  IMEITripDetailsModel.fromJson(Map<String, dynamic> json) {
    summary =
        json['summary'] != null ? new Summary.fromJson(json['summary']) : null;
    trips = json['trips'] != null ? new Trips.fromJson(json['trips']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.summary != null) {
      data['summary'] = this.summary!.toJson();
    }
    if (this.trips != null) {
      data['trips'] = this.trips!.toJson();
    }
    return data;
  }
}

class Summary {
  int? totalTrips;
  int? completedTrips;
  int? ongoingTrips;
  String? totalDistanceKm;
  String? totalEnergyConsumed;
  String? totalOperationalDuration;
  String? todayDistanceKm;
  String? todayEnergyConsumed;
  String? avgTripsPerDay;
  String? avgDistancePerImeiKm;
  String? avgEnergyPerImei;
  String? avgOperationalHoursPerImei;
  String? consumedFuel;
  String? avgFuelPerImei;

  Summary({
    this.totalTrips,
    this.completedTrips,
    this.ongoingTrips,
    this.totalDistanceKm,
    this.totalEnergyConsumed,
    this.totalOperationalDuration,
    this.todayDistanceKm,
    this.todayEnergyConsumed,
    this.avgTripsPerDay,
    this.avgDistancePerImeiKm,
    this.avgEnergyPerImei,
    this.avgOperationalHoursPerImei,
    this.consumedFuel,
    this.avgFuelPerImei,
  });

  Summary.fromJson(Map<String, dynamic> json) {
    totalTrips = json['totalTrips'];
    completedTrips = json['completedTrips'];
    ongoingTrips = json['ongoingTrips'];
    totalDistanceKm = json['totalDistanceKm'];
    totalEnergyConsumed = json['totalEnergyConsumed'];
    totalOperationalDuration = json['totalOperationalDuration'];
    todayDistanceKm = json['todayDistanceKm'];
    todayEnergyConsumed = json['todayEnergyConsumed'];
    avgTripsPerDay = json['avgTripsPerDay'];
    avgDistancePerImeiKm = json['avgDistancePerImeiKm'];
    avgEnergyPerImei = json['avgEnergyPerImei'];
    avgOperationalHoursPerImei = json['avgOperationalHoursPerImei'];
    consumedFuel = json['consumedFuel'];
    avgFuelPerImei = json['avgFuelPerImei'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalTrips'] = this.totalTrips;
    data['completedTrips'] = this.completedTrips;
    data['ongoingTrips'] = this.ongoingTrips;
    data['totalDistanceKm'] = this.totalDistanceKm;
    data['totalEnergyConsumed'] = this.totalEnergyConsumed;
    data['totalOperationalDuration'] = this.totalOperationalDuration;
    data['todayDistanceKm'] = this.todayDistanceKm;
    data['todayEnergyConsumed'] = this.todayEnergyConsumed;
    data['avgTripsPerDay'] = this.avgTripsPerDay;
    data['avgDistancePerImeiKm'] = this.avgDistancePerImeiKm;
    data['avgEnergyPerImei'] = this.avgEnergyPerImei;
    data['avgOperationalHoursPerImei'] = this.avgOperationalHoursPerImei;
    data['consumedFuel'] = this.consumedFuel;
    data['avgFuelPerImei'] = this.avgFuelPerImei;
    return data;
  }
}

class Trips {
  int? totalCount;
  List<Entities>? entities;

  Trips({this.totalCount, this.entities});

  Trips.fromJson(Map<String, dynamic> json) {
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
  double? maxSpeed;
  double? averageSpeed;
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
  String? tafe;
  double? totalDistance;
  int? totalTime;
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
    this.tafe,
    this.totalDistance,
    this.totalTime,
    this.grafanaURL,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    id = json['id'];
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
    tafe = json['tafe'];
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
    data['tafe'] = this.tafe;
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
