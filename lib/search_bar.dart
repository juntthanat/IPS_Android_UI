import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/beacon_loc_request.dart';
import 'package:flutter_thesis_project/navigation.dart';
import 'package:flutter_thesis_project/screensize_converter.dart';

const Duration debounceDuration = Duration(milliseconds: 500);

class AsyncAutocomplete extends StatefulWidget {
  final Beacon selectedBeacon;
  final EnableNavigate enableNavigate;
  final int currentFloorId;
  final GeoScaledUnifiedMapper geoScaledUnifiedMapper;

  const AsyncAutocomplete({
    super.key,
    required this.selectedBeacon,
    required this.enableNavigate,
    required this.currentFloorId,
    required this.geoScaledUnifiedMapper,
  });

  @override
  State<AsyncAutocomplete> createState() => _AsyncAutocompleteState();
}

class _AsyncAutocompleteState extends State<AsyncAutocomplete> {
  String? _currentQuery;

  late Iterable<String> _lastOptions = <String>[];

  late final _Debounceable<Iterable<String>?, String> _debouncedSearch;
  bool _networkError = false;

  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    late final Iterable<String> options;
    try {
      final response = await fetchGeoBeaconsFromNameQuery(_currentQuery!);
      options = response.map((e) => e.name);
    } catch (error) {
      if (error is _NetworkException) {
        setState(() {
          _networkError = true;
        });
        return <String>[];
      }
    }

    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      fieldViewBuilder: (BuildContext context, TextEditingController controller,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            errorText:
                _networkError ? 'Network error, please try again.' : null,
            contentPadding: const EdgeInsets.all(20.0),
          ),
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        setState(() {
          _networkError = false;
        });
        final Iterable<String>? options =
            await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      onSelected: (String selection) async {
        debugPrint('You just selected $selection');
        var selectedGeoBeacon =
            await fetchGeoBeaconFromExactNameQuery(selection);
        if (selectedGeoBeacon.getFloorId() == -1) {
          return;
        }

        var scaledUnifiedX = widget.geoScaledUnifiedMapper.getWidthPixel(selectedGeoBeacon.geoX, selectedGeoBeacon.getFloorId());
        var scaledUnifiedY = widget.geoScaledUnifiedMapper.getHeightPixel(selectedGeoBeacon.geoY, selectedGeoBeacon.getFloorId());

        print("Scaled Unified X: $scaledUnifiedX Y: $scaledUnifiedY");

        var selectedBeacon = Beacon(
            id: selectedGeoBeacon.id,
            x: scaledUnifiedX,
            y: scaledUnifiedY,
            name: selectedGeoBeacon.name,
            macAddress: selectedGeoBeacon.macAddress);
        
        if (widget.currentFloorId != selectedGeoBeacon.getFloorId()) {
          showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Wrong Floor'),
              content: const Text('Your destination is on another floor!'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        // DO NOT MODIFY THE FOLLOWING 5 LINES (DANGER BLOCK) TO USE ASSIGNMENT INSTEAD OF THIS UGLY THING
        // REASON: THE PARENT COMPONENT WILL NOT ALLOW THE NEW VARIABLE TO BE ASSIGNED

        // START DANGER BLOCK
        widget.selectedBeacon.id = selectedBeacon.id;
        widget.selectedBeacon.x = selectedBeacon.x;
        widget.selectedBeacon.y = selectedBeacon.y;
        widget.selectedBeacon.name = selectedBeacon.name;
        widget.selectedBeacon.macAddress = selectedBeacon.macAddress;
        // END DANGER BLOCK

        widget.enableNavigate.setState(true);
      },
    );
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
///
/// This means that the original function will be called only after no calls
/// have been made for the given Duration.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}

// An exception indicating that a network request has failed.
class _NetworkException implements Exception {
  const _NetworkException();
}
