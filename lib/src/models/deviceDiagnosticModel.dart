class DeviceDiagnosticModel {
  String? iMEI;
  Battery? battery;
  Location? location;

  DeviceDiagnosticModel({this.iMEI, this.battery, this.location});

  DeviceDiagnosticModel.fromJson(Map<String, dynamic> json) {
    iMEI = json['IMEI'];
    battery =
        json['Battery'] != null ? new Battery.fromJson(json['Battery']) : null;
    location =
        json['Location'] != null
            ? new Location.fromJson(json['Location'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['IMEI'] = this.iMEI;
    if (this.battery != null) {
      data['Battery'] = this.battery!.toJson();
    }
    if (this.location != null) {
      data['Location'] = this.location!.toJson();
    }
    return data;
  }
}

class Battery {
  String? time;
  double? voltage;
  double? current;
  int? soc;
  int? soh;
  int? cycleCount;
  String? chargingStatus;
  double? odometer;
  double? temperature;
  double? energyConsumption;
  double? distanceEmpty;
  String? ignition;
  double? cell1;
  double? cell2;
  double? cell3;
  double? cell4;
  double? cell5;
  double? cell6;
  double? cell7;
  double? cell8;
  double? cell9;
  double? cell10;
  double? cell11;
  double? cell12;
  double? cell13;
  double? cell14;
  double? cell15;
  double? cell16;
  double? cell17;
  double? cell18;
  double? cell19;
  double? cell20;
  double? cell21;
  double? cell22;
  double? cell23;
  double? cell24;
  double? cell25;
  double? cell26;
  double? cell27;
  double? cell28;
  double? cell29;
  double? cell30;
  double? tempSensor1;
  double? tempSensor2;
  double? tempSensor3;
  double? tempSensor4;
  double? tempSensor5;
  double? tempSensor6;
  double? tempSensor7;
  double? vcc;
  double? tcc;

  Battery({
    this.time,
    this.voltage,
    this.current,
    this.soc,
    this.soh,
    this.cycleCount,
    this.chargingStatus,
    this.odometer,
    this.temperature,
    this.energyConsumption,
    this.distanceEmpty,
    this.ignition,
    this.cell1,
    this.cell2,
    this.cell3,
    this.cell4,
    this.cell5,
    this.cell6,
    this.cell7,
    this.cell8,
    this.cell9,
    this.cell10,
    this.cell11,
    this.cell12,
    this.cell13,
    this.cell14,
    this.cell15,
    this.cell16,
    this.cell17,
    this.cell18,
    this.cell19,
    this.cell20,
    this.cell21,
    this.cell22,
    this.cell23,
    this.cell24,
    this.cell25,
    this.cell26,
    this.cell27,
    this.cell28,
    this.cell29,
    this.cell30,
    this.tempSensor1,
    this.tempSensor2,
    this.tempSensor3,
    this.tempSensor4,
    this.tempSensor5,
    this.tempSensor6,
    this.tempSensor7,
    this.vcc,
    this.tcc,
  });

  Battery.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    voltage = json['voltage'];
    current = json['current'];
    soc = json['soc'];
    soh = json['soh'];
    cycleCount = json['cycle_count'];
    chargingStatus = json['charging_status'];
    odometer = json['odometer'];
    temperature = json['temperature'];
    energyConsumption = json['energy_consumption'];
    distanceEmpty = json['distance_empty'];
    ignition = json['ignition'];
    cell1 = json['Cell_1'];
    cell2 = json['Cell_2'];
    cell3 = json['Cell_3'];
    cell4 = json['Cell_4'];
    cell5 = json['Cell_5'];
    cell6 = json['Cell_6'];
    cell7 = json['Cell_7'];
    cell8 = json['Cell_8'];
    cell9 = json['Cell_9'];
    cell10 = json['Cell_10'];
    cell11 = json['Cell_11'];
    cell12 = json['Cell_12'];
    cell13 = json['Cell_13'];
    cell14 = json['Cell_14'];
    cell15 = json['Cell_15'];
    cell16 = json['Cell_16'];
    cell17 = json['Cell_17'];
    cell18 = json['Cell_18'];
    cell19 = json['Cell_19'];
    cell20 = json['Cell_20'];
    cell21 = json['Cell_21'];
    cell22 = (json['Cell_22'] as num?)?.toDouble();
    cell23 = (json['Cell_23'] as num?)?.toDouble();
    cell24 = (json['Cell_24'] as num?)?.toDouble();
    cell25 = (json['Cell_25'] as num?)?.toDouble();
    cell26 = (json['Cell_26'] as num?)?.toDouble();
    cell27 = (json['Cell_27'] as num?)?.toDouble();
    cell28 = (json['Cell_28'] as num?)?.toDouble();
    cell29 = (json['Cell_29'] as num?)?.toDouble();
    cell30 = (json['Cell_30'] as num?)?.toDouble();
    tempSensor1 = json['TempSensor_1'];
    tempSensor2 = json['TempSensor_2'];
    tempSensor3 = json['TempSensor_3'];
    tempSensor4 = json['TempSensor_4'];
    tempSensor5 = json['TempSensor_5'];
    tempSensor6 = json['TempSensor_6'];
    tempSensor7 = json['TempSensor_7'];
    vcc = json['VCC'];
    tcc = json['TCC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['voltage'] = this.voltage;
    data['current'] = this.current;
    data['soc'] = this.soc;
    data['soh'] = this.soh;
    data['cycle_count'] = this.cycleCount;
    data['charging_status'] = this.chargingStatus;
    data['odometer'] = this.odometer;
    data['temperature'] = this.temperature;
    data['energy_consumption'] = this.energyConsumption;
    data['distance_empty'] = this.distanceEmpty;
    data['ignition'] = this.ignition;
    data['Cell_1'] = this.cell1;
    data['Cell_2'] = this.cell2;
    data['Cell_3'] = this.cell3;
    data['Cell_4'] = this.cell4;
    data['Cell_5'] = this.cell5;
    data['Cell_6'] = this.cell6;
    data['Cell_7'] = this.cell7;
    data['Cell_8'] = this.cell8;
    data['Cell_9'] = this.cell9;
    data['Cell_10'] = this.cell10;
    data['Cell_11'] = this.cell11;
    data['Cell_12'] = this.cell12;
    data['Cell_13'] = this.cell13;
    data['Cell_14'] = this.cell14;
    data['Cell_15'] = this.cell15;
    data['Cell_16'] = this.cell16;
    data['Cell_17'] = this.cell17;
    data['Cell_18'] = this.cell18;
    data['Cell_19'] = this.cell19;
    data['Cell_20'] = this.cell20;
    data['Cell_21'] = this.cell21;
    data['Cell_22'] = this.cell22;
    data['Cell_23'] = this.cell23;
    data['Cell_24'] = this.cell24;
    data['Cell_25'] = this.cell25;
    data['Cell_26'] = this.cell26;
    data['Cell_27'] = this.cell27;
    data['Cell_28'] = this.cell28;
    data['Cell_29'] = this.cell29;
    data['Cell_30'] = this.cell30;
    data['TempSensor_1'] = this.tempSensor1;
    data['TempSensor_2'] = this.tempSensor2;
    data['TempSensor_3'] = this.tempSensor3;
    data['TempSensor_4'] = this.tempSensor4;
    data['TempSensor_5'] = this.tempSensor5;
    data['TempSensor_6'] = this.tempSensor6;
    data['TempSensor_7'] = this.tempSensor7;
    data['VCC'] = this.vcc;
    data['TCC'] = this.tcc;
    return data;
  }
}

class Location {
  String? time;
  double? vehvoltage;
  double? intvoltage;
  String? ignition;
  double? odometer;
  int? sos;
  String? fourWd;
  int? temperature;
  int? fuelLevel;
  int? rpm;
  String? pto;
  double? speed;
  Null? adblue;

  Location({
    this.time,
    this.vehvoltage,
    this.intvoltage,
    this.ignition,
    this.odometer,
    this.sos,
    this.fourWd,
    this.temperature,
    this.fuelLevel,
    this.rpm,
    this.pto,
    this.speed,
    this.adblue,
  });

  Location.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    vehvoltage = json['vehvoltage'];
    intvoltage = json['intvoltage'];
    ignition = json['ignition'];
    odometer = json['odometer'];
    sos = json['sos'];
    fourWd = json['four_wd'];
    temperature = json['temperature'];
    fuelLevel = json['fuel_level'];
    rpm = json['rpm'];
    pto = json['pto'];
    speed = json['speed'];
    adblue = json['adblue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['vehvoltage'] = this.vehvoltage;
    data['intvoltage'] = this.intvoltage;
    data['ignition'] = this.ignition;
    data['odometer'] = this.odometer;
    data['sos'] = this.sos;
    data['four_wd'] = this.fourWd;
    data['temperature'] = this.temperature;
    data['fuel_level'] = this.fuelLevel;
    data['rpm'] = this.rpm;
    data['pto'] = this.pto;
    data['speed'] = this.speed;
    data['adblue'] = this.adblue;
    return data;
  }
}
