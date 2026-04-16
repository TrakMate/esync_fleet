class BatteryReportModel {
  String? time;
  int? soc;
  int? soh;
  int? vol;
  int? cur;
  double? cellVolt1;
  double? cellVolt2;
  double? cellVolt3;
  double? cellVolt4;
  double? cellVolt5;
  double? cellVolt6;
  double? cellVolt7;
  double? cellVolt8;
  double? cellVolt9;
  double? cellVolt10;
  double? cellVolt11;
  double? cellVolt12;
  double? cellVolt13;
  double? cellVolt14;
  double? cellVolt15;
  double? cellVolt16;
  Null? cellVolt17;
  Null? cellVolt18;
  Null? cellVolt19;
  Null? cellVolt20;
  Null? cellVolt21;
  Null? cellVolt22;
  Null? cellVolt23;
  Null? cellVolt24;
  double? tempSensor1;
  double? tempSensor2;
  double? tempSensor3;
  double? tempSensor4;
  double? tempSensor5;
  Null? tempSensor6;
  Null? tempSensor7;
  Null? tempSensor8;
  int? dte;
  int? cycle;
  int? ccap;
  String? serialno;
  String? productID;
  int? mchgv;
  int? maxchgc;
  int? cellvCnt;
  double? cellvMin;
  int? cellvImin;
  double? cellvMax;
  int? cellvImax;
  double? tempBatt;
  int? tempCnt;
  double? tempMin;
  int? tempImin;
  double? tempMax;
  int? tempImax;
  String? chgdsg;
  double? lat;
  double? lng;

  BatteryReportModel({
    this.time,
    this.soc,
    this.soh,
    this.vol,
    this.cur,
    this.cellVolt1,
    this.cellVolt2,
    this.cellVolt3,
    this.cellVolt4,
    this.cellVolt5,
    this.cellVolt6,
    this.cellVolt7,
    this.cellVolt8,
    this.cellVolt9,
    this.cellVolt10,
    this.cellVolt11,
    this.cellVolt12,
    this.cellVolt13,
    this.cellVolt14,
    this.cellVolt15,
    this.cellVolt16,
    this.cellVolt17,
    this.cellVolt18,
    this.cellVolt19,
    this.cellVolt20,
    this.cellVolt21,
    this.cellVolt22,
    this.cellVolt23,
    this.cellVolt24,
    this.tempSensor1,
    this.tempSensor2,
    this.tempSensor3,
    this.tempSensor4,
    this.tempSensor5,
    this.tempSensor6,
    this.tempSensor7,
    this.tempSensor8,
    this.dte,
    this.cycle,
    this.ccap,
    this.serialno,
    this.productID,
    this.mchgv,
    this.maxchgc,
    this.cellvCnt,
    this.cellvMin,
    this.cellvImin,
    this.cellvMax,
    this.cellvImax,
    this.tempBatt,
    this.tempCnt,
    this.tempMin,
    this.tempImin,
    this.tempMax,
    this.tempImax,
    this.chgdsg,
    this.lat,
    this.lng,
  });

  BatteryReportModel.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    soc = json['soc'];
    soh = json['soh'];
    vol = json['vol'];
    cur = json['cur'];
    cellVolt1 = json['cellVolt_1'];
    cellVolt2 = json['cellVolt_2'];
    cellVolt3 = json['cellVolt_3'];
    cellVolt4 = json['cellVolt_4'];
    cellVolt5 = json['cellVolt_5'];
    cellVolt6 = json['cellVolt_6'];
    cellVolt7 = json['cellVolt_7'];
    cellVolt8 = json['cellVolt_8'];
    cellVolt9 = json['cellVolt_9'];
    cellVolt10 = json['cellVolt_10'];
    cellVolt11 = json['cellVolt_11'];
    cellVolt12 = json['cellVolt_12'];
    cellVolt13 = json['cellVolt_13'];
    cellVolt14 = json['cellVolt_14'];
    cellVolt15 = json['cellVolt_15'];
    cellVolt16 = json['cellVolt_16'];
    cellVolt17 = json['cellVolt_17'];
    cellVolt18 = json['cellVolt_18'];
    cellVolt19 = json['cellVolt_19'];
    cellVolt20 = json['cellVolt_20'];
    cellVolt21 = json['cellVolt_21'];
    cellVolt22 = json['cellVolt_22'];
    cellVolt23 = json['cellVolt_23'];
    cellVolt24 = json['cellVolt_24'];
    tempSensor1 = json['tempSensor_1'];
    tempSensor2 = json['tempSensor_2'];
    tempSensor3 = json['tempSensor_3'];
    tempSensor4 = json['tempSensor_4'];
    tempSensor5 = json['tempSensor_5'];
    tempSensor6 = json['tempSensor_6'];
    tempSensor7 = json['tempSensor_7'];
    tempSensor8 = json['tempSensor_8'];
    dte = json['dte'];
    cycle = json['cycle'];
    ccap = json['ccap'];
    serialno = json['serialno'];
    productID = json['productID'];
    mchgv = json['mchgv'];
    maxchgc = json['maxchgc'];
    cellvCnt = json['cellv_cnt'];
    cellvMin = json['cellv_min'];
    cellvImin = json['cellv_imin'];
    cellvMax = json['cellv_max'];
    cellvImax = json['cellv_imax'];
    tempBatt = json['temp_batt'];
    tempCnt = json['temp_cnt'];
    tempMin = json['temp_min'];
    tempImin = json['temp_imin'];
    tempMax = json['temp_max'];
    tempImax = json['temp_imax'];
    chgdsg = json['chgdsg'];
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['soc'] = this.soc;
    data['soh'] = this.soh;
    data['vol'] = this.vol;
    data['cur'] = this.cur;
    data['cellVolt_1'] = this.cellVolt1;
    data['cellVolt_2'] = this.cellVolt2;
    data['cellVolt_3'] = this.cellVolt3;
    data['cellVolt_4'] = this.cellVolt4;
    data['cellVolt_5'] = this.cellVolt5;
    data['cellVolt_6'] = this.cellVolt6;
    data['cellVolt_7'] = this.cellVolt7;
    data['cellVolt_8'] = this.cellVolt8;
    data['cellVolt_9'] = this.cellVolt9;
    data['cellVolt_10'] = this.cellVolt10;
    data['cellVolt_11'] = this.cellVolt11;
    data['cellVolt_12'] = this.cellVolt12;
    data['cellVolt_13'] = this.cellVolt13;
    data['cellVolt_14'] = this.cellVolt14;
    data['cellVolt_15'] = this.cellVolt15;
    data['cellVolt_16'] = this.cellVolt16;
    data['cellVolt_17'] = this.cellVolt17;
    data['cellVolt_18'] = this.cellVolt18;
    data['cellVolt_19'] = this.cellVolt19;
    data['cellVolt_20'] = this.cellVolt20;
    data['cellVolt_21'] = this.cellVolt21;
    data['cellVolt_22'] = this.cellVolt22;
    data['cellVolt_23'] = this.cellVolt23;
    data['cellVolt_24'] = this.cellVolt24;
    data['tempSensor_1'] = this.tempSensor1;
    data['tempSensor_2'] = this.tempSensor2;
    data['tempSensor_3'] = this.tempSensor3;
    data['tempSensor_4'] = this.tempSensor4;
    data['tempSensor_5'] = this.tempSensor5;
    data['tempSensor_6'] = this.tempSensor6;
    data['tempSensor_7'] = this.tempSensor7;
    data['tempSensor_8'] = this.tempSensor8;
    data['dte'] = this.dte;
    data['cycle'] = this.cycle;
    data['ccap'] = this.ccap;
    data['serialno'] = this.serialno;
    data['productID'] = this.productID;
    data['mchgv'] = this.mchgv;
    data['maxchgc'] = this.maxchgc;
    data['cellv_cnt'] = this.cellvCnt;
    data['cellv_min'] = this.cellvMin;
    data['cellv_imin'] = this.cellvImin;
    data['cellv_max'] = this.cellvMax;
    data['cellv_imax'] = this.cellvImax;
    data['temp_batt'] = this.tempBatt;
    data['temp_cnt'] = this.tempCnt;
    data['temp_min'] = this.tempMin;
    data['temp_imin'] = this.tempImin;
    data['temp_max'] = this.tempMax;
    data['temp_imax'] = this.tempImax;
    data['chgdsg'] = this.chgdsg;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}
