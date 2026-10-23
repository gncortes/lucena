import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// O modelo e o fabricante do celular, para o "Enviar feedback". Só esses
/// dois campos: nada que identifique o aparelho.
class DeviceModel {
  const DeviceModel({this.model, this.manufacturer});

  final String? model;
  final String? manufacturer;
}

abstract class DeviceService {
  Future<DeviceModel> model();
}

/// Lê pelo `device_info_plus`. Fora do Android e do iOS, ou se a leitura
/// falha, vai vazio.
class PluginDeviceService implements DeviceService {
  PluginDeviceService([DeviceInfoPlugin? plugin])
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  @override
  Future<DeviceModel> model() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _plugin.androidInfo;
        return DeviceModel(model: info.model, manufacturer: info.manufacturer);
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _plugin.iosInfo;
        return DeviceModel(model: info.model, manufacturer: 'Apple');
      }
    } on Exception {
      // Sem o modelo, o feedback vai do mesmo jeito.
    }
    return const DeviceModel();
  }
}

class NoDeviceService implements DeviceService {
  const NoDeviceService();

  @override
  Future<DeviceModel> model() async => const DeviceModel();
}
