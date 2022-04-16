import 'dart:async';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

Builder configBuilder(BuilderOptions options) => _ConfigBuilder();

class _ConfigBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        '.yaml': <String>['.dart']
      };

  static const String _defaultConfigFileName = 'coap_config';

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;

    final fileName = path.basename(id.path);
    if (!fileName.startsWith(_defaultConfigFileName)) {
      print('No $_defaultConfigFileName file found!');
      return;
    }

    final yamlConfig = await buildStep.readAsString(id);
    final YamlMap data = loadYaml(yamlConfig);

    if (!data.containsKey('version')) {
      throw Exception('Invalid CoAP configuration file, '
          'make sure to include the [version] key');
    }

    final className = generateClassName(fileName);

    final contents = _generateFileTemplate(className, data);
    return buildStep.writeAsString(id.changeExtension('.dart'), contents);
  }
}

String generateClassName(String fileName) {
  final name = fileName.replaceAll('.yaml', '');
  return name.split('_').map((part) => part.capitalize()).join();
}

String _generateFileTemplate(String className, YamlMap data) => """
// GENERATED CODE, do not edit this file.

import 'package:coap/coap.dart';

/// Configuration loading class. The config file itself is a YAML
/// file. The configuration items below are marked as optional to allow
/// the config file to contain only those entries that override the defaults.
/// The file can't be empty, so version must as a minimum be present.
class $className extends DefaultCoapConfig {
${_generateDataScript(data)}}
""";

String _generateDataScript(YamlMap data) {
  final buff = StringBuffer();
  for (var k in data.keys) {
    buff.writeln('  @override');
    if (data[k] is String) {
      if ('true' == data[k] || 'false' == data[k]) {
        buff.writeln('  bool get $k => ${data[k]};');
        continue;
      }
      buff.writeln("  String get $k => '${data[k]}';");
    } else if (data[k] is bool) {
      buff.writeln('  bool get $k => ${data[k]};');
    } else if (data[k] is int) {
      buff.writeln('  int get $k => ${data[k]};');
    } else if (data[k] is double) {
      buff.writeln('  double get $k => ${data[k]};');
    }
    if (k != data.keys.last) {
      buff.writeln();
    }
  }
  return buff.toString();
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
