import 'package:flutter/material.dart';

class SupplierCreen extends StatefulWidget {
  const SupplierCreen({super.key});

  @override
  State<SupplierCreen> createState() => _SupplierCreenState();
}

class _SupplierCreenState extends State<SupplierCreen> {



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Screen'),
      ),
      body: const Center(
        child: Text('This is the Supplier Screen'),
      ),
    );
  }
}
