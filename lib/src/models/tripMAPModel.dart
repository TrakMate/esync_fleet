class TripMapPerTripModel {
  List<Data>? data;
  List<TripStats>? tripStats;
  double? centerLat;
  double? centerLng;
  int? zoom;
  String? vehicleNumber;
  String? imei;

  TripMapPerTripModel({
    this.data,
    this.tripStats,
    this.centerLat,
    this.centerLng,
    this.zoom,
    this.vehicleNumber,
    this.imei,
  });

  TripMapPerTripModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    if (json['tripStats'] != null) {
      tripStats = <TripStats>[];
      json['tripStats'].forEach((v) {
        tripStats!.add(new TripStats.fromJson(v));
      });
    }
    centerLat = json['centerLat'];
    centerLng = json['centerLng'];
    zoom = json['zoom'];
    vehicleNumber = json['vehicleNumber'];
    imei = json['imei'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.tripStats != null) {
      data['tripStats'] = this.tripStats!.map((v) => v.toJson()).toList();
    }
    data['centerLat'] = this.centerLat;
    data['centerLng'] = this.centerLng;
    data['zoom'] = this.zoom;
    data['vehicleNumber'] = this.vehicleNumber;
    data['imei'] = this.imei;
    return data;
  }
}

class Data {
  String? lat;
  String? lng;
  String? speed;
  String? odo;
  String? time;

  Data({this.lat, this.lng, this.speed, this.odo, this.time});

  Data.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
    speed = json['speed'];
    odo = json['odo'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['speed'] = this.speed;
    data['odo'] = this.odo;
    data['time'] = this.time;
    return data;
  }
}

class TripStats {
  String? id;
  String? imei;
  String? tripId;
  String? orgId;
  String? time;
  Location? location;
  String? address;
  int? idlingInSeconds;

  TripStats({
    this.id,
    this.imei,
    this.tripId,
    this.orgId,
    this.time,
    this.location,
    this.address,
    this.idlingInSeconds,
  });

  TripStats.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    imei = json['imei'];
    tripId = json['tripId'];
    orgId = json['orgId'];
    time = json['time'];
    location =
        json['location'] != null
            ? new Location.fromJson(json['location'])
            : null;
    address = json['address'];
    idlingInSeconds = json['idlingInSeconds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['imei'] = this.imei;
    data['tripId'] = this.tripId;
    data['orgId'] = this.orgId;
    data['time'] = this.time;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['address'] = this.address;
    data['idlingInSeconds'] = this.idlingInSeconds;
    return data;
  }
}

class Location {
  double? x;
  double? y;

  Location({this.x, this.y});

  Location.fromJson(Map<String, dynamic> json) {
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
