class DownloadTripModel {
  String? tripId;
  String? vehicleNumber;
  String? imei;
  List<TripStatus>? tripStatus;

  DownloadTripModel({
    this.tripId,
    this.vehicleNumber,
    this.imei,
    this.tripStatus,
  });

  DownloadTripModel.fromJson(Map<String, dynamic> json) {
    tripId = json['tripId'];
    vehicleNumber = json['vehicleNumber'];
    imei = json['imei'];
    if (json['tripStatus'] != null) {
      tripStatus = <TripStatus>[];
      json['tripStatus'].forEach((v) {
        tripStatus!.add(new TripStatus.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tripId'] = this.tripId;
    data['vehicleNumber'] = this.vehicleNumber;
    data['imei'] = this.imei;
    if (this.tripStatus != null) {
      data['tripStatus'] = this.tripStatus!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TripStatus {
  String? time;
  String? lat;
  String? lng;
  String? speed;
  String? odo;
  String? soc;
  String? locVol;
  String? battVol;
  String? fuel;

  TripStatus({
    this.time,
    this.lat,
    this.lng,
    this.speed,
    this.odo,
    this.soc,
    this.locVol,
    this.battVol,
    this.fuel,
  });

  TripStatus.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    lat = json['lat'];
    lng = json['lng'];
    speed = json['speed'];
    odo = json['odo'];
    soc = json['soc'];
    locVol = json['locVol'];
    battVol = json['battVol'];
    fuel = json['fuel'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['speed'] = this.speed;
    data['odo'] = this.odo;
    data['soc'] = this.soc;
    data['locVol'] = this.locVol;
    data['battVol'] = this.battVol;
    data['fuel'] = this.fuel;
    return data;
  }
}
