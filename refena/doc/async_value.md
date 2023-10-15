# Async Value

To represent loading and error states while fetching data, Refena provides the `AsyncValue` class.

An `AsyncValue` can be in 3 states:

- `AsyncValue.loading`: the data is currently being fetched
- `AsyncValue.error`: an error occurred while fetching the data
- `AsyncValue.data`: the data was successfully fetched

```dart
final booksProvider = FutureProvider<List<String>>((ref) async {
  final response = await http.get(
    Uri.https('https://api.books.com/books'),
  );
  final json = jsonDecode(response.body);
  return (json['books'] as List).cast<String>();
});

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final books = context.ref.watch(booksProvider);
    // Perform a switch-case on the result to handle loading/error states
    return boredSuggestion.when(
      data: (books) => Text(data.join(', ')),
      loading: () => Text('loading'),
      error: (error, stackTrace) => Text('error: $error'),
    );
  }
}
```

It comes with neat features such as

- `when` to handle loading/error states,
- `join` to join multiple `AsyncValue`s into one, and
- `map` to map the data type of `AsyncValue` while keeping the error / loading state.

## Transforming the data type of AsyncValue

Let's assume you write a view mode on top of `booksProvider` that also exposes the number of books:

```dart
class BookPageVm {
  final int bookCount;
  final List<String> books;
  
  BookPageVm({
    required this.bookCount,
    required this.books,
  });
}

final bookPageVmProvider = ViewProvider<AsyncValue<BookPageVm>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.map((books) {
    return BookPageVm(
      bookCount: books.length,
      books: books,
    );
  });
});
```

As you can see, `bookPageVmProvider` is a `ViewProvider<AsyncValue<BookPageVm>>` that depends on `booksProvider`.

Instead of manually mapping each state of `booksAsync`,
you can use `map` to map the data type of `booksAsync` while keeping the error / loading state.

In the widget, you can then use `when` to handle the loading/error states (as usual):

```dart
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.ref.watch(bookPageVmProvider);
    // Perform a switch-case on the result to handle loading/error states
    return vm.when(
      data: (books) => Text('${books.bookCount} books: ${books.books.join(', ')}'),
      loading: () => Text('loading'),
      error: (error, stackTrace) => Text('error: $error'),
    );
  }
}
```

## Joining multiple AsyncValues into one

Joining multiple `AsyncValue`s into one is similar to `map`, but it allows you to join multiple `AsyncValue`s into one.

Here, we use the new Records feature of Dart.

Let's extend the previous example to also fetch the sold-out books:

```dart
final soldOutBooksProvider = FutureProvider<List<String>>((ref) async {
  final response = await http.get(
    Uri.https('https://api.books.com/sold-out'),
  );
  final json = jsonDecode(response.body);
  return (json['books'] as List).cast<String>();
});
```

We then fetch all books and sold-out books in parallel:

```dart
class BookData {
  final String title;
  final bool soldOut;

  BookData({
    required this.title,
    required this.soldOut,
  });
}
```

```dart
final soldOutProvider = ViewProvider<AsyncValue<List<BookData>>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  final soldOutBooksAsync = ref.watch(soldOutBooksProvider);
  return (booksAsync, soldOutBooksAsync).join((books, soldOutBooks) {
    return books.map((book) {
      return BookData(
        title: book,
        soldOut: soldOutBooks.contains(book),
      );
    }).toList();
  });
});
```

As you can see, we use `join` to join `booksAsync` and `soldOutBooksAsync` into one `AsyncValue`.
