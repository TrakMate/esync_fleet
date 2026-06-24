class CanDataModel {
  int? totalCount;
  List<Entities>? entities;

  CanDataModel({this.totalCount, this.entities});

  CanDataModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];

    if (json['entities'] != null) {
      entities = <Entities>[];
      json['entities'].forEach((v) {
        entities!.add(Entities.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['totalCount'] = totalCount;

    if (entities != null) {
      data['entities'] = entities!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class Entities {
  String? imei;
  String? latitude;
  String? longitude;
  String? time;
  String? rawVoltValueOfEGRValvePosMV;
  String? engineOpererationStatus;
  String? pRVOpenCount;
  String? injectionQuantityinmgstMgHub;
  String? protectLamp;
  String? amberWarningLamp;
  String? redStopLamp;
  String? malfunctionIndicatorLamp;
  String? suspectParameterNumber;
  String? failureModeIdentifier;
  String? occurrenceCount;
  String? sPNConversionMethod;
  String? chargingSystemPotentialV;
  String? batteryPotentialPowerInput1V;
  String? barometricpressureKPa;
  String? engineOilPressure1KPa;
  String? engineWaittoStartLamp;
  String? nominalFrictionPerTorque;
  String? engineIntakeManifold1PressKPa;
  String? engineIntakeManifold1TempC;
  String? engineFuelRateLH;
  String? engineInstantaneousFuelEconomyKmL;
  String? engineAverageFuelEconomyKmL;
  String? engineCoolantTempC;
  String? engineFuelTemp1C;
  String? engineOilTemperature1C;
  String? engFuelInjectorMeterRail1PressMPa;
  String? accelPedalPos1;
  String? enginePercentLoadAtCurrentSpeed;
  String? actualMaxAvailableEngiPerTorque;
  String? driversDemandEngPerTorque;
  String? actualEngPerTorque;
  String? engineSpeedRpm;
  String? name;
  String? vehicleNumber;

  Entities({
    this.imei,
    this.latitude,
    this.longitude,
    this.time,
    this.rawVoltValueOfEGRValvePosMV,
    this.engineOpererationStatus,
    this.pRVOpenCount,
    this.injectionQuantityinmgstMgHub,
    this.protectLamp,
    this.amberWarningLamp,
    this.redStopLamp,
    this.malfunctionIndicatorLamp,
    this.suspectParameterNumber,
    this.failureModeIdentifier,
    this.occurrenceCount,
    this.sPNConversionMethod,
    this.chargingSystemPotentialV,
    this.batteryPotentialPowerInput1V,
    this.barometricpressureKPa,
    this.engineOilPressure1KPa,
    this.engineWaittoStartLamp,
    this.nominalFrictionPerTorque,
    this.engineIntakeManifold1PressKPa,
    this.engineIntakeManifold1TempC,
    this.engineFuelRateLH,
    this.engineInstantaneousFuelEconomyKmL,
    this.engineAverageFuelEconomyKmL,
    this.engineCoolantTempC,
    this.engineFuelTemp1C,
    this.engineOilTemperature1C,
    this.engFuelInjectorMeterRail1PressMPa,
    this.accelPedalPos1,
    this.enginePercentLoadAtCurrentSpeed,
    this.actualMaxAvailableEngiPerTorque,
    this.driversDemandEngPerTorque,
    this.actualEngPerTorque,
    this.engineSpeedRpm,
    this.name,
    this.vehicleNumber,
  });

  Entities.fromJson(Map<String, dynamic> json) {
    imei = json['imei']?.toString();
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    time = json['time']?.toString();

    rawVoltValueOfEGRValvePosMV =
        json['RawVoltValueOfEGRValvePos (mV)']?.toString();

    engineOpererationStatus = json['EngineOpererationStatus']?.toString();

    pRVOpenCount = json['PRVOpenCount (-)']?.toString();

    injectionQuantityinmgstMgHub =
        json['InjectionQuantityinmgst (mg/hub)']?.toString();

    protectLamp = json['ProtectLamp']?.toString();
    amberWarningLamp = json['AmberWarningLamp']?.toString();
    redStopLamp = json['RedStopLamp']?.toString();

    malfunctionIndicatorLamp = json['MalfunctionIndicatorLamp']?.toString();

    suspectParameterNumber = json['SuspectParameterNumber']?.toString();

    failureModeIdentifier = json['FailureModeIdentifier']?.toString();

    occurrenceCount = json['OccurrenceCount']?.toString();

    sPNConversionMethod = json['SPNConversionMethod']?.toString();

    chargingSystemPotentialV = json['ChargingSystemPotential (V)']?.toString();

    batteryPotentialPowerInput1V =
        json['BatteryPotential_PowerInput1 ( V)']?.toString();

    barometricpressureKPa = json['Barometricpressure (kPa)']?.toString();

    engineOilPressure1KPa = json['EngineOilPressure1 (kPa)']?.toString();

    engineWaittoStartLamp = json['EngineWaittoStartLamp']?.toString();

    nominalFrictionPerTorque = json['NominalFrictionPerTorque (%)']?.toString();

    engineIntakeManifold1PressKPa =
        json['EngineIntakeManifold1Press (kPa)']?.toString();

    engineIntakeManifold1TempC =
        json['EngineIntakeManifold1Temp (°C)']?.toString();

    engineFuelRateLH = json['EngineFuelRate (L/h)']?.toString();

    engineInstantaneousFuelEconomyKmL =
        json['EngineInstantaneousFuelEconomy (km/L)']?.toString();

    engineAverageFuelEconomyKmL =
        json['EngineAverageFuelEconomy (km/L)']?.toString();

    engineCoolantTempC = json['EngineCoolantTemp (°C)']?.toString();

    engineFuelTemp1C = json['EngineFuelTemp1 (°C)']?.toString();

    engineOilTemperature1C = json['EngineOilTemperature1 (°C)']?.toString();

    engFuelInjectorMeterRail1PressMPa =
        json['EngFuelInjectorMeterRail1Press (MPa)']?.toString();

    accelPedalPos1 = json['AccelPedalPos1 (%)']?.toString();

    enginePercentLoadAtCurrentSpeed =
        json['EnginePercentLoadAtCurrentSpeed']?.toString();

    actualMaxAvailableEngiPerTorque =
        json['ActualMaxAvailableEngiPerTorque (%)']?.toString();

    driversDemandEngPerTorque =
        json['DriversDemandEngPerTorque (%)']?.toString();

    actualEngPerTorque = json['ActualEngPerTorque (%)']?.toString();

    engineSpeedRpm = json['EngineSpeed (rpm)']?.toString();

    name = json['name']?.toString();

    vehicleNumber = json['Vehicle_Number']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'imei': imei,
      'latitude': latitude,
      'longitude': longitude,
      'time': time,
      'RawVoltValueOfEGRValvePos (mV)': rawVoltValueOfEGRValvePosMV,
      'EngineOpererationStatus': engineOpererationStatus,
      'PRVOpenCount (-)': pRVOpenCount,
      'InjectionQuantityinmgst (mg/hub)': injectionQuantityinmgstMgHub,
      'ProtectLamp': protectLamp,
      'AmberWarningLamp': amberWarningLamp,
      'RedStopLamp': redStopLamp,
      'MalfunctionIndicatorLamp': malfunctionIndicatorLamp,
      'SuspectParameterNumber': suspectParameterNumber,
      'FailureModeIdentifier': failureModeIdentifier,
      'OccurrenceCount': occurrenceCount,
      'SPNConversionMethod': sPNConversionMethod,
      'ChargingSystemPotential (V)': chargingSystemPotentialV,
      'BatteryPotential_PowerInput1 ( V)': batteryPotentialPowerInput1V,
      'Barometricpressure (kPa)': barometricpressureKPa,
      'EngineOilPressure1 (kPa)': engineOilPressure1KPa,
      'EngineWaittoStartLamp': engineWaittoStartLamp,
      'NominalFrictionPerTorque (%)': nominalFrictionPerTorque,
      'EngineIntakeManifold1Press (kPa)': engineIntakeManifold1PressKPa,
      'EngineIntakeManifold1Temp (°C)': engineIntakeManifold1TempC,
      'EngineFuelRate (L/h)': engineFuelRateLH,
      'EngineInstantaneousFuelEconomy (km/L)':
          engineInstantaneousFuelEconomyKmL,
      'EngineAverageFuelEconomy (km/L)': engineAverageFuelEconomyKmL,
      'EngineCoolantTemp (°C)': engineCoolantTempC,
      'EngineFuelTemp1 (°C)': engineFuelTemp1C,
      'EngineOilTemperature1 (°C)': engineOilTemperature1C,
      'EngFuelInjectorMeterRail1Press (MPa)': engFuelInjectorMeterRail1PressMPa,
      'AccelPedalPos1 (%)': accelPedalPos1,
      'EnginePercentLoadAtCurrentSpeed': enginePercentLoadAtCurrentSpeed,
      'ActualMaxAvailableEngiPerTorque (%)': actualMaxAvailableEngiPerTorque,
      'DriversDemandEngPerTorque (%)': driversDemandEngPerTorque,
      'ActualEngPerTorque (%)': actualEngPerTorque,
      'EngineSpeed (rpm)': engineSpeedRpm,
      'name': name,
      'Vehicle_Number': vehicleNumber,
    };
  }
}
