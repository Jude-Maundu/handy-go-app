import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';

class FindingFundiDialog extends StatefulWidget {
  const FindingFundiDialog({Key? key}) : super(key: key);

  @override
  State<FindingFundiDialog> createState() => _FindingFundiDialogState();
}

class _FindingFundiDialogState extends State<FindingFundiDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return LiquidCircularProgressIndicator(
                    value: _animationController.value,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.green),
                    borderColor: Colors.green,
                    borderWidth: 2,
                    center: Text(
                      "${(_animationController.value * 100).toInt()}%",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Finding nearby fundis...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "This usually takes 10-15 seconds",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
              child: Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
