import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/places_service.dart';

class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlacePrediction> _predictions = const [];
  bool _loading = false;
  bool _showSuggestions = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay so a suggestion tap can register first.
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (!mounted || _focusNode.hasFocus) return;
          setState(() => _showSuggestions = false);
        });
      } else if (widget.controller.text.trim().length >= 2) {
        _scheduleSearch(widget.controller.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;
    _scheduleSearch(widget.controller.text);
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _predictions = const [];
        _loading = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _showSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 320), () async {
      final id = ++_requestId;
      final results = await PlacesService.autocomplete(query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _predictions = results;
        _loading = false;
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  void _select(PlacePrediction prediction) {
    widget.controller
      ..text = prediction.description
      ..selection = TextSelection.collapsed(
        offset: prediction.description.length,
      );
    setState(() {
      _predictions = const [];
      _showSuggestions = false;
      _loading = false;
    });
    _focusNode.unfocus();
  }

  Future<void> _openInMaps() async {
    final query = widget.controller.text.trim();
    if (query.isEmpty) return;
    final uri = PlacesService.mapsSearchUri(query);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Search Google Places…',
            prefixIcon: const Icon(Icons.place_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (hasText)
                  IconButton(
                    tooltip: 'Open in Google Maps',
                    onPressed: _openInMaps,
                    icon: Icon(
                      Icons.map_outlined,
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Material(
            color: scheme.surface,
            elevation: 2,
            shadowColor: scheme.shadow.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _predictions.isEmpty && !_loading
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'No Google Places matches. You can still type any address.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _predictions.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: scheme.outline.withValues(alpha: 0.2),
                            ),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: scheme.primary,
                            ),
                            title: Text(
                              _predictions[i].mainText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: _predictions[i].secondaryText.isEmpty
                                ? null
                                : Text(
                                    _predictions[i].secondaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            onTap: () => _select(_predictions[i]),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Powered by Google',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
