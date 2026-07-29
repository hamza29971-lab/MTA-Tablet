// lib/ui/widgets/update_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final int remoteBuildNumber;
  const UpdateDialog({super.key, required this.remoteBuildNumber});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Indiriliyor...';
    });

    try {
      final file = await UpdateService.downloadApk(
        widget.remoteBuildNumber,
        (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText =
                  'Indiriliyor... %${(progress * 100).toStringAsFixed(0)}';
            });
          }
        },
      );

      if (mounted) {
        setState(() => _statusText = 'Kurulum baslatiliyor...');
        final result = await OpenFile.open(
          file.path,
          type: 'application/vnd.android.package-archive',
        );
        
        if (mounted) {
          if (result.type == ResultType.done) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _isDownloading = false;
              _statusText = 'Kurulum hatasi: ${result.message}';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Hata: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFF046464), size: 28),
          SizedBox(width: 12),
          Text(
            'Yeni Guncelleme Mevcut',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni surum mevcut (Build ${widget.remoteBuildNumber}).\nGuncellemek ister misiniz?',
              style: const TextStyle(fontSize: 16),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF046464),
                minHeight: 8,
              ),
            ],
            if (_statusText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _statusText.toLowerCase().contains('hata')
                      ? Colors.red
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _isDownloading
          ? null
          : [
              TextButton(
                onPressed: () {
                  UpdateService.ignoreBuild(widget.remoteBuildNumber);
                  Navigator.of(context).pop();
                },
                child: const Text('Simdi Degil',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Guncelle',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046464),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
    );
  }
}
