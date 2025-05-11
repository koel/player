import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class PodcastProvider with ChangeNotifier, StreamSubscriber {
  var _podcasts = <Podcast>[];
  final _vault = <String, Podcast>{};

  PodcastProvider() {
    subscribe(AuthProvider.userLoggedOutStream.listen((_) {
      _podcasts.clear();
      _vault.clear();

      notifyListeners();
    }));
  }

  List<Podcast> get podcasts => _podcasts;

  Future<void> fetchAll() async {
    _podcasts = _parsePodcastsFromJson(await get('podcasts'));
    _podcasts.forEach((element) => _vault[element.id] = element);

    notifyListeners();
  }

  List<Podcast> _parsePodcastsFromJson(List<dynamic> json) {
    return json.map<Podcast>((j) => Podcast.fromJson(j)).toList();
  }

  Future<void> refresh() {
    _podcasts.clear();
    _vault.clear();
    return fetchAll();
  }

  Future<void> unsubscribePodcast(Podcast podcast) async {
    await delete('podcasts/${podcast.id}/subscriptions');

    _podcasts.remove(podcast);
    _vault.remove(podcast.id);

    notifyListeners();
  }

  Future<Podcast> add({required String url}) async {
    final json = await post('podcasts', data: {'url': url});
    final podcast = Podcast.fromJson(json);

    _podcasts.add(podcast);
    _vault[podcast.id] = podcast;

    notifyListeners();

    return podcast;
  }

  Future<Podcast> resolve(String id, {bool forceRefresh = false}) async {
    if (!_vault.containsKey(id) || forceRefresh) {
      _vault[id] = Podcast.fromJson(await get('podcasts/$id'));
    }

    return _vault[id]!;
  }

  Future<num> getEpisodeProgress(Episode episode) async {
    try {
      final podcast = await resolve(episode.podcastId);
      return podcast.state.progresses[episode.id] ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
