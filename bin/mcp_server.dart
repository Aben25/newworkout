import 'dart:convert';
import 'dart:io';

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('MCP server listening on port ${server.port}');

  await for (var request in server) {
    if (request.uri.path == '/mcp') {
      handleMcpRequest(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }
}

void handleMcpRequest(HttpRequest request) {
  if (request.method == 'GET') {
    final response = {
      'tools': [
        {
          'functionDeclarations': [
            {
              'name': 'get_workout_recommendations',
              'description': 'Get workout recommendations for the user.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'userId': {
                    'type': 'string',
                    'description': 'The ID of the user.'
                  }
                },
                'required': ['userId']
              }
            }
          ]
        }
      ]
    };
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response))
      ..close();
  } else if (request.method == 'POST') {
    // Handle tool execution requests here
    request.response
      ..statusCode = HttpStatus.notImplemented
      ..write('Tool execution not implemented yet.')
      ..close();
  } else {
    request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..write('Method not allowed')
      ..close();
  }
}
