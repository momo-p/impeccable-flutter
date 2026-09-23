import 'dart:io';

/// Minimal static server so headless Chrome can load the built app.
Future<void> main(List<String> argv) async {
  final root = Directory(argv[0]);
  final port = argv.length > 1 ? int.parse(argv[1]) : 8731;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('serving ${root.path} on $port');
  const types = {
    '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
    '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf',
    '.wasm': 'application/wasm', '.css': 'text/css', '.symbols': 'text/plain',
  };
  await for (final req in server) {
    var path = req.uri.path == '/' ? '/index.html' : req.uri.path;
    final file = File('${root.path}$path');
    if (!file.existsSync()) {
      req.response.statusCode = 404;
      await req.response.close();
      continue;
    }
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    req.response.headers.contentType =
        ContentType.parse(types[ext] ?? 'application/octet-stream');
    await req.response.addStream(file.openRead());
    await req.response.close();
  }
}
