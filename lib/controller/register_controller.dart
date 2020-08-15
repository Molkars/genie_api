import 'package:genie_api/genie_api.dart';

class RegisterController extends ResourceController {
  RegisterController(this.context, this.authServer);
  final ManagedContext context;
  final AuthServer authServer;

  @Operation.post()
  Future<Response> createUser(@Bind.body(ignore: ["id"]) User user) async {
    // Check for required parameters before we spend time hashing
    if (user.username == null || user.password == null || user.firstName == null || user.lastName == null || user.email == null) {
      return Response.badRequest(body: {"error": "username, password, firstName, lastName, and email fields are required."});
    }

    // Create the password hash
    user
      ..salt = AuthUtility.generateRandomSalt()
      ..hashedPassword = authServer.hashPassword(user.password, user.salt)
      ..email = user.email.toLowerCase();

    // Return the new user
    return Response.ok(await Query<User>(context, values: user).insert());
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    var _userSchema = context.schema.getObjectWithType(User);

    context.defer(() {
      _userSchema = context.document.components.resolve(_userSchema);
      _userSchema.properties.remove("makerspacesOwned");
      _userSchema.properties.remove("tokens");
    });

    return {
      "200": APIResponse.schema("User successfully registered.", _userSchema),
    };
  }
}