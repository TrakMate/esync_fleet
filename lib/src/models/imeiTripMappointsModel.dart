class IMEITripMapPointsModel {
  String? imei;
  int? totalTrips;
  List<Points>? points;

  IMEITripMapPointsModel({this.imei, this.totalTrips, this.points});

  IMEITripMapPointsModel.fromJson(Map<String, dynamic> json) {
    imei = json['imei'];
    totalTrips = json['totalTrips'];
    if (json['points'] != null) {
      points = <Points>[];
      json['points'].forEach((v) {
        points!.add(new Points.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imei'] = this.imei;
    data['totalTrips'] = this.totalTrips;
    if (this.points != null) {
      data['points'] = this.points!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Points {
  double? lat;
  double? lng;
  String? status;
  double? distanceKm;
  int? durationMinutes;
  String? startTime;
  String? endTime;

  Points({
    this.lat,
    this.lng,
    this.status,
    this.distanceKm,
    this.durationMinutes,
    this.startTime,
    this.endTime,
  });

  Points.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
    status = json['status'];
    distanceKm = json['distanceKm'];
    durationMinutes = json['durationMinutes'];
    startTime = json['startTime'];
    endTime = json['endTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['status'] = this.status;
    data['distanceKm'] = this.distanceKm;
    data['durationMinutes'] = this.durationMinutes;
    data['startTime'] = this.startTime;
    data['endTime'] = this.endTime;
    return data;
  }
}
