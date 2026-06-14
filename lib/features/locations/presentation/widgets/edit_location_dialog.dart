import 'package:flutter/material.dart';

/// Dialog for editing a location's label and notes
class EditLocationDialog extends StatefulWidget {
  final String currentLabel;
  final String currentNotes;
  final String cityName;
  final Function(String? label, String? notes) onSubmit;

  const EditLocationDialog({
    super.key,
    required this.currentLabel,
    required this.currentNotes,
    required this.cityName,
    required this.onSubmit,
  });

  @override
  State<EditLocationDialog> createState() => _EditLocationDialogState();
}

class _EditLocationDialogState extends State<EditLocationDialog> {
  late TextEditingController _labelController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.currentLabel);
    _notesController = TextEditingController(text: widget.currentNotes);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(
      _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.cityName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label',
              hintText: 'contoh: Kampus, Kos, Rumah',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Catatan',
              hintText: 'contoh: Dekat jalan raya',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
