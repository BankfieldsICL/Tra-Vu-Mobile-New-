import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class TrackingSocketService extends GetxService {
  io.Socket? _socket;
  final RxBool isConnected = false.obs;
  final RxString socketId = '...'.obs;
  final Map<String, List<Function(dynamic)>> _listenerRegistry = {};
  final Set<String> _jobSubscriptions = <String>{};

  String? _activeUrl;
  String? _activeToken;

  Future<void> init(String serverUrl, String token, String tenantId) async {
    // Avoid redundant reconnects if already connected with same credentials
    if (_socket != null && isConnected.value && _activeUrl == serverUrl && _activeToken == token) {
      debugPrint('[TrackingSocketService] Already connected with same token/url — skipping re-init.');
      return;
    }

    debugPrint('[TrackingSocketService] Initializing socket v3+ at $serverUrl | Tenant: $tenantId');
    _activeUrl = serverUrl;
    _activeToken = token;
    await disconnect();

    try {
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'tenantId': tenantId})
            .setAuth({'token': token, 'tenantId': tenantId})
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('[TrackingSocketService] Connected to tracking socket. ID: ${_socket?.id}');
        isConnected.value = true;
        socketId.value = _socket?.id ?? 'Unknown';
        _replaySubscriptions();
      });

      _socket!.onDisconnect((_) {
        debugPrint('[TrackingSocketService] Disconnected');
        isConnected.value = false;
        socketId.value = 'Disconnected';
      });

      // Wildcard listener for debugging incoming events
      _socket!.onAny((event, data) {
        debugPrint('[TrackingSocketService] ANY_EVENT: $event | DATA: $data');
      });

      _socket!.onConnectError((err) => debugPrint('[TrackingSocketService] Connect Error: $err'));
      _socket!.onError((err) => debugPrint('[TrackingSocketService] Error: $err'));

      _applyRegistry();

      _socket!.connect();

    } catch (e) {
      debugPrint('[TrackingSocketService] Exception during init: $e');
    }
  }

  void _applyRegistry() {
    if (_socket == null) return;
    _listenerRegistry.forEach((event, listeners) {
      _socket!.off(event);
      for (final listener in listeners) {
        _socket!.on(event, (data) {
          try {
            listener(data);
          } catch (e) {
            debugPrint('[TrackingSocketService] Error in listener for $event: $e');
          }
        });
      }
    });
  }

  void pushNewToken(String token) {
    if (_socket != null && isConnected.value) {
      debugPrint('[TrackingSocketService] Pushing new auth token to server...');
      _socket!.emit('updateAuthToken', {'token': token});
      // Invalidate cached token so next init() reconnects with the new one
      _activeToken = token;
    }
  }

  void _registerListener(String event, Function(dynamic) listener) {
    _listenerRegistry.putIfAbsent(event, () => []).add(listener);
    if (_socket != null) {
      _socket!.on(event, listener);
    }
  }

  void off(String event) {
    _listenerRegistry.remove(event);
    _socket?.off(event);
  }

  void _replaySubscriptions() {
    if (!isConnected.value || _socket == null) {
      return;
    }

    for (final jobId in _jobSubscriptions) {
      _socket!.emit('subscribeToJob', {'jobId': jobId});
    }
  }


  // --- DRIVER METHODS ---
  void updateLocation(double lat, double lng, {String? jobId}) {
    if (isConnected.value && _socket != null) {
      debugPrint('[TrackingSocketService] Emitting location: lat=$lat, lng=$lng (Job: $jobId)');
      _socket!.emit('updateLocation', {
        'lat': lat,
        'lng': lng,
        if (jobId != null) 'jobId': jobId,
      });
    } else {
      debugPrint('[TrackingSocketService] WARNING: Skipping location update (Not connected)');
    }
  }

  void listenForJobOffers(Function(Map<String, dynamic>) onOffer) {
    _registerListener('newJobOffer', (data) {
      if (data is Map) {
        onOffer(Map<String, dynamic>.from(data));
      }
    });
  }


  void acceptJob(String jobId) {
    _socket?.emit('acceptJob', {'jobId': jobId});
  }

  void emitStatusUpdate(String jobId, String status) {
    if (isConnected.value && _socket != null) {
      _socket!.emit('updateJobStatus', {'jobId': jobId, 'status': status});
    }
  }

  void listenForJobAcceptedSuccess(Function(Map<String, dynamic>) onSuccess) {
    _registerListener('jobAcceptedSuccess', (data) {
      if (data is Map) {
        onSuccess(Map<String, dynamic>.from(data));
      }
    });
  }


  void listenForJobAcceptedError(Function(Map<String, dynamic>) onError) {
    _registerListener('jobAcceptedError', (data) {
      if (data is Map) {
        onError(Map<String, dynamic>.from(data));
      }
    });
  }


  // --- CUSTOMER METHODS ---
  void subscribeToJob(String jobId) {
    _jobSubscriptions.add(jobId);
    if (isConnected.value && _socket != null) {
      _socket!.emit('subscribeToJob', {'jobId': jobId});
    }
  }

  void unsubscribeFromJob(String jobId) {
    _jobSubscriptions.remove(jobId);
    if (isConnected.value && _socket != null) {
      _socket!.emit('unsubscribeFromJob', {'jobId': jobId});
    }
  }

  void listenToDriverLocation(
    Function(Map<String, dynamic>) onLocationUpdated,
  ) {
    _registerListener('locationUpdated', (data) {
      if (data is Map) {
        onLocationUpdated(Map<String, dynamic>.from(data));
      }
    });
  }


  void listenToJobStatus(Function(Map<String, dynamic>) onStatusUpdated) {
    _registerListener('statusUpdated', (data) {
      if (data is Map) {
        onStatusUpdated(Map<String, dynamic>.from(data));
      }
    });
  }


  Future<void> disconnect() async {
    if (_socket == null) return;
    _socket!.dispose();
    _socket = null;
    isConnected.value = false;
    socketId.value = 'Disconnected';
    _activeUrl = null;
    _activeToken = null;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
