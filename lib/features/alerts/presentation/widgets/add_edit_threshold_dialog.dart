import 'package:flutter/material.dart';

class AddEditThresholdDialog extends StatefulWidget {
  final String? city;
  final int? initialAqi;
  final String? initialLabel;
  final Function(String city, int aqi, String? label) onSubmit;

  const AddEditThresholdDialog({
    super.key,
    this.city,
    this.initialAqi,
    this.initialLabel,
    required this.onSubmit,
  });

  @override
  State<AddEditThresholdDialog> createState() => _AddEditThresholdDialogState();
}

class _AddEditThresholdDialogState extends State<AddEditThresholdDialog> {
  late TextEditingController _cityController;
  late TextEditingController _aqiController;
  late TextEditingController _labelController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.city ?? '');
    _aqiController =
        TextEditingController(text: widget.initialAqi?.toString() ?? '');
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _cityController.dispose();
    _aqiController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_cityController.text.isEmpty || _aqiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang wajib')),
      );
      return;
    }

    final aqi = int.tryParse(_aqiController.text);
    if (aqi == null || aqi < 0 || aqi > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AQI harus antara 0-500')),
      );
      return;
    }

    setState(() => _isLoading = true);

    widget.onSubmit(
      _cityController.text.trim(),
      aqi,
      _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.city == null ? 'Tambah Threshold' : 'Edit Threshold'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _cityController,
              enabled: widget.city == null,
              decoration: InputDecoration(
                labelText: 'Nama Kota *',
                hintText: 'contoh: Surabaya',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aqiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Batas AQI *',
                hintText: '0-500',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Label (Opsional)',
                hintText: 'contoh: Kampus, Kos, Rumah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'Tip: Atur batas AQI sesuai kebutuhan Anda. Aplikasi akan mengirim notifikasi jika AQI melampaui batas ini.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
