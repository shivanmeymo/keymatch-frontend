import 'package:flutter/material.dart';
import 'lib/utils/flavor_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 DEBUG: Testing FlavorHelper directly...');
  final flavor = await FlavorHelper.getCurrentFlavor();
  print('🔍 DEBUG: FlavorHelper returned: $flavor');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Flavor Test')),
        body: Center(
          child: FutureBuilder<Flavor>(
            future: FlavorHelper.getCurrentFlavor(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text('Detected flavor: ${snapshot.data}');
              }
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
} 