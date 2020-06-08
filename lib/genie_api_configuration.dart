import 'package:genie_api/genie_api.dart';

/// Configure the [Configuration] for the application.
class GenieApiConfiguration extends Configuration {
  GenieApiConfiguration(String fileName) : super.fromFile(File(fileName));

  DatabaseConfiguration database;
  int threads;
  int port;
}