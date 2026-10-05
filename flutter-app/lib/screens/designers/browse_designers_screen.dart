import 'package:flutter/material.dart';
import '../../modules/designers/models/designer_summary.dart';
import '../../modules/designers/screens/designer_listing_screen.dart';

class BrowseDesignersScreen extends StatelessWidget {
  final String? initialStyle;
  final DesignerQueryParameters? initialParams;

  const BrowseDesignersScreen({
    super.key,
    this.initialStyle,
    this.initialParams,
  });

  @override
  Widget build(BuildContext context) {
    return DesignerListingScreen(
      initialStyle: initialStyle,
      initialParams: initialParams,
    );
  }
}

