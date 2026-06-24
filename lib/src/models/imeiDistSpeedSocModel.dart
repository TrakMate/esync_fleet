// class IMEIDistSpeedSocModel {
//   List<Data>? data;

//   IMEIDistSpeedSocModel({this.data});

//   IMEIDistSpeedSocModel.fromJson(Map<String, dynamic> json) {
//     if (json['data'] != null) {
//       data = <Data>[];
//       json['data'].forEach((v) {
//         data!.add(new Data.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class Data {
//   String? time;
//   double? speed;
//   double? distance;
//   double? soc;

//   Data({this.time, this.speed, this.distance, this.soc});

//   Data.fromJson(Map<String, dynamic> json) {
//     time = json['time'];
//     speed = (json['speed'] ?? 0).toDouble();
//     distance = (json['distance'] ?? 0).toDouble();
//     soc = (json['soc'] ?? 0).toDouble();
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['time'] = time;
//     data['speed'] = speed;
//     data['distance'] = distance;
//     data['soc'] = soc;
//     return data;
//   }
// }

class IMEIDistSpeedSocModel {
  List<ChartData>? oneHour;
  List<ChartData>? sixHours;
  List<ChartData>? twelveHours;
  List<ChartData>? oneDay;

  IMEIDistSpeedSocModel({
    this.oneHour,
    this.sixHours,
    this.twelveHours,
    this.oneDay,
  });

  IMEIDistSpeedSocModel.fromJson(Map<String, dynamic> json) {
    oneHour =
        (json['oneHour'] as List?)?.map((e) => ChartData.fromJson(e)).toList();

    sixHours =
        (json['sixHours'] as List?)?.map((e) => ChartData.fromJson(e)).toList();

    twelveHours =
        (json['twelveHours'] as List?)
            ?.map((e) => ChartData.fromJson(e))
            .toList();

    oneDay =
        (json['oneDay'] as List?)?.map((e) => ChartData.fromJson(e)).toList();
  }
}

class ChartData {
  String? time;
  double? speed;
  double? distance;
  double? soc;

  ChartData({this.time, this.speed, this.distance, this.soc});

  ChartData.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    speed = (json['speed'] ?? 0).toDouble();
    distance = (json['distance'] ?? 0).toDouble();
    soc = json['soc'];
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'speed': speed,
    'distance': distance,
    'soc': soc,
  };
}
