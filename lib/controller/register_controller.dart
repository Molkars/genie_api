import 'package:genie_api/genie_api.dart';

class RegisterController extends ResourceController {
  RegisterController(this.context, this.authServer);
  final ManagedContext context;
  final AuthServer authServer;

  @Operation.post()
  Future<Response> createUser(@Bind.body() User user) async {
    // Check for required parameters before we spend time hashing
    if (user.username == null || user.password == null || user.firstName == null
        || user.lastName == null || user.email == null) {
      return Response.badRequest(
          body: {"error": "Username, Password, First Name, Last Name, and Email fields are required."});
    }

    // Create the password hash
    user
      ..salt = AuthUtility.generateRandomSalt()
      ..hashedPassword = authServer.hashPassword(user.password, user.salt);

    // Return the new user
    return Response.ok(await (Query<User>(context)..values = user).insert());
  }
}