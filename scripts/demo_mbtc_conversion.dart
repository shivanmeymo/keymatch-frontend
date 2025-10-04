import 'dart:io';
import '../lib/services/bitcoin_conversion_service.dart';

void main() async {
  print('🪙 Bitcoin mBTC Conversion Demo');
  print('================================\n');

  // Test different USD amounts
  final testAmounts = [1.99, 4.99, 9.99, 19.99, 49.99, 99.99];

  for (final usdAmount in testAmounts) {
    print('💰 Testing \$${usdAmount.toStringAsFixed(2)} USD:');
    
    try {
      // Get the best denomination for this amount
      final shouldUseMbtc = await BitcoinConversionService.shouldUseMilliBitcoin(usdAmount);
      final formattedAmount = await BitcoinConversionService.getFormattedAmount(usdAmount);
      
      print('   Best denomination: ${shouldUseMbtc ? 'mBTC' : 'BTC'}');
      print('   Formatted amount: $formattedAmount');
      
      // Also show both BTC and mBTC for comparison
      final btcAmount = await BitcoinConversionService.usdToBitcoin(usdAmount);
      final mbtcAmount = await BitcoinConversionService.usdToMilliBitcoin(usdAmount);
      
      print('   BTC equivalent: ${BitcoinConversionService.formatBitcoinAmount(btcAmount)} BTC');
      print('   mBTC equivalent: ${BitcoinConversionService.formatMilliBitcoinAmount(mbtcAmount)} mBTC');
      
    } catch (e) {
      print('   Error: $e');
    }
    
    print('');
  }

  print('✅ Demo completed!');
} 