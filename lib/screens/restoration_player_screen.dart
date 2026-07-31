import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/timeline_event.dart';

class RestorationPlayerScreen extends StatefulWidget {
  final List<TimelineEvent> images;
  const RestorationPlayerScreen({super.key, required this.images});
  @override
  State<RestorationPlayerScreen> createState() =>
      _RestorationPlayerScreenState();
}

class _RestorationPlayerScreenState extends State<RestorationPlayerScreen> {
  int index = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (widget.images.isNotEmpty) {
        setState(() => index = (index + 1) % widget.images.length);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No hay imágenes para reproducir.')),
      );
    }
    final e = widget.images[index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Evolución del proyecto'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            child: Image.file(File(e.imagePath), fit: BoxFit.contain),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(e.description.isEmpty ? e.category : e.description),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (index + 1) / widget.images.length,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
