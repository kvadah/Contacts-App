import 'package:flutter/material.dart';

class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
        backgroundColor: const Color.fromARGB(255, 209, 127, 3),
      ),
      body: const Center(
        child: Text("Contacts List"),
      ),
    );
  }
}