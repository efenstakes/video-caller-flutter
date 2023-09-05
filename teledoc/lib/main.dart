import 'package:flutter/material.dart';
import 'package:meetr/pages/home/page.dart';
import 'package:meetr/services/signal.dart';
import 'package:mock_data/mock_data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});


  // create the users callerId
  var callerId = mockName('female');

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // initialize signalling service
    SignalService.instance.init(callerId: callerId);


    return MaterialApp(
      title: 'TeleDoc',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(callerId: callerId),
    );
  }
}
