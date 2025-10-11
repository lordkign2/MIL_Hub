import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/link_check_model.dart';
import '../../domain/entities/link_check_entity.dart';

abstract class LinkCheckRemoteDataSource {
  /// Performs comprehensive link analysis
  Future<LinkAssessmentModel> analyzeLink(String url);

  /// Save link check to Firestore
  Future<void> saveLinkCheck(LinkAssessmentModel assessment);

  /// Get recent link checks from the community
  Stream<List<LinkCheckModel>> getRecentLinkChecks({int limit = 20});

  /// Get user's link check history
  Stream<List<LinkCheckModel>> getUserLinkChecks({int limit = 50});

  /// Search for previously checked URLs
  Future<LinkCheckModel?> findPreviousCheck(String url);
}

class LinkCheckRemoteDataSourceImpl implements LinkCheckRemoteDataSource {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final http.Client _httpClient = http.Client();

  // Collection reference
  static final CollectionReference _linkChecksCollection = _firestore
      .collection('linkChecks');

  // Google Fact Check Tools API configuration
  static const String _factCheckApiKey =
      'YOUR_GOOGLE_API_KEY'; // TODO: Add to environment
  static const String _factCheckApiUrl =
      'https://factchecktools.googleapis.com/v1alpha1/claims:search';

  // News credibility sources
  static const List<String> _trustedNewsSources = [
    'reuters.com',
    'ap.org',
    'apnews.com',
    'bbc.com',
    'npr.org',
    'pbs.org',
    'cnn.com',
    'nytimes.com',
    'washingtonpost.com',
    'wsj.com',
    'theguardian.com',
    'abcnews.go.com',
    'cbsnews.com',
    'nbcnews.com',
  ];

  static const List<String> _questionableNewsSources = [
    'infowars.com',
    'breitbart.com',
    'naturalnews.com',
    'beforeitsnews.com',
    'zerohedge.com',
    'dailymail.co.uk',
    'rt.com',
  ];

  // Suspicious keywords to check for
  static const List<String> _suspiciousKeywords = [
    'free',
    'giveaway',
    'prize',
    'urgent',
    'limited time',
    'act now',
    'click here',
    'winner',
    'congratulations',
    'claim now',
    'exclusive',
    'offer expires',
    'shocking',
    'unbelievable',
    'miracle',
    'guaranteed',
    'risk-free',
    'no credit check',
    'easy money',
    'work from home',
    'get rich quick',
    'lose weight fast',
    'secret revealed',
    'doctors hate this',
    'one weird trick',
  ];

  @override
  Future<LinkAssessmentModel> analyzeLink(String url) async {
    final List<CheckResultModel> results = [];

    try {
      // Clean and validate URL
      final cleanUrl = _cleanUrl(url);

      // 1. Protocol Check (HTTPS vs HTTP)
      results.add(_checkProtocol(cleanUrl));

      // 2. Suspicious Keywords Check
      results.add(await _checkSuspiciousKeywords(cleanUrl));

      // 3. Reachability Check
      results.add(await _checkReachability(cleanUrl));

      // 4. Fact Check API
      results.add(await _checkFactCheck(cleanUrl));

      // 5. News Source Credibility
      results.add(_checkNewsCredibility(cleanUrl));

      // Generate overall assessment
      return _generateAssessment(cleanUrl, results);
    } catch (e) {
      // Return error assessment
      return LinkAssessmentModel(
        url: url,
        results: [
          CheckResultModel(
            type: CheckType.protocol,
            passed: false,
            message: 'Analysis failed: ${e.toString()}',
          ),
        ],
        isOverallSafe: false,
        verdict: '❌ Analysis Failed',
        confidence: 0.0,
        recommendations: ['Please check the URL format and try again'],
      );
    }
  }

  @override
  Future<void> saveLinkCheck(LinkAssessmentModel assessment) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final linkCheck = LinkCheckModel(
        id: '',
        url: assessment.url,
        originalUrl: assessment.url,
        isSafe: assessment.isOverallSafe,
        isReachable: assessment.results
            .where((r) => r.type == CheckType.reachability)
            .first
            .passed,
        verdict: assessment.verdict,
        suspiciousKeywords:
            assessment.results
                .where((r) => r.type == CheckType.keywords)
                .first
                .data?['foundKeywords']
                ?.cast<String>() ??
            [],
        warnings: assessment.recommendations,
        metadata: {
          'confidence': assessment.confidence,
          'checkResults': (assessment.results as List<CheckResultModel>)
              .map((r) => r.toJson())
              .toList(),
          'timestamp': DateTime.now().toIso8601String(),
        },
        checkedBy: user.uid,
        createdAt: DateTime.now(),
      );

      await _linkChecksCollection.add(linkCheck.toFirestore());
    } catch (e) {
      throw Exception('Failed to save link check: $e');
    }
  }

  @override
  Stream<List<LinkCheckModel>> getRecentLinkChecks({int limit = 20}) {
    return _linkChecksCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LinkCheckModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<LinkCheckModel>> getUserLinkChecks({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _linkChecksCollection
        .where('checkedBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LinkCheckModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<LinkCheckModel?> findPreviousCheck(String url) async {
    final cleanUrl = _cleanUrl(url);

    try {
      final snapshot = await _linkChecksCollection
          .where('url', isEqualTo: cleanUrl)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LinkCheckModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Private helper methods

  static String _cleanUrl(String url) {
    // Remove extra whitespace
    url = url.trim();

    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    return url;
  }

  static CheckResultModel _checkProtocol(String url) {
    final isHttps = url.startsWith('https://');

    return CheckResultModel(
      type: CheckType.protocol,
      passed: isHttps,
      message: isHttps
          ? '✅ Secure HTTPS connection'
          : '⚠️ Insecure HTTP connection',
      details: isHttps
          ? 'This link uses encrypted HTTPS protocol, which is safer for data transmission.'
          : 'This link uses unencrypted HTTP protocol. Be cautious with personal information.',
    );
  }

  static Future<CheckResultModel> _checkSuspiciousKeywords(String url) async {
    try {
      // Check URL itself
      final foundKeywords = <String>[];
      final lowerUrl = url.toLowerCase();

      for (final keyword in _suspiciousKeywords) {
        if (lowerUrl.contains(keyword.toLowerCase())) {
          foundKeywords.add(keyword);
        }
      }

      final passed = foundKeywords.isEmpty;

      return CheckResultModel(
        type: CheckType.keywords,
        passed: passed,
        message: passed
            ? '✅ No suspicious keywords detected'
            : '⚠️ Suspicious keywords found: ${foundKeywords.join(', ')}',
        details: passed
            ? 'The URL doesn\'t contain commonly used suspicious keywords.'
            : 'Found keywords often associated with scams or misleading content.',
        data: {
          'foundKeywords': foundKeywords,
          'totalChecked': _suspiciousKeywords.length,
        },
      );
    } catch (e) {
      return CheckResultModel(
        type: CheckType.keywords,
        passed: true,
        message: '⚠️ Keyword check failed',
        details: 'Unable to perform keyword analysis: ${e.toString()}',
      );
    }
  }

  static Future<CheckResultModel> _checkReachability(String url) async {
    try {
      final response = await http
          .head(
            Uri.parse(url),
            headers: {'User-Agent': 'MIL-Hub-LinkChecker/1.0'},
          )
          .timeout(const Duration(seconds: 10));

      final passed = response.statusCode >= 200 && response.statusCode < 400;

      return CheckResultModel(
        type: CheckType.reachability,
        passed: passed,
        message: passed
            ? '✅ Link is reachable (${response.statusCode})'
            : '❌ Link is not reachable (${response.statusCode})',
        details: passed
            ? 'The website responded successfully to our request.'
            : 'The website is currently unavailable or returned an error.',
        data: {'statusCode': response.statusCode, 'headers': response.headers},
      );
    } on SocketException {
      return CheckResultModel(
        type: CheckType.reachability,
        passed: false,
        message: '❌ No internet connection or DNS resolution failed',
        details:
            'Unable to connect to the website. Check your internet connection.',
      );
    } on HttpException {
      return CheckResultModel(
        type: CheckType.reachability,
        passed: false,
        message: '❌ HTTP error occurred',
        details: 'The website returned an HTTP error.',
      );
    } catch (e) {
      return CheckResultModel(
        type: CheckType.reachability,
        passed: false,
        message: '❌ Connection failed',
        details: 'Unable to reach the website: ${e.toString()}',
      );
    }
  }

  static LinkAssessmentModel _generateAssessment(
    String url,
    List<CheckResultModel> results,
  ) {
    // Calculate overall safety based on results
    final passedChecks = results.where((r) => r.passed).length;
    final totalChecks = results.length;
    final confidence = totalChecks > 0 ? (passedChecks / totalChecks) : 0.0;

    // Determine if overall safe
    final isOverallSafe = passedChecks >= (totalChecks * 0.7); // 70% threshold

    // Generate verdict
    String verdict;
    if (confidence >= 0.8) {
      verdict = '✅ Safe';
    } else if (confidence >= 0.5) {
      verdict = '⚠️ Suspicious';
    } else {
      verdict = '❌ Unsafe';
    }

    // Generate recommendations
    final recommendations = <String>[];
    for (final result in results) {
      if (!result.passed && result.details != null) {
        recommendations.add(result.details!);
      }
    }

    if (recommendations.isEmpty && isOverallSafe) {
      recommendations.add(
        'This link appears to be safe based on our analysis.',
      );
    }

    return LinkAssessmentModel(
      url: url,
      results: results.map((r) => r.toEntity()).toList(),
      isOverallSafe: isOverallSafe,
      verdict: verdict,
      confidence: confidence,
      recommendations: recommendations,
    );
  }

  /// Check against Google Fact Check Tools API
  static Future<CheckResultModel> _checkFactCheck(String url) async {
    try {
      // Extract domain and query for fact checks
      final uri = Uri.parse(url);
      final domain = uri.host;

      // Only proceed if we have a valid API key
      if (_factCheckApiKey == 'YOUR_GOOGLE_API_KEY') {
        return CheckResultModel(
          type: CheckType.factCheck,
          passed: true,
          message: '⚠️ Fact check API not configured',
          details:
              'Configure Google Fact Check Tools API key to enable fact checking.',
        );
      }

      final queryUrl = Uri.parse(_factCheckApiUrl).replace(
        queryParameters: {
          'key': _factCheckApiKey,
          'query': domain,
          'languageCode': 'en',
        },
      );

      final response = await _httpClient
          .get(queryUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final claims = data['claims'] as List? ?? [];

        if (claims.isNotEmpty) {
          final factCheckData = _analyzeFactCheckClaims(claims);
          return CheckResultModel(
            type: CheckType.factCheck,
            passed: factCheckData['passed'] as bool,
            message: factCheckData['message'] as String,
            details: factCheckData['details'] as String,
            data: factCheckData,
          );
        } else {
          return CheckResultModel(
            type: CheckType.factCheck,
            passed: true,
            message: '✅ No fact check flags found',
            details:
                'No disputed claims found for this domain in fact-checking databases.',
          );
        }
      } else {
        return CheckResultModel(
          type: CheckType.factCheck,
          passed: true,
          message: '⚠️ Fact check service unavailable',
          details: 'Unable to connect to fact-checking service.',
        );
      }
    } catch (e) {
      return CheckResultModel(
        type: CheckType.factCheck,
        passed: true,
        message: '⚠️ Fact check failed',
        details:
            'Error checking against fact-checking databases: ${e.toString()}',
      );
    }
  }

  /// Analyze fact check claims and determine credibility
  static Map<String, dynamic> _analyzeFactCheckClaims(List claims) {
    int totalClaims = claims.length;
    int falseClaims = 0;
    int mixedClaims = 0;
    List<String> ratings = [];

    for (var claim in claims) {
      final claimReviews = claim['claimReview'] as List? ?? [];
      for (var review in claimReviews) {
        final rating = (review['textualRating'] as String? ?? '').toLowerCase();
        ratings.add(rating);

        if (rating.contains('false') ||
            rating.contains('pants on fire') ||
            rating.contains('mostly false')) {
          falseClaims++;
        } else if (rating.contains('mixed') ||
            rating.contains('half true') ||
            rating.contains('mostly true')) {
          mixedClaims++;
        }
      }
    }

    double falseRatio = totalClaims > 0 ? falseClaims / totalClaims : 0.0;
    bool passed = falseRatio < 0.3; // Fail if more than 30% false claims

    String message;
    String details;

    if (falseRatio >= 0.5) {
      message = '❌ High false claim rate detected';
      details =
          'This domain has a significant number of fact-checked false claims ($falseClaims/$totalClaims).';
    } else if (falseRatio >= 0.3) {
      message = '⚠️ Some disputed claims found';
      details =
          'This domain has some fact-checked disputed claims ($falseClaims/$totalClaims). Verify information carefully.';
    } else {
      message = '✅ Low disputed claim rate';
      details =
          'This domain has relatively few disputed claims in fact-checking databases.';
    }

    return {
      'passed': passed,
      'message': message,
      'details': details,
      'totalClaims': totalClaims,
      'falseClaims': falseClaims,
      'mixedClaims': mixedClaims,
      'ratings': ratings,
      'falseRatio': falseRatio,
    };
  }

  /// Check news source credibility
  static CheckResultModel _checkNewsCredibility(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // Remove 'www.' prefix for comparison
      final cleanDomain = domain.startsWith('www.')
          ? domain.substring(4)
          : domain;

      bool isTrusted = _trustedNewsSources.any(
        (source) => cleanDomain == source || cleanDomain.endsWith('.$source'),
      );

      bool isQuestionable = _questionableNewsSources.any(
        (source) => cleanDomain == source || cleanDomain.endsWith('.$source'),
      );

      if (isTrusted) {
        return CheckResultModel(
          type: CheckType.newsCredibility,
          passed: true,
          message: '✅ Trusted news source',
          details:
              'This domain is recognized as a reliable news source with strong editorial standards.',
          data: {'credibilityLevel': 'trusted', 'domain': cleanDomain},
        );
      } else if (isQuestionable) {
        return CheckResultModel(
          type: CheckType.newsCredibility,
          passed: false,
          message: '❌ Questionable news source',
          details:
              'This domain has been identified as having questionable editorial practices or bias.',
          data: {'credibilityLevel': 'questionable', 'domain': cleanDomain},
        );
      } else {
        return CheckResultModel(
          type: CheckType.newsCredibility,
          passed: true,
          message: '⚠️ Unknown news source',
          details:
              'This domain is not in our database of known news sources. Verify information independently.',
          data: {'credibilityLevel': 'unknown', 'domain': cleanDomain},
        );
      }
    } catch (e) {
      return CheckResultModel(
        type: CheckType.newsCredibility,
        passed: true,
        message: '⚠️ Credibility check failed',
        details: 'Unable to analyze news source credibility: ${e.toString()}',
      );
    }
  }

  // Helper method to convert CheckResultModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    // This is a placeholder - actual implementation would be in CheckResultModel
    return {};
  }
}
