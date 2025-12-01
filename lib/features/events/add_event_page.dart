import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/claudinary_service.dart';
import '../../models/event_model.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  File? imageFile;
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => imageFile = File(file.path));
  }

  Future<void> submitEvent() async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await CloudinaryService().uploadFile(imageFile!);
    }

    final newId = FirestoreService.instance.generateId("events");

    final event = EventModel(
      id: newId,
      title: titleCtrl.text,
      description: descCtrl.text,
      imageUrl: imageUrl ?? '',
      createdAt: DateTime.now(),
      status: 'pending',
      userId: '', // current user
    );

    await FirestoreService.instance.addEvent(event);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Event Title"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : const Center(child: Text("Tap to pick an image")),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: submitEvent, child: const Text("Submit Event")),
            ],
          ),
        ),
      ),
    );
  }
}
