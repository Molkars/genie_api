import 'package:genie_api/genie_api.dart';

/// This [ResourceController] handles the endpoint to preform CRUD operations
/// on [Makerspace]s. It is only accessible after logging in with OAuth2.0
class MakerspaceController extends ResourceController {
  MakerspaceController(this.context);
  final ManagedContext context;

  /// Returns a JSON formatted list of all [Makerspace]s in the database.
  @Operation.get()
  Future<Response> getAllMakerspaces() async {
    return Response.ok(await Query<Makerspace>(context).fetch());
  }

  /// Returns the [Makerspace] from the database specified by the [id].
  @Operation.get('id')
  Future<Response> getMakerspace(@Bind.path("id") int id) async {
    // Get the makerspace specified from the database
    final _makerspace = await (Query<Makerspace>(context)
      ..where((makerspace) => makerspace.id).equalTo(id)
    ).fetchOne();

    // Return an error if the makerspace was not located in the database
    if (_makerspace == null) {
      return Response.notFound();
    }

    // Return the makerspace specified
    return Response.ok(_makerspace);
  }

  /// Create a new [Makerspace] and add it to the database. The new makerspace will
  /// be owned by the [User] who sent the POST request. The only field require to be
  /// passed into the request is the name of the new makerspace.
  @Operation.post()
  Future<Response> createMakerspace(@Bind.body(ignore: ['id', 'owner'], require: ['name']) Makerspace makerspace) async {
    // Set the default colors of the makerspace if the user did not supply them
    makerspace.primaryColor ??= 4279060385;
    makerspace.secondaryColor ??= 4279079585;

    // Add the makerspace to the database
    final _makerspace = await (Query<Makerspace>(context)
        ..values = makerspace
        ..values.owner.id = request.authorization.ownerID
    ).insert();

    // Return an error if the makerspace could not be created for some reason
    if (_makerspace == null) {
      return Response.serverError(body: 'There was an error creating this makerspace. Please try again later.');
    }

    // Return the newly created makerspace
    return Response.ok(_makerspace);
  }

  /// Update the [Makerspace] with the specified [id].
  @Operation('PATCH', 'id')
  Future<Response> updateMakerspace(@Bind.path('id') int id, @Bind.body(ignore: ['id']) Makerspace makerspace) async {
    // Get the current settings of the makerspace specified
    final _current = await (Query<Makerspace>(context)
      ..where((m) => m.id).equalTo(id)
    ).fetchOne();

    // Return an error if the user making the request is not the current owner of the makerspace specified
    if (_current == null) {
      return Response.notFound();
    } else if (_current.owner.id != request.authorization.ownerID) {
      return Response.unauthorized();
    }

    // Update the makerspace in the database
    final _updatedMakerspace = await (Query<Makerspace>(context)
        ..values = makerspace
        ..where((m) => m.id).equalTo(id)
    ).updateOne();

    // Return an error if there was an issue updating the makerspace
    if (_updatedMakerspace == null) {
      return Response.badRequest();
    }

    // Return the updated makerspace
    return Response.ok(_updatedMakerspace);
  }

  /// Deletes the [Makerspace] with the specified [id] from the database.
  @Operation.delete('id')
  Future<Response> deleteMakerspace(@Bind.path('id') int id) async {
    // Get the current settings of the makerspace specified
    final _current = await (Query<Makerspace>(context)
      ..where((m) => m.id).equalTo(id)
    ).fetchOne();

    // Return an error if the user making the request is not the current owner of the makerspace specified
    if (_current == null) {
      return Response.notFound();
    } else if (_current.owner.id != request.authorization.ownerID) {
      return Response.unauthorized();
    }

    // Delete the makerspace from the database
    await (Query<Makerspace>(context)
        ..where((m) => m.id).equalTo(id)
    ).delete();

    // Return a 200 response when the makerspace was deleted
    return Response.ok(null);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    if (operation.pathVariables.isEmpty && operation.method == "GET") {
      return {
        "200": APIResponse.schema("Makerspaces Fetched Successfully", context.schema.getObjectWithType(Makerspace))
      };
    } else if (operation.pathVariables.isNotEmpty && operation.method == "GET") {
      return {
        "200": APIResponse.schema("Makerspace Fetched Successfully", context.schema.getObjectWithType(Makerspace))
      };
    } else if (operation.pathVariables.isEmpty && operation.method == "POST") {
      return {
        "200": APIResponse.schema("Makerspace Created Successfully", context.schema.getObjectWithType(Makerspace))
      };
    } else if (operation.pathVariables.isNotEmpty && operation.method == "PATCH") {
      return {
        "200": APIResponse.schema("Makerspace Updated Successfully", context.schema.getObjectWithType(Makerspace))
      };
    }
    return null;
  }
}