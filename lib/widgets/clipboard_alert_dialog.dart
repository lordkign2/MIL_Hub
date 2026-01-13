import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/clipboard_monitor_service.dart';
import '../features/check/services/link_check_service.dart';

class ClipboardAlertDialog extends StatefulWidget {
  final ClipboardCheckResult checkResult;

  const ClipboardAlertDialog({super.key, required this.checkResult});

  @override
  State<ClipboardAlertDialog> createState() => _ClipboardAlertDialogState();
}

class _ClipboardAlertDialogState extends State<ClipboardAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                widget.checkResult.isSuspicious
                    ? Icons.warning_rounded
                    : Icons.info_outline_rounded,
                color: widget.checkResult.isSuspicious
                    ? Colors.orangeAccent
                    : Colors.blueAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.checkResult.isSuspicious
                      ? '⚠️ Suspicious Content'
                      : '📋 Clipboard Content',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.checkResult.isSuspicious
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.checkResult.isSuspicious
                        ? Colors.orangeAccent.withValues(alpha: 0.3)
                        : Colors.blueAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.checkResult.warningMessage,
                  style: TextStyle(
                    color: widget.checkResult.isSuspicious
                        ? Colors.orangeAccent
                        : Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content preview
              const Text(
                'Content Preview:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!, width: 1),
                ),
                child: Text(
                  widget.checkResult.content.length > 200
                      ? '${widget.checkResult.content.substring(0, 200)}...'
                      : widget.checkResult.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recommendation
              Text(
                widget.checkResult.recommendationMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),

              if (_isAnalyzing) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Analyzing link...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            // Dismiss button
            TextButton(
              onPressed: _isAnalyzing
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            // Copy button (if URL)
            if (widget.checkResult.isUrl)
              TextButton(
                onPressed: _isAnalyzing
                    ? null
                    : () {
                        Clipboard.setData(
                          ClipboardData(text: widget.checkResult.content),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                child: const Text(
                  'Copy',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

            // Check link button (if URL)
            if (widget.checkResult.isUrl)
              ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isAnalyzing ? 'Checking...' : 'Check Link'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeLink() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Analyze the link
      final assessment = await LinkCheckService.analyzeLink(
        widget.checkResult.content,
      );

      // Save to Firestore
      await LinkCheckService.saveLinkCheck(assessment);

      if (mounted) {
        // Close the dialog
        Navigator.of(context).pop();

        // Show results in a new dialog
        _showAnalysisResults(assessment);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAnalysisResults(dynamic assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              assessment.isOverallSafe ? Icons.check_circle : Icons.warning,
              color: assessment.isOverallSafe ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text(
              'Analysis Results',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assessment.verdict,
              style: TextStyle(
                color: assessment.isOverallSafe ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...assessment.recommendations.map<Widget>(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
