import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';

class LocationPicker extends StatefulWidget {
  final Function(double lat, double lng, String address)? onLocationSelected;

  const LocationPicker({Key? key, this.onLocationSelected}) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for location...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _isSearching
                  ? CircularProgressIndicator()
                  : IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<LocationProvider>(
                          context,
                          listen: false,
                        ).searchLocation('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _performSearch(value);
              }
            },
          ),
        ),

        // Search Results
        Expanded(
          child: Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              if (locationProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (locationProvider.searchResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_searching,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Search for a location',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: locationProvider.searchResults.length,
                itemBuilder: (context, index) {
                  final result = locationProvider.searchResults[index];
                  return ListTile(
                    leading: Icon(Icons.location_pin),
                    title: Text(result.address),
                    subtitle: Text(
                      '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                    ),
                    onTap: () {
                      if (widget.onLocationSelected != null) {
                        widget.onLocationSelected!(
                          result.latitude,
                          result.longitude,
                          result.address,
                        );
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    await locationProvider.searchLocation(query);

    setState(() {
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
