import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/devicesModel.dart';

void openDeviceOverview(BuildContext context, DeviceEntity device) {
  context.pushNamed(
    'deviceOverview',
    pathParameters: {'imei': device.imei ?? ''},
    extra: device,
  );
}

void openDeviceDiagnostics(BuildContext context, DeviceEntity device) {
  context.pushNamed(
    'deviceDiagnostics',
    pathParameters: {'imei': device.imei ?? ''},
    extra: device,
  );
}

void openDeviceConfiguration(BuildContext context, DeviceEntity device) {
  context.pushNamed(
    'deviceConfiguration',
    pathParameters: {'imei': device.imei ?? ''},
    extra: device,
  );
}
