import 'package:flutter/material.dart';


class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.title});
  final String title;
  @override
  State<AlertsPage> createState() => _AlertsState();
}

class _AlertsState extends State<AlertsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('ALERRTS'),
            ElevatedButton(
              child: Text('+'),
              onPressed: () => Navigator.pushNamed(context, '/alerts/modify'),
            ),
          ],
        ),
      )
    );
  }
}