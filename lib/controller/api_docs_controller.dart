import 'package:genie_api/genie_api.dart';

/// This [ResourceController] handles the endpoint to display the ApiDocs generated
/// with the aqueduct document client command.
class ApiDocsController extends ResourceController {

  /// Returns the ApiDocs file
  @Operation.get()
  Future<Response> getApiDocs() async {
    return Response.ok(File("client.html").readAsStringSync())..contentType = ContentType("application", "html");
  }
}