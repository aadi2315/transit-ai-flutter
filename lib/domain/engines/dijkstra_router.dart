/// Multimodal Route Graph Router (PRD §4: "Multimodal Graph Router").
///
/// This solves step 1 of the problem: given a start stop and an end stop,
/// which bus(es) does the rider need, and at which stop do they transfer?
///
/// GRAPH DESIGN
/// Node = "routeId|stopId" ("currently riding routeId, at stopId")
/// Edges:
///   - RIDE      : consecutive stops on the same route (weight = travel time)
///   - TRANSFER  : same physical stop, switching routes (weight = headway/transfer penalty)
///   - BOARD     : virtual start -> any (route, originStop) node
///   - ALIGHT    : any (route, destStop) node -> virtual end
library dijkstra_router;

import '../models/transit_graph_models.dart';

const double _defaultAvgBusSpeedMps = 20 * 1000 / 3600; // 20 km/h default
const double _defaultTransferPenaltySeconds = 15 * 60; // 15 mins headway transfer wait
const double _defaultBoardingPenaltySeconds = 60; // 1 min initial board

const String _startNode = '__START__';
const String _endNode = '__END__';

enum _EdgeKind { ride, transfer, board, alight }

class _Edge {
  final String to;
  final double weight;
  final _EdgeKind kind;
  const _Edge(this.to, this.weight, this.kind);
}

/// Minimal binary min-heap so this file has zero external dependencies.
class _PriorityQueue {
  final List<MapEntry<double, String>> _heap = [];

  bool get isEmpty => _heap.isEmpty;

  void push(double priority, String value) {
    _heap.add(MapEntry(priority, value));
    int i = _heap.length - 1;
    while (i > 0) {
      final parent = (i - 1) ~/ 2;
      if (_heap[parent].key <= _heap[i].key) break;
      final tmp = _heap[parent];
      _heap[parent] = _heap[i];
      _heap[i] = tmp;
      i = parent;
    }
  }

  MapEntry<double, String> pop() {
    final top = _heap.first;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      int i = 0;
      while (true) {
        final l = 2 * i + 1, r = 2 * i + 2;
        int smallest = i;
        if (l < _heap.length && _heap[l].key < _heap[smallest].key) smallest = l;
        if (r < _heap.length && _heap[r].key < _heap[smallest].key) smallest = r;
        if (smallest == i) break;
        final tmp = _heap[smallest];
        _heap[smallest] = _heap[i];
        _heap[i] = tmp;
        i = smallest;
      }
    }
    return top;
  }
}

class TransitRouter {
  final Map<String, Stop> stopsById;
  final List<RouteStopSequence> sequences;
  final Map<String, String> _routeShortNameById;

  final Map<String, List<_Edge>> _adj = {};
  final Map<String, List<String>> _routesAtStop = {};

  TransitRouter({required this.stopsById, required this.sequences})
      : _routeShortNameById = {
          for (final s in sequences) s.routeId: s.routeShortName,
        } {
    _buildGraph();
  }

  factory TransitRouter.fromLists({
    required List<Stop> stops,
    required List<RouteStopSequence> sequences,
  }) {
    return TransitRouter(
      stopsById: {for (final s in stops) s.stopId: s},
      sequences: sequences,
    );
  }

  /// Alias for findRoute supporting named parameters
  Itinerary? route({
    required String originStopId,
    required String destinationStopId,
    bool useHeuristic = false,
  }) =>
      findRoute(originStopId, destinationStopId, useHeuristic: useHeuristic);

  static String _node(String routeId, String stopId) => '$routeId|$stopId';

  void _buildGraph() {
    // 1. IN-VEHICLE RIDE EDGES (Consecutive stops on the same route N -> N+1)
    for (final seq in sequences) {
      final ids = seq.stopIdsInOrder;
      for (int i = 0; i < ids.length - 1; i++) {
        final fromId = ids[i];
        final toId = ids[i + 1];

        double travelTimeS;
        if (seq.travelTimeFromPrevMins.containsKey(toId)) {
          travelTimeS = seq.travelTimeFromPrevMins[toId]! * 60.0;
        } else {
          final a = stopsById[fromId];
          final b = stopsById[toId];
          if (a != null && b != null) {
            final distM = GeoMath.haversineM(a.lat, a.lon, b.lat, b.lon);
            travelTimeS = distM / _defaultAvgBusSpeedMps;
          } else {
            travelTimeS = 180.0; // 3 mins fallback
          }
        }

        _adj
            .putIfAbsent(_node(seq.routeId, fromId), () => [])
            .add(_Edge(_node(seq.routeId, toId), travelTimeS, _EdgeKind.ride));
      }

      for (final sid in ids) {
        _routesAtStop.putIfAbsent(sid, () => []).add(seq.routeId);
      }
    }

    // 2. TRANSFER EDGES (Interchange stops shared across routes)
    _routesAtStop.forEach((stopId, routeIds) {
      final uniq = routeIds.toSet().toList();
      for (final r1 in uniq) {
        for (final r2 in uniq) {
          if (r1 == r2) continue;
          // Find headway of the target route
          final targetSeq = sequences.firstWhere(
            (s) => s.routeId == r2,
            orElse: () => RouteStopSequence(routeId: r2, routeShortName: r2, stopIdsInOrder: []),
          );
          final waitSeconds = targetSeq.headwayMins > 0
              ? targetSeq.headwayMins * 60.0
              : _defaultTransferPenaltySeconds;

          _adj
              .putIfAbsent(_node(r1, stopId), () => [])
              .add(_Edge(_node(r2, stopId), waitSeconds, _EdgeKind.transfer));
        }
      }
    });
  }

  /// Finds the lowest-cost itinerary from [originStopId] to [destinationStopId].
  /// Returns null if the two stops aren't connected in this graph.
  Itinerary? findRoute(
    String originStopId,
    String destinationStopId, {
    bool useHeuristic = false,
  }) {
    final dest = stopsById[destinationStopId];
    if (dest == null || !stopsById.containsKey(originStopId)) {
      return null;
    }

    double heuristic(String node) {
      if (!useHeuristic || node == _startNode || node == _endNode) return 0;
      final parts = node.split('|');
      if (parts.length < 2) return 0;
      final s = stopsById[parts[1]];
      if (s == null) return 0;
      final straightLineM = GeoMath.haversineM(s.lat, s.lon, dest.lat, dest.lon);
      return straightLineM / _defaultAvgBusSpeedMps;
    }

    // Virtual BOARD / ALIGHT edges for this specific query.
    final localAdj = <String, List<_Edge>>{};
    _adj.forEach((k, v) => localAdj[k] = List.of(v));

    for (final seq in sequences) {
      if (seq.stopIdsInOrder.contains(originStopId)) {
        localAdj
            .putIfAbsent(_startNode, () => [])
            .add(_Edge(_node(seq.routeId, originStopId), _defaultBoardingPenaltySeconds, _EdgeKind.board));
      }
      if (seq.stopIdsInOrder.contains(destinationStopId)) {
        localAdj
            .putIfAbsent(_node(seq.routeId, destinationStopId), () => [])
            .add(const _Edge(_endNode, 0, _EdgeKind.alight));
      }
    }

    final dist = <String, double>{_startNode: 0};
    final prevNode = <String, String>{};
    final prevKind = <String, _EdgeKind>{};
    final visited = <String>{};
    final pq = _PriorityQueue()..push(0, _startNode);

    while (!pq.isEmpty) {
      final entry = pq.pop();
      final u = entry.value;
      if (visited.contains(u)) continue;
      visited.add(u);
      if (u == _endNode) break;

      for (final edge in localAdj[u] ?? const <_Edge>[]) {
        final tentative = (dist[u] ?? double.infinity) + edge.weight;
        if (tentative < (dist[edge.to] ?? double.infinity)) {
          dist[edge.to] = tentative;
          prevNode[edge.to] = u;
          prevKind[edge.to] = edge.kind;
          pq.push(tentative + heuristic(edge.to), edge.to);
        }
      }
    }

    if (!prevNode.containsKey(_endNode)) return null;

    // Reconstruct path, then collapse into rider-facing legs.
    final rawPath = <MapEntry<String, _EdgeKind>>[];
    String node = _endNode;
    while (node != _startNode) {
      final p = prevNode[node]!;
      final kind = prevKind[node]!;
      rawPath.add(MapEntry(node, kind));
      node = p;
    }
    final ordered = rawPath.reversed.toList();

    final legs = <TripLeg>[];
    String? currentRoute;
    String? legBoardStop;
    String? lastStop;

    for (final e in ordered) {
      final n = e.key;
      final kind = e.value;
      if (kind == _EdgeKind.board) {
        currentRoute = n.split('|')[0];
        legBoardStop = n.split('|')[1];
        lastStop = legBoardStop;
      } else if (kind == _EdgeKind.ride) {
        lastStop = n.split('|')[1];
      } else if (kind == _EdgeKind.transfer) {
        legs.add(TripLeg(
          routeId: currentRoute!,
          routeShortName: _routeShortNameById[currentRoute] ?? currentRoute,
          boardStopId: legBoardStop!,
          alightStopId: lastStop!,
        ));
        currentRoute = n.split('|')[0];
        legBoardStop = n.split('|')[1];
        lastStop = legBoardStop;
      } else if (kind == _EdgeKind.alight) {
        legs.add(TripLeg(
          routeId: currentRoute!,
          routeShortName: _routeShortNameById[currentRoute] ?? currentRoute,
          boardStopId: legBoardStop!,
          alightStopId: lastStop!,
        ));
      }
    }

    return Itinerary(legs: legs, estimatedTotalSeconds: dist[_endNode]!);
  }
}
