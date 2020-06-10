# genie_api

## Database

You will need a local database for testing, and another database for running the application locally. The behavior and configuration of these databases are documented here: http://aqueduct.io/docs/testing/mixins/.

To run tests, you must have a configuration file named `config.src.yaml`. By default, it is configured to connect your application to a database named `dart_test` (documented in the link above) and should not need to be edited. Tables are automatically created and deleted during test execution.

To run your application locally, you must have a `config.yaml` file that has correct database connection info, which should point to a local database specific to your application (documented in link above).
When running locally, you must apply database migrations to your database before using it. The following commands generate a migration file from your project and then apply it to a database. Replace your database's connection details with the details below.

```
aqueduct db generate
aqueduct db upgrade --connect postgres://dart:dart@localhost:5432/genie_api
```

### Configure OAuth

To run your application locally, you must also register OAuth 2.0 clients in the application database. Use the same database credentials after you have applied the migration.

```
aqueduct auth add-client --id com.local.test \
    --secret mysecret \
    --connect postgres://user:password@localhost:5432/genie_api
```

To run your tests with OAuth 2.0 client identifiers, see this documentation: http://aqueduct.io/docs/testing/mixins/#testing-applications-that-use-oauth-20.

<br>

## Running the server locally

Run `aqueduct serve` from this directory to run the application. For running within an IDE, run `bin/main.dart`.

<br>

## Running CURL commands to test the end points

The following CURL commands are valid HTTP requests for the routes configured by generating this project. If you get a 503 error, your application is not connecting to the database.

### Register a user (POST /register)

To register a new user, send a `POST /register` request. Use the following CURL command and replace the `<username>` and `<password>` with your new user.

```bash
curl -X POST http://localhost:8888/register -H 'Content-Type: application/json' -d '{"username":"<username>", "password": "<password>", "firstName": "<first name>", "lastName": "<last name>", "email": "<email>", "profilePictureUrl": "<someurl>"}' -v
```

You should see a response similar to this:

```JSON
{
  "id": 8,
  "firstName": "Brandan",
  "lastName": "Schmitz",
  "username": "brandan-schmitz",
  "email": "brandan.schmitz@celestialdata.net",
  "profilePictureUrl": "https://avatars0.githubusercontent.com/u/6267549",
}
```

### Login (POST /login)

To login to the API and get an `access_token` that can be used for authorizing with protected endpoints, send a `POST /login` request. Use the following CURL command and replace the `<username>` and `<password>` values with your own. You will also need to replace `<token>` with the Base64 encoded value of your client ID and secret. If the client does not have a secret, then it is ommitted. You still need to add the seperating `:` behind the id of your client when converting to base64. An example command of converting the client-id of `genie.mobile` to base64 is provided below.

```bash
echo "genie.mobile:" | base64
```

```bash
curl -X POST http://localhost:8888/login -H 'Content-Type: application/x-www-form-urlencoded' -H "Authorization": "Basic <token>" -d "grant_type=password&username=<username>&password=<password>"
```

You should see a response similar to this:

```bash
{
	"access_token":"pWsghYSfxat0ibhQaPnSNjiULFEuFCzA",
	"token_type":"bearer",
	"expires_in":86399
}
```

You will need to use the `access_token` in order to access protected endpoints.

<br>

## Swagger UI Client

To generate a SwaggerUI client, run `aqueduct document client`.

<br>

## Client Packages

To generate client libraries for use in other programs, you will need to install the [openapi-generator](https://openapi-generator.tech) tool. Once you have it installed, review the list of supported client generators [here](https://openapi-generator.tech/docs/generators). Once you know the name of the generator you wish to use, follow the steps below.

1. Generate a OpenAPI3.0 Specification JSON file from your Aqueduct project. To do this, open a terminal window and move to your projects base folder and run the following command:

   ```bash
   aqueduct document --machine > specfile.json
   ```

   This will produce a `specfile.json` file in the root of your project directory that can be used in the next step to generate your client library.

2. Run the openapi-generator generate command below, replacing the `<generator>` with the name of the generator that you choose earlier and `</path/to/client>` with the folder path you want the generator to be created in. Please note that this will create a folder and place the client in that folder.

   ```bash
   openapi-generator generate -g <generator> -i specfile.json -o </path/to/client>
   ```

   For example, the following command will generate a dart client inside a client folder in the current directory you are in (your project folder).

   ```bash
   openapi-generator generate -g dart -i specfile.json -o client
   ```