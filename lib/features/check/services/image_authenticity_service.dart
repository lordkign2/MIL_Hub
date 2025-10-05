import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// Service for checking image authenticity using reverse image search APIs
class ImageAuthenticityService {
  static final http.Client _httpClient = http.Client();

  // API Configuration - Replace with actual API keys
  static const String _bingApiKey = 'YOUR_BING_VISUAL_SEARCH_API_KEY';
  static const String _tineyyeApiKey = 'YOUR_TINEYE_API_KEY';
  static const String _tineyyePrivateKey = 'YOUR_TINEYE_PRIVATE_KEY';

  // API Endpoints
  static const String _bingVisualSearchUrl =
      'https://api.bing.microsoft.com/v7.0/images/visualsearch';
  static const String _tineyeSearchUrl = 'https://api.tineye.com/rest/search/';

  /// Check image authenticity using multiple reverse search APIs
  static Future<ImageAuthenticityResult> checkImageAuthenticity(
    File imageFile, {
    bool useBing = true,
    bool useTineye = true,
  }) async {
    final List<ImageSearchResult> searchResults = [];
    final List<String> errors = [];

    try {
      // Read image data
      final imageBytes = await imageFile.readAsBytes();
      final imageHash = _calculateImageHash(imageBytes);

      // Bing Visual Search
      if (useBing && _bingApiKey != 'YOUR_BING_VISUAL_SEARCH_API_KEY') {
        try {
          final bingResult = await _searchWithBing(imageBytes);
          searchResults.add(bingResult);
        } catch (e) {
          errors.add('Bing search failed: ${e.toString()}');
        }
      }

      // TinEye Search
      if (useTineye && _tineyyeApiKey != 'YOUR_TINEYE_API_KEY') {
        try {
          final tineyeResult = await _searchWithTineye(imageBytes);
          searchResults.add(tineyeResult);
        } catch (e) {
          errors.add('TinEye search failed: ${e.toString()}');
        }
      }

      // Analyze results
      return _analyzeSearchResults(
        imageHash: imageHash,
        searchResults: searchResults,
        errors: errors,
        originalFilePath: imageFile.path,
      );
    } catch (e) {
      return ImageAuthenticityResult(
        isAuthentic: false,
        confidence: 0.0,
        verdict: '❌ Analysis Failed',
        summary: 'Unable to analyze image: ${e.toString()}',
        searchResults: [],
        warnings: ['Image analysis failed'],
        metadata: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Perform reverse image search using Bing Visual Search API
  static Future<ImageSearchResult> _searchWithBing(Uint8List imageBytes) async {
    try {
      final boundary = 'boundary${DateTime.now().millisecondsSinceEpoch}';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_bingVisualSearchUrl),
      );

      request.headers.addAll({
        'Ocp-Apim-Subscription-Key': _bingApiKey,
        'Content-Type': 'multipart/form-data; boundary=$boundary',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseBingResponse(data);
      } else {
        throw Exception('Bing API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bing search failed: $e');
    }
  }

  /// Perform reverse image search using TinEye API
  static Future<ImageSearchResult> _searchWithTineye(
    Uint8List imageBytes,
  ) async {
    try {
      // TinEye requires HMAC authentication
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final nonce = _generateNonce();

      final requestUrl =
          '${_tineyeSearchUrl}?api_key=$_tineyyeApiKey&timestamp=$timestamp&nonce=$nonce';
      final signature = _generateTineyeSignature(
        requestUrl,
        _tineyyePrivateKey,
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$requestUrl&signature=$signature'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseTineyeResponse(data);
      } else {
        throw Exception('TinEye API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('TinEye search failed: $e');
    }
  }

  /// Parse Bing Visual Search API response
  static ImageSearchResult _parseBingResponse(Map<String, dynamic> data) {
    final tags = data['tags'] as List? ?? [];
    final List<ImageMatch> matches = [];

    for (var tag in tags) {
      final actions = tag['actions'] as List? ?? [];
      for (var action in actions) {
        if (action['actionType'] == 'VisualSearch') {
          final actionData = action['data'] as Map<String, dynamic>? ?? {};
          final value = actionData['value'] as List? ?? [];

          for (var item in value) {
            matches.add(
              ImageMatch(
                sourceUrl: item['webSearchUrl'] ?? '',
                thumbnailUrl: item['thumbnailUrl'] ?? '',
                hostPageUrl: item['hostPageUrl'] ?? '',
                title: item['name'] ?? '',
                description: item['displayUrl'] ?? '',
                confidence: (item['similarity'] as num?)?.toDouble() ?? 0.0,
                dateFound:
                    DateTime.tryParse(item['datePublished'] ?? '') ??
                    DateTime.now(),
                width: item['width'] ?? 0,
                height: item['height'] ?? 0,
              ),
            );
          }
        }
      }
    }

    return ImageSearchResult(
      apiSource: 'Bing Visual Search',
      totalMatches: matches.length,
      matches: matches,
      processingTime: Duration.zero, // Not provided by Bing
      status: 'success',
    );
  }

  /// Parse TinEye API response
  static ImageSearchResult _parseTineyeResponse(Map<String, dynamic> data) {
    final results = data['results'] as Map<String, dynamic>? ?? {};
    final matches = results['matches'] as List? ?? [];

    final List<ImageMatch> imageMatches = matches
        .map(
          (match) => ImageMatch(
            sourceUrl: match['image_url'] ?? '',
            thumbnailUrl: match['image_url'] ?? '',
            hostPageUrl: match['backlinks']?.first?['url'] ?? '',
            title: match['backlinks']?.first?['title'] ?? '',
            description: match['domain'] ?? '',
            confidence: 1.0, // TinEye doesn't provide similarity scores
            dateFound:
                DateTime.tryParse(match['crawl_date'] ?? '') ?? DateTime.now(),
            width: match['width'] ?? 0,
            height: match['height'] ?? 0,
          ),
        )
        .cast<ImageMatch>()
        .toList();

    return ImageSearchResult(
      apiSource: 'TinEye',
      totalMatches: imageMatches.length,
      matches: imageMatches,
      processingTime: Duration(
        milliseconds: (results['query_time'] as num?)?.round() ?? 0,
      ),
      status: 'success',
    );
  }

  /// Analyze search results and determine authenticity
  static ImageAuthenticityResult _analyzeSearchResults({
    required String imageHash,
    required List<ImageSearchResult> searchResults,
    required List<String> errors,
    required String originalFilePath,
  }) {
    int totalMatches = 0;
    DateTime? earliestMatch;
    List<String> suspiciousDomains = [];
    List<String> warnings = [];

    // Aggregate results from all APIs
    for (var result in searchResults) {
      totalMatches += result.totalMatches;

      for (var match in result.matches) {
        if (earliestMatch == null || match.dateFound.isBefore(earliestMatch)) {
          earliestMatch = match.dateFound;
        }

        // Check for suspicious domains (known fake news, clickbait sites)
        final domain = Uri.tryParse(match.hostPageUrl)?.host ?? '';
        if (_isSuspiciousDomain(domain)) {
          suspiciousDomains.add(domain);
        }
      }
    }

    // Determine authenticity based on analysis
    bool isAuthentic = true;
    double confidence = 1.0;
    String verdict;
    String summary;

    if (totalMatches == 0) {
      verdict = '✅ Potentially Original';
      summary =
          'No matches found in reverse image search databases. This could be an original image.';
      confidence =
          0.7; // Lower confidence since absence of evidence isn't evidence of absence
    } else if (totalMatches > 100) {
      isAuthentic = false;
      verdict = '❌ Widely Circulated';
      summary =
          'This image has been found in $totalMatches locations online, suggesting it may be recycled content.';
      confidence = 0.9;
      warnings.add('Image appears in many online sources');
    } else if (suspiciousDomains.isNotEmpty) {
      isAuthentic = false;
      verdict = '⚠️ Found on Questionable Sites';
      summary =
          'Image found on potentially unreliable domains: ${suspiciousDomains.join(', ')}';
      confidence = 0.8;
      warnings.add('Associated with questionable sources');
    } else if (totalMatches > 10) {
      verdict = '⚠️ Multiple Matches Found';
      summary =
          'Found $totalMatches matches. Verify the context and source of this image.';
      confidence = 0.6;
      warnings.add('Image has been used in multiple contexts');
    } else {
      verdict = '✅ Limited Distribution';
      summary =
          'Found $totalMatches matches. This appears to have limited circulation online.';
      confidence = 0.8;
    }

    // Add time-based analysis
    if (earliestMatch != null) {
      final daysSinceFirst = DateTime.now().difference(earliestMatch).inDays;
      if (daysSinceFirst > 365) {
        warnings.add('Earliest match found over a year ago');
      }
      summary += ' Earliest match: ${_formatDate(earliestMatch)}.';
    }

    return ImageAuthenticityResult(
      isAuthentic: isAuthentic,
      confidence: confidence,
      verdict: verdict,
      summary: summary,
      searchResults: searchResults,
      warnings: warnings,
      metadata: {
        'imageHash': imageHash,
        'totalMatches': totalMatches,
        'earliestMatch': earliestMatch?.toIso8601String(),
        'suspiciousDomains': suspiciousDomains,
        'errors': errors,
        'originalFilePath': originalFilePath,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Calculate a simple hash of the image for tracking
  static String _calculateImageHash(Uint8List imageBytes) {
    final digest = sha256.convert(imageBytes);
    return digest.toString();
  }

  /// Generate a random nonce for TinEye authentication
  static String _generateNonce() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  /// Generate HMAC signature for TinEye API
  static String _generateTineyeSignature(String requestUrl, String privateKey) {
    final key = utf8.encode(privateKey);
    final message = utf8.encode(requestUrl);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    return digest.toString();
  }

  /// Check if a domain is known to be suspicious
  static bool _isSuspiciousDomain(String domain) {
    final suspiciousDomains = [
      'clickbait.com',
      'fakenews.com',
      'conspiracy.net',
      // Add more known suspicious domains
    ];

    return suspiciousDomains.any(
      (suspicious) =>
          domain.contains(suspicious) || domain.endsWith(suspicious),
    );
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Result of image authenticity check
class ImageAuthenticityResult {
  final bool isAuthentic;
  final double confidence;
  final String verdict;
  final String summary;
  final List<ImageSearchResult> searchResults;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  ImageAuthenticityResult({
    required this.isAuthentic,
    required this.confidence,
    required this.verdict,
    required this.summary,
    required this.searchResults,
    required this.warnings,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'isAuthentic': isAuthentic,
      'confidence': confidence,
      'verdict': verdict,
      'summary': summary,
      'searchResults': searchResults.map((r) => r.toJson()).toList(),
      'warnings': warnings,
      'metadata': metadata,
    };
  }
}

/// Result from a single reverse image search API
class ImageSearchResult {
  final String apiSource;
  final int totalMatches;
  final List<ImageMatch> matches;
  final Duration processingTime;
  final String status;

  ImageSearchResult({
    required this.apiSource,
    required this.totalMatches,
    required this.matches,
    required this.processingTime,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'apiSource': apiSource,
      'totalMatches': totalMatches,
      'matches': matches.map((m) => m.toJson()).toList(),
      'processingTime': processingTime.inMilliseconds,
      'status': status,
    };
  }
}

/// Individual image match from reverse search
class ImageMatch {
  final String sourceUrl;
  final String thumbnailUrl;
  final String hostPageUrl;
  final String title;
  final String description;
  final double confidence;
  final DateTime dateFound;
  final int width;
  final int height;

  ImageMatch({
    required this.sourceUrl,
    required this.thumbnailUrl,
    required this.hostPageUrl,
    required this.title,
    required this.description,
    required this.confidence,
    required this.dateFound,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceUrl': sourceUrl,
      'thumbnailUrl': thumbnailUrl,
      'hostPageUrl': hostPageUrl,
      'title': title,
      'description': description,
      'confidence': confidence,
      'dateFound': dateFound.toIso8601String(),
      'width': width,
      'height': height,
    };
  }
}
