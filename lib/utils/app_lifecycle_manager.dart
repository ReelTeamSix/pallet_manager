import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pallet_model.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force a complete UI refresh and data reload when app is resumed
      if (mounted) {
        // Force reload data from storage
        final model = Provider.of<PalletModel>(context, listen: false);
        model.forceDataReload().then((_) {
          // After data is reloaded, force a complete UI rebuild
          if (mounted) {
            // Schedule a rebuild for the next frame to ensure the UI is fully refreshed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                // This empty setState will force a complete rebuild
              });
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
