import 'package:flutter_test/flutter_test.dart';
import 'package:stylesync/modules/quotes_contracts/models/quote.dart';
import 'package:stylesync/modules/quotes_contracts/models/contract.dart';
import 'package:stylesync/modules/quotes_contracts/services/quotes_contracts_service.dart';

void main() {
  group('Quotes & Contracts Flutter Component Tests', () {
    test('Quote and QuoteVersion parsing from JSON', () {
      final json = {
        'id': 'q-test-1',
        'projectRequestId': 'req-1',
        'designerId': 'des-1',
        'scopeSummary': 'Modern Minimalist Living Room',
        'status': 'Stage1Released',
        'totalCost': 150000.0,
        'currentVersion': {
          'id': 'v-1',
          'versionNumber': 1,
          'authorId': 'des-1',
          'authorRole': 'Designer',
          'materialsSubtotal': 90000.0,
          'laborSubtotal': 35000.0,
          'designFee': 12500.0,
          'contingencyAmount': 6875.0,
          'taxAmount': 11550.0,
          'totalCost': 150000.0,
          'createdAt': '2026-10-05T12:00:00Z',
          'items': [
            {
              'id': 'i-1',
              'description': 'Custom TV Unit',
              'category': 'Furniture',
              'quantity': 1,
              'unitCost': 90000.0,
              'lineTotal': 90000.0,
            }
          ]
        },
        'items': [
          {
            'id': 'i-1',
            'description': 'Custom TV Unit',
            'category': 'Furniture',
            'quantity': 1,
            'unitCost': 90000.0,
            'totalCost': 90000.0,
          }
        ]
      };

      final quote = Quote.fromJson(json);

      expect(quote.id, 'q-test-1');
      expect(quote.status, 'Stage1Released');
      expect(quote.totalCost, 150000.0);
      expect(quote.currentVersion, isNotNull);
      expect(quote.currentVersion!.versionNumber, 1);
      expect(quote.currentVersion!.materialsSubtotal, 90000.0);
      expect(quote.currentVersion!.items.length, 1);
    });

    test('Stage 2 Decision in service generates Contract in PendingSignature status', () async {
      final service = QuotesContractsService();
      final quotes = await service.listQuotes();
      expect(quotes, isNotEmpty);

      final quoteId = quotes.first.id;
      final result = await service.stage2Decision(quoteId, 'Approve');

      expect(result, isA<Contract>());
      final contract = result as Contract;
      expect(contract.quoteId, quoteId);
      expect(contract.status, 'PendingSignature');
    });

    test('Contract sign transitions status to Active and stamps SignedAt', () async {
      final service = QuotesContractsService();
      final contracts = await service.listContracts();
      expect(contracts, isNotEmpty);

      final contractId = contracts.first.id;
      final signed = await service.signContract(contractId);

      expect(signed.status, 'Active');
      expect(signed.signedAt, isNotNull);
    });
  });
}
