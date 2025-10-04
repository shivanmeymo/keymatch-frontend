// Temporarily disabled for APK build
// import 'package:flutter/material.dart';
// import 'package:key_match/services/location_service.dart';
// import 'package:key_match/services/profile_service.dart';
// import 'package:key_match/constants/colors.dart';

// class GpsLocationPicker extends StatefulWidget {
//   final Function(String) onLocationSelected;
//   final String? currentLocation;

//   const GpsLocationPicker({
//     Key? key,
//     required this.onLocationSelected,
//     this.currentLocation,
//   }) : super(key: key);

//   @override
//   State<GpsLocationPicker> createState() => _GpsLocationPickerState();
// }

// class _GpsLocationPickerState extends State<GpsLocationPicker> {
//   bool _isLoading = false;

//   Future<void> _getCurrentLocation() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final coordinates = await LocationService.getCurrentLocation();
//       if (coordinates != null) {
//         final locationString = '${coordinates['latitude']!.toStringAsFixed(4)}, ${coordinates['longitude']!.toStringAsFixed(4)}';
//         widget.onLocationSelected(locationString);
        
//         // Update profile with GPS coordinates
//         await ProfileService.updateLocationWithGPS(
//           coordinates['latitude']!,
//           coordinates['longitude']!,
//         );

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Location updated successfully!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error getting location: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.currentLocation != null) ...[
//           Text(
//             'Current Location: ${widget.currentLocation}',
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
//         ElevatedButton.icon(
//           onPressed: _isLoading ? null : _getCurrentLocation,
//           icon: Icon(Icons.location_on, color: AppColors.primary),
//           label: Text(_isLoading ? 'Getting Location...' : 'Get Current Location'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// } 