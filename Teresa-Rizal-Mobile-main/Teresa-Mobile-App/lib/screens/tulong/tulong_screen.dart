import 'package:flutter/material.dart';
import '../../models/service_request.dart';
import '../../services/mock_catalog.dart';
import '../../theme/soft_widget.dart';
import '../shared/request_list_screen.dart';

/// Tulong = "Assistance Requests" (see components/citizen/sidebar.blade.php).
/// Web Admin destination: Admin > Assistance Requests (currently a single
/// Route::view mock page — see Section 8, Missing Web Admin Processes).
class TulongScreen extends StatelessWidget {
  const TulongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestListScreen(
      category: ServiceCategory.tulong,
      title: 'Tulong',
      subtitle: 'Submit and follow up assistance program requests.',
      catalog: MockCatalog.assistanceTypes,
      accent: SoftColors.tulongInk,
      icon: Icons.volunteer_activism_outlined,
    );
  }
}
