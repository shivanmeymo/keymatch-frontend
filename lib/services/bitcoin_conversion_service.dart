import 'dart:convert';
import 'package:http/http.dart' as http;

class BitcoinConversionService {
  static const String _apiUrl = 'https://api.coingecko.com/api/v3/simple/price';
  static double? _cachedRate;
  static DateTime? _lastUpdate;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get current Bitcoin price in USD
  static Future<double> getBitcoinPrice() async {
    // Check if we have a recent cached rate
    if (_cachedRate != null && _lastUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastUpdate!);
      if (timeSinceUpdate < _cacheDuration) {
        return _cachedRate!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?ids=bitcoin&vs_currencies=usd'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final priceRaw = data['bitcoin']['usd'];
        final price = priceRaw is int ? priceRaw.toDouble() : priceRaw as double;
        
        // Cache the rate
        _cachedRate = price;
        _lastUpdate = DateTime.now();
        
        print('💰 Current Bitcoin price: \$${price.toStringAsFixed(2)} USD');
        return price;
      } else {
        throw Exception('Failed to fetch Bitcoin price: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching Bitcoin price: $e');
      
      // Return a fallback rate if API fails (you can update this periodically)
      const fallbackRate = 100000.0; // Fallback BTC price in USD (updated to current price)
      print('💰 Using fallback Bitcoin price: \$${fallbackRate.toStringAsFixed(2)} USD');
      return fallbackRate;
    }
  }

  /// Convert USD amount to Bitcoin
  static Future<double> usdToBitcoin(double usdAmount) async {
    final btcPrice = await getBitcoinPrice();
    final btcAmount = usdAmount / btcPrice;
    
    // Round to 8 decimal places (standard for Bitcoin)
    return double.parse(btcAmount.toStringAsFixed(8));
  }

  /// Convert USD amount to mBTC (milliBitcoin)
  static Future<double> usdToMilliBitcoin(double usdAmount) async {
    final btcAmount = await usdToBitcoin(usdAmount);
    return btcAmount * 1000; // 1 BTC = 1000 mBTC
  }

  /// Convert Bitcoin amount to USD
  static Future<double> bitcoinToUsd(double btcAmount) async {
    final btcPrice = await getBitcoinPrice();
    return btcAmount * btcPrice;
  }

  /// Convert mBTC amount to USD
  static Future<double> milliBitcoinToUsd(double mbtcAmount) async {
    final btcAmount = mbtcAmount / 1000; // 1000 mBTC = 1 BTC
    return await bitcoinToUsd(btcAmount);
  }

  /// Format Bitcoin amount for display
  static String formatBitcoinAmount(double btcAmount) {
    if (btcAmount < 0.001) {
      // For very small amounts, show more decimal places
      return btcAmount.toStringAsFixed(8);
    } else if (btcAmount < 1) {
      // For amounts less than 1 BTC, show 4 decimal places
      return btcAmount.toStringAsFixed(4);
    } else {
      // For amounts 1 BTC or more, show 2 decimal places
      return btcAmount.toStringAsFixed(2);
    }
  }

  /// Format mBTC amount for display
  static String formatMilliBitcoinAmount(double mbtcAmount) {
    if (mbtcAmount < 1) {
      // For very small amounts, show 3 decimal places
      return mbtcAmount.toStringAsFixed(3);
    } else if (mbtcAmount < 100) {
      // For amounts less than 100 mBTC, show 2 decimal places
      return mbtcAmount.toStringAsFixed(2);
    } else {
      // For amounts 100 mBTC or more, show 1 decimal place
      return mbtcAmount.toStringAsFixed(1);
    }
  }

  /// Get formatted Bitcoin amount with USD equivalent
  static Future<String> getFormattedBitcoinAmount(double usdAmount) async {
    final btcAmount = await usdToBitcoin(usdAmount);
    final formattedBtc = formatBitcoinAmount(btcAmount);
    return '$formattedBtc BTC (\$${usdAmount.toStringAsFixed(2)} USD)';
  }

  /// Get formatted mBTC amount with USD equivalent
  static Future<String> getFormattedMilliBitcoinAmount(double usdAmount) async {
    final mbtcAmount = await usdToMilliBitcoin(usdAmount);
    final formattedMbtc = formatMilliBitcoinAmount(mbtcAmount);
    return '$formattedMbtc mBTC (\$${usdAmount.toStringAsFixed(2)} USD)';
  }

  /// Get the best denomination for display (BTC or mBTC)
  /// Returns true if mBTC should be used, false for BTC
  static Future<bool> shouldUseMilliBitcoin(double usdAmount) async {
    final btcAmount = await usdToBitcoin(usdAmount);
    // Use mBTC if the amount is less than 0.01 BTC (10 mBTC)
    return btcAmount < 0.01;
  }

  /// Get formatted amount in the best denomination
  static Future<String> getFormattedAmount(double usdAmount) async {
    final shouldUseMbtc = await shouldUseMilliBitcoin(usdAmount);
    if (shouldUseMbtc) {
      return await getFormattedMilliBitcoinAmount(usdAmount);
    } else {
      return await getFormattedBitcoinAmount(usdAmount);
    }
  }
} 