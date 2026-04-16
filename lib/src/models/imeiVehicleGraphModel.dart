class IMEIVehicleGraphModel {
  List<VehicleGraph>? vehicleGraph;

  IMEIVehicleGraphModel({this.vehicleGraph});

  IMEIVehicleGraphModel.fromJson(Map<String, dynamic> json) {
    if (json['vehicleGraph'] != null) {
      vehicleGraph = <VehicleGraph>[];
      json['vehicleGraph'].forEach((v) {
        vehicleGraph!.add(new VehicleGraph.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.vehicleGraph != null) {
      data['vehicleGraph'] = this.vehicleGraph!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VehicleGraph {
  String? time;
  double? moving;
  double? idle;
  double? halted;
  double? stopped;

  VehicleGraph({this.time, this.moving, this.idle, this.halted, this.stopped});

  VehicleGraph.fromJson(Map<String, dynamic> json) {
    time = json['time'];

    moving = (json['Moving'] ?? 0).toDouble();
    idle = (json['Idle'] ?? 0).toDouble();
    halted = (json['Halted'] ?? 0).toDouble();
    stopped = (json['Stopped'] ?? 0).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['time'] = time;
    data['Moving'] = moving;
    data['Idle'] = idle;
    data['Halted'] = halted;
    data['Stopped'] = stopped;
    return data;
  }
}
