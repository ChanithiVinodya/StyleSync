import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/quotes_contracts_service.dart';
import '../theme/qc_theme.dart';

class QuoteFormBottomSheet extends StatefulWidget {
  final Quote? initialQuote;
  final Function(Quote savedQuote) onQuoteSaved;

  const QuoteFormBottomSheet({
    super.key,
    this.initialQuote,
    required this.onQuoteSaved,
  });

  static void show(
    BuildContext context, {
    Quote? initialQuote,
    required Function(Quote) onQuoteSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QcTheme.surface,
      builder: (_) => QuoteFormBottomSheet(
        initialQuote: initialQuote,
        onQuoteSaved: onQuoteSaved,
      ),
    );
  }

  @override
  State<QuoteFormBottomSheet> createState() => _QuoteFormBottomSheetState();
}

class _QuoteFormBottomSheetState extends State<QuoteFormBottomSheet> {
  final _service = QuotesContractsService();
  bool _isLoading = false;
  late TextEditingController _summaryController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.initialQuote?.scopeSummary ?? '');
    _notesController = TextEditingController(text: widget.initialQuote?.notes ?? '');
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveQuote() async {
    if (_summaryController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final payload = QuoteFormPayload(
        projectRequestId: widget.initialQuote?.projectRequestId ?? 'req-1',
        designerId: widget.initialQuote?.designerId ?? 'des-1',
        scopeSummary: _summaryController.text.trim(),
        notes: _notesController.text.trim(),
        isAiGenerated: widget.initialQuote?.isAiGenerated ?? false,
        items: widget.initialQuote?.items ?? [],
      );

      Quote saved;
      if (widget.initialQuote == null) {
        saved = await _service.createQuote(payload);
      } else {
        saved = await _service.updateQuote(widget.initialQuote!.id, payload);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onQuoteSaved(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialQuote != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edit Quote' : 'Create Quote', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: QcTheme.textMain)),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryController,
              style: const TextStyle(color: QcTheme.textMain),
              decoration: const InputDecoration(
                labelText: 'Scope Summary',
                labelStyle: TextStyle(color: QcTheme.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: QcTheme.border)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: QcTheme.textMain),
              decoration: const InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: QcTheme.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: QcTheme.border)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: QcTheme.primary)) 
                : ElevatedButton(
                    onPressed: _saveQuote,
                    style: ElevatedButton.styleFrom(backgroundColor: QcTheme.primary),
                    child: Text(isEditing ? 'Save Changes' : 'Create Quote', style: const TextStyle(color: Colors.white)),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
