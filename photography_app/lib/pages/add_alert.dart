import 'package:flutter/material.dart';


class AddAlertPage extends StatefulWidget {
  const AddAlertPage({super.key, required this.title});
  final String title;
  @override
  State<AddAlertPage> createState() => _AddAlertState();
}

class _AddAlertState extends State<AddAlertPage> {

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
            const Text('WOAH ADD AN ALERT???'),
          ],
        ),
      ),
    );
  }
}