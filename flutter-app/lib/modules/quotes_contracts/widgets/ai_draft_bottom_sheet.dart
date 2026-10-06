import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/quotes_contracts_service.dart';
import '../theme/qc_theme.dart';

class AiDraftBottomSheet extends StatefulWidget {
  final Function(Quote newQuote) onDraftCreated;

  const AiDraftBottomSheet({super.key, required this.onDraftCreated});

  static void show(BuildContext context, {required Function(Quote) onDraftCreated}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QcTheme.surface,
      builder: (_) => AiDraftBottomSheet(onDraftCreated: onDraftCreated),
    );
  }

  @override
  State<AiDraftBottomSheet> createState() => _AiDraftBottomSheetState();
}

class _AiDraftBottomSheetState extends State<AiDraftBottomSheet> {
  final _service = QuotesContractsService();
  bool _isLoading = false;

  void _generateDraft() async {
    setState(() => _isLoading = true);
    try {
      final payload = AiDraftPayload(
        projectRequestId: 'req-1',
        designerId: 'des-1',
        roomType: 'Kitchen',
        roomSizeSqft: 200,
        budgetMin: 5000,
        budgetMax: 10000,
        styleProfile: 'Modern',
        naturalLanguageScope: 'Modern kitchen remodel',
      );
      final quote = await _service.draftQuoteFromAgent(payload);
      if (mounted) {
        Navigator.pop(context);
        widget.onDraftCreated(quote);
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Generate AI Draft Quote', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: QcTheme.textMain)),
            const SizedBox(height: 16),
            _isLoading 
              ? const CircularProgressIndicator(color: QcTheme.primary) 
              : ElevatedButton(
                  onPressed: _generateDraft,
                  style: ElevatedButton.styleFrom(backgroundColor: QcTheme.primary),
                  child: const Text('Generate', style: TextStyle(color: Colors.white)),
                ),
          ],
        ),
      ),
    );
  }
}
