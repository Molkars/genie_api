import 'package:genie_api/genie_api.dart';

/// This handles the [ApplicationChannel] for the Genie API
class GenieApiChannel extends ApplicationChannel {
  // The instance of the AuthServer that handles all authentication
  AuthServer authServer;

  // The context of the application
  ManagedContext context;

  // The API Configuration file
  GenieApiConfiguration _config;

  // Prepare the application, configure the logger, config, and AuthServer
  @override
  Future prepare() async {
    // Setup the logger
    logger.onRecord.listen((rec) =>
        print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));

    // Load the application configuration
    _config = GenieApiConfiguration(options.configurationFilePath);

    // Create the application context using the info from the configuration
    context = contextWithConnectionInfo(_config.database);

    // Configure the AuthServer
    final authStorage = ManagedAuthDelegate<User>(context, tokenLimit: 10);
    authServer = AuthServer(authStorage);
  }

  // Handle all the routes in the router
  @override
  Controller get entryPoint {
    final router = Router();

    // Display the ApiDocs on the root of the API
    router.route("/").linkFunction((request) async {
      final _docs = File("client.html");
      return Response.ok(_docs.openRead())
        ..encodeBody = false
        ..contentType = ContentType.html;
    });

    // Create an account on the system
    router.route("/register")
        .link(() => RegisterController(context, authServer));

    // Handles logging into the system
    router.route("/auth/token")
        .link(() => AuthController(authServer));

    // Handles resetting user account passwords
    router.route("/reset-password/[:token]")
        .link(() => PasswordResetController(context, authServer, _config));

    // Returns the currently logged in users information
    router.route("/me")
        .link(() => Authorizer.bearer(authServer))
        .link(() => IdentityController(context));

    // Handles all the users routes
    router.route("/users/[:id([0-9]+)]")
        .link(() => Authorizer.bearer(authServer))
        .link(() => UserController(context, authServer));

    // Handles all the makerspace routes
    router
        .route("/makerspace/[:id([0-9]+)]")
        .link(() => Authorizer.bearer(authServer))
        .link(() => MakerspaceController(context));

    // Return the built router
    return router;
  }

  /// Create the [ManagedContext] that is used to define connections within the application.
  ManagedContext contextWithConnectionInfo(
      DatabaseConfiguration connectionInfo) {
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final psc = PostgreSQLPersistentStore(
        connectionInfo.username,
        connectionInfo.password,
        connectionInfo.host,
        connectionInfo.port,
        connectionInfo.databaseName);

    return ManagedContext(dataModel, psc);
  }
}