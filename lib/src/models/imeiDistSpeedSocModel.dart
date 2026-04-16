// class IMEIDistSpeedSocModel {
//   String? imei;
//   List<DistanceSpeedSocEntities>? entities;

//   IMEIDistSpeedSocModel({this.imei, this.entities});

//   IMEIDistSpeedSocModel.fromJson(Map<String, dynamic> json) {
//     imei = json['imei'];
//     if (json['entities'] != null) {
//       entities = <DistanceSpeedSocEntities>[];
//       json['entities'].forEach((v) {
//         entities!.add(new DistanceSpeedSocEntities.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['imei'] = this.imei;
//     if (this.entities != null) {
//       data['entities'] = this.entities!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class DistanceSpeedSocEntities {
//   final String? timeHr;
//   final double? soc;
//   final double? distance;
//   final double? speed;

//   DistanceSpeedSocEntities({this.timeHr, this.soc, this.distance, this.speed});

//   factory DistanceSpeedSocEntities.fromJson(Map<String, dynamic> json) {
//     return DistanceSpeedSocEntities(
//       timeHr: json['time_hr'] as String?,
//       soc: (json['soc'] as num?)?.toDouble(),
//       distance: (json['Distance'] as num?)?.toDouble(),
//       speed: (json['speed'] as num?)?.toDouble(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['time_hr'] = this.timeHr;
//     data['soc'] = this.soc;
//     data['Distance'] = this.distance;
//     data['speed'] = this.speed;
//     return data;
//   }
// }

class IMEIDistSpeedSocModel {
  List<Data>? data;

  IMEIDistSpeedSocModel({this.data});

  IMEIDistSpeedSocModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? time;
  double? speed;
  double? distance;
  double? soc;

  Data({this.time, this.speed, this.distance, this.soc});

  Data.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    speed = (json['speed'] ?? 0).toDouble();
    distance = (json['distance'] ?? 0).toDouble();
    soc = (json['soc'] ?? 0).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['time'] = time;
    data['speed'] = speed;
    data['distance'] = distance;
    data['soc'] = soc;
    return data;
  }
}
