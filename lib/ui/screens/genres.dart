import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/genre_provider.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenresScreen extends StatefulWidget {
  static const routeName = '/genres';
  final AppRouter router;

  const GenresScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _GenresScreenState createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  var _loading = false;
  var _errored = false;

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await context.read<GenreProvider>().fetch();
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<GenreProvider>(
          builder: (_, provider, __) {
            if (provider.genres.isEmpty) {
              if (_loading) {
                return const Center(child: Spinner(size: 16));
              }
              if (_errored) return OopsBox(onRetry: fetchData);
            }

            return CupertinoTheme(
              data: CupertinoThemeData(primaryColor: Colors.white),
              child: PullToRefresh(
                onRefresh: fetchData,
                child: CustomScrollView(
                  slivers: [
                    CupertinoSliverNavigationBar(enableBackgroundFilterBlur: false,
                      backgroundColor: highlightAccentColor,
                      largeTitle: const LargeTitle(text: 'Genres'),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= provider.genres.length) return null;
                          final genre = provider.genres[index];
                          return GenreRow(
                            genre: genre,
                            router: widget.router,
                          );
                        },
                        childCount: provider.genres.length,
                      ),
                    ),
                    const BottomSpace(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GenreRow extends StatelessWidget {
  final Genre genre;
  final AppRouter router;

  const GenreRow({Key? key, required this.genre, required this.router})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => router.gotoGenreDetailsScreen(
          context,
          genre: genre,
        ),
        child: ListTile(
          shape: Border(bottom: Divider.createBorderSide(context)),
          title: Text(
            genre.name.isEmpty ? 'Unknown Genre' : genre.name,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${genre.songCount} song${genre.songCount == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}
