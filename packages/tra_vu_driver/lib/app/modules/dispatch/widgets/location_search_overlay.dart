import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tra_vu_core/models/place_model.dart';
import '../../../services/location_service.dart';

class LocationSearchOverlay extends StatefulWidget {
  final String title;
  final String hint;
  final Function(Place place) onPlaceSelected;

  const LocationSearchOverlay({
    super.key,
    required this.title,
    required this.hint,
    required this.onPlaceSelected,
  });

  @override
  State<LocationSearchOverlay> createState() => _LocationSearchOverlayState();
}

class _LocationSearchOverlayState extends State<LocationSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final OsmLocationService _locationService = Get.find<OsmLocationService>();

  List<Place> _places = [];
  bool _isLoading = false;

  void _onSearchChanged(String query) {
    _locationService.searchWithDebounce(
      query,
      onResults: (results) {
        if (mounted) setState(() => _places = results);
      },
      onLoading: (loading) {
        if (mounted) setState(() => _isLoading = loading);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search field ─────────────────────────────────────────────────
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF2F4F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // ── Results list ─────────────────────────────────────────────────
          Expanded(
            child: _places.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Start typing to search…'
                          : 'No results found',
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _places.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF667085),
                        ),
                        title: Text(
                          place.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          widget.onPlaceSelected(place);
                          Get.back();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
