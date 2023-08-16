/// The object that gets fired by the stream.
class NotifierEvent<T> {
  final T prev;
  final T next;

  NotifierEvent(this.prev, this.next);

  @override
  String toString() {
    return 'NotifierEvent($prev -> $next)';
  }
}
