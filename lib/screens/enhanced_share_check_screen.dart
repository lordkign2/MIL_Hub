import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/share_intent_service.dart';
import '../features/check/services/link_check_service.dart';
import '../constants/global_variables.dart';

class ShareCheckScreen extends StatefulWidget {
  final ShareCheckArguments? arguments;

  const ShareCheckScreen({super.key, this.arguments});

  @override
  State<ShareCheckScreen> createState() => _ShareCheckScreenState();
}

class _ShareCheckScreenState extends State<ShareCheckScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  String? _sharedContent;
  ShareContentType? _contentType;
  List<String> _detectedUrls = [];
  bool _isAnalyzing = false;
  dynamic _analysisResult;
  String? _selectedUrl;

  @override
  void initState() {
    super.initState();

    // Setup animations following UI theme and design memory
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );

    // Process shared content
    _processSharedContent();

    // Start animations
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _processSharedContent() {
    final args =
        widget.arguments ??
        ModalRoute.of(context)?.settings.arguments as ShareCheckArguments?;

    if (args != null) {
      setState(() {
        _sharedContent = args.content;
        _contentType = args.type;
        _detectedUrls = args.allUrls;
        _selectedUrl = args.firstUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalVariables.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '🔍 Share-to-Verify',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GlobalVariables.backgroundColor,
                  Colors.indigo.shade900.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: _sharedContent != null
                  ? _buildAnalysisInterface()
                  : _buildComingSoonInterface(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisInterface() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with content detection
          _buildContentHeader(),

          const SizedBox(height: 24),

          // Content preview
          _buildContentPreview(),

          const SizedBox(height: 24),

          // URL selection (if multiple URLs)
          if (_detectedUrls.length > 1) ...[
            _buildUrlSelection(),
            const SizedBox(height: 24),
          ],

          // Action buttons
          _buildActionButtons(),

          const SizedBox(height: 24),

          // Analysis results
          if (_analysisResult != null) _buildAnalysisResults(),

          // Loading indicator
          if (_isAnalyzing) _buildLoadingIndicator(),

          const Spacer(),

          // Security tips
          _buildSecurityTips(),
        ],
      ),
    );
  }

  Widget _buildComingSoonInterface() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coming soon header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.withOpacity(0.2),
                  Colors.purple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.indigo.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share-to-Verify Available!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share suspicious content from any app for instant analysis',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          _buildInstructions(),

          const Spacer(),

          // Action button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
            icon: const Icon(Icons.home),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.2),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.purple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.security, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _detectedUrls.isNotEmpty
                ? 'Shared Link Detected'
                : 'Shared Content Received',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _detectedUrls.isNotEmpty
                ? 'We found ${_detectedUrls.length} link${_detectedUrls.length > 1 ? 's' : ''} in the shared content'
                : 'Let\'s analyze this content for safety',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _contentType == ShareContentType.url
                    ? Icons.link
                    : _contentType == ShareContentType.file
                    ? Icons.file_present
                    : Icons.text_fields,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Shared Content Preview',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _sharedContent != null && _sharedContent!.length > 300
                  ? '${_sharedContent!.substring(0, 300)}...'
                  : _sharedContent ?? 'No content',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Multiple Links Detected',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Select which link to check:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ...(_detectedUrls.map(
            (url) => RadioListTile<String>(
              value: url,
              groupValue: _selectedUrl,
              onChanged: (value) => setState(() => _selectedUrl = value),
              title: Text(
                url.length > 50 ? '${url.substring(0, 50)}...' : url,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              activeColor: Colors.orange,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Copy button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isAnalyzing ? null : _copyContent,
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.grey[600]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Check link button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed:
                _isAnalyzing ||
                    (_detectedUrls.isEmpty && _sharedContent == null)
                ? null
                : _checkContent,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.security),
            label: Text(_isAnalyzing ? 'Checking...' : 'Check Safety'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _analysisResult.isOverallSafe
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _analysisResult.isOverallSafe
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _analysisResult.isOverallSafe
                    ? Icons.check_circle
                    : Icons.warning,
                color: _analysisResult.isOverallSafe
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text(
                'Analysis Results',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analysisResult.verdict,
            style: TextStyle(
              color: _analysisResult.isOverallSafe
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...(_analysisResult.recommendations.map<Widget>(
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
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 16),
          Text(
            'Analyzing shared content...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Security Tips',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Always verify links before clicking them\n'
            '• Be cautious of shortened URLs\n'
            '• Check the sender before trusting shared content',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'How to Use Share-to-Verify',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '1. In any app (TikTok, WhatsApp, etc.), find suspicious content\n'
            '2. Tap the Share button\n'
            '3. Select "MIL Hub" from the share menu\n'
            '4. Get instant security analysis\n\n'
            'For now, you can also:\n'
            '• Copy suspicious links\n'
            '• Open MIL Hub\n'
            '• Get automatic clipboard alerts\n'
            '• Use the Check tab for manual verification',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _copyContent() {
    final contentToCopy = _selectedUrl ?? _sharedContent ?? '';
    if (contentToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: contentToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _checkContent() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      HapticFeedback.mediumImpact();

      String contentToCheck;
      if (_detectedUrls.isNotEmpty) {
        contentToCheck = _selectedUrl ?? _detectedUrls.first;
      } else {
        contentToCheck = _sharedContent ?? '';
      }

      if (contentToCheck.isEmpty) {
        throw Exception('No content to analyze');
      }

      // Analyze the content using existing LinkCheckService
      final assessment = await LinkCheckService.analyzeLink(contentToCheck);

      // Save to Firestore for community transparency
      await LinkCheckService.saveLinkCheck(assessment);

      if (mounted) {
        setState(() {
          _analysisResult = assessment;
          _isAnalyzing = false;
        });

        // Provide haptic feedback based on result
        if (assessment.isOverallSafe) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
