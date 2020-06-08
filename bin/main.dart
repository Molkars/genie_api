import 'package:genie_api/genie_api.dart';

Future main() async {
  final _config = GenieApiConfiguration("config.yaml");
  final app = Application<GenieApiChannel>()
      ..options.configurationFilePath = "config.yaml"
      ..options.port = _config.port;

  await app.start(numberOfInstances: _config.threads ?? Platform.numberOfProcessors ~/ 2);

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}