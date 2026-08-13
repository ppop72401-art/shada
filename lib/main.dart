import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(const CardGamesHubApp());

class CardGamesHubApp extends StatelessWidget {
  const CardGamesHubApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: ServerScreen());
  }
}

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});
  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  String status = "تهيئة خادم الألعاب...";
  List<WebSocket> clients = [];

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    List<String> ips = [];
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) ips.add(addr.address);
      }
    }
    
    setState(() {
      status = "الخادم جاهز!\n\nرابط اللاعبين (عبر الهوت سبوت):\nhttp://${ips.isNotEmpty ? ips.first : 'localhost'}:8080\n\nرابط جهازك (للعب):\nhttp://127.0.0.1:8080";
    });

    String htmlContent = await rootBundle.loadString('assets/index.html');
    HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    
    server.listen((HttpRequest request) {
      if (request.uri.path == '/ws') {
        WebSocketTransformer.upgrade(request).then((WebSocket ws) {
          clients.add(ws);
          ws.listen((data) {
            for (var client in clients) {
              if (client.readyState == WebSocket.open) {
                client.add(data);
              }
            }
          }, onDone: () => clients.remove(ws));
        });
      } else {
        request.response
          ..headers.contentType = ContentType.html
          ..write(htmlContent)
          ..close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style, size: 80, color: Color(0xFFFFFFFF)),
              const SizedBox(height: 20),
              SelectableText(
                status, 
                textAlign: TextAlign.center, 
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, height: 1.5)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
