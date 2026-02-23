import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const VisionQuestApp());
}

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'message': 'Backend erfolgreich verbunden!',
        };
      } else {
        return {
          'success': false,
          'message': 'Backend antwortet mit Status ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Verbindungsfehler: ${e.toString()}',
      };
    }
  }
}

class BackendProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _status;
  bool _isConnected = false;

  bool get isLoading => _isLoading;
  String? get status => _status;
  bool get isConnected => _isConnected;

  Future<void> testConnection() async {
    _isLoading = true;
    _status = 'Teste Backend-Verbindung...';
    notifyListeners();

    final result = await ApiService.testBackendConnection();

    _isLoading = false;
    _isConnected = result['success'];
    _status = result['message'];
    notifyListeners();
  }
}

class VisionQuestApp extends StatelessWidget {
  const VisionQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BackendProvider(),
      child: MaterialApp(
        title: 'VisionQuest',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'VisionQuest - Backend Integration'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Teste Verbindung beim Start
    Future.microtask(() {
      context.read<BackendProvider>().testConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Consumer<BackendProvider>(
        builder: (context, backendProvider, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (backendProvider.isLoading)
                  const CircularProgressIndicator()
                else if (backendProvider.isConnected)
                  Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Backend verbunden!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (backendProvider.status != null)
                        Text(
                          backendProvider.status!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Backend nicht erreichbar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (backendProvider.status != null)
                        Text(
                          backendProvider.status!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<BackendProvider>().testConnection();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Verbindung testen'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
