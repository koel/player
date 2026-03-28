import 'package:app/models/genre.dart';
import 'package:app/providers/genre_provider.dart';
import 'package:app/ui/screens/genres.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'genres_screen_test.mocks.dart';

@GenerateMocks([GenreProvider])
void main() {
  late MockGenreProvider genreProviderMock;

  setUp(() {
    genreProviderMock = MockGenreProvider();
  });

  Widget buildTestApp() {
    return ChangeNotifierProvider<GenreProvider>.value(
      value: genreProviderMock,
      child: const MaterialApp(home: GenresScreen()),
    );
  }

  testWidgets('shows genre list', (tester) async {
    final genres = [
      Genre.fake(name: 'Rock', songCount: 42),
      Genre.fake(name: 'Jazz', songCount: 10),
    ];

    when(genreProviderMock.genres).thenReturn(genres);
    when(genreProviderMock.fetch()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Rock'), findsOneWidget);
    expect(find.text('42 songs'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('10 songs'), findsOneWidget);
    verify(genreProviderMock.fetch()).called(1);
  });

  testWidgets('shows singular "song" for count of 1', (tester) async {
    when(genreProviderMock.genres)
        .thenReturn([Genre.fake(name: 'Blues', songCount: 1)]);
    when(genreProviderMock.fetch()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('1 song'), findsOneWidget);
    verify(genreProviderMock.fetch()).called(1);
  });

  testWidgets('shows Unknown Genre for empty name', (tester) async {
    when(genreProviderMock.genres)
        .thenReturn([Genre.fake(name: '', songCount: 5)]);
    when(genreProviderMock.fetch()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Unknown Genre'), findsOneWidget);
    verify(genreProviderMock.fetch()).called(1);
  });
}
