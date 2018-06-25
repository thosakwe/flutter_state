import 'dart:async';

/// An immutable wrapper around a Dart object; it fires an event on update.
class Immutable<T> {
  final List<Immutable> _children = [];
  final StreamController<T> _onChange = new StreamController<T>(sync: true);
  bool _isClosed = false;
  T _current;

  Immutable(this._current);

  /// The current value of this [Immutable].
  T get current => _current;

  /// Returns `true` after a call to [close].
  bool get isClosed => _isClosed;

  /// A [Stream] that fires when [change] is called.
  ///
  /// You will never have to call this.
  Stream<T> get onChange => _onChange.stream;

  /// Disposes of this [Immutable], and of any children.
  void close() {
    if (_isClosed) return;
    //print('Closing $hashCode');
    _isClosed = true;
    _children.forEach((s) => s.close());
    _onChange.close();
  }

  /// Shorthand for calling [change] with a completely new value.
  void replace(T newValue) => change((_) => newValue);

  /// Asynchronously signal that the value of this [Immutable] has changed.
  void change(T Function(T) update) {
    if (!_onChange.isClosed) {
      //print('New from $hashCode: ${update(_current)}');
      _onChange.add(update(_current));
    }
  }

  /// Returns an immutable wrapper over a value that, in most use cases, is a property of [current].
  ///
  /// You can optionally include a [change] function, so that the child [Immutable] can be used to signal an update
  /// within the parent.
  ///
  /// If no [change] function is provided, then the child state will be completely immutable.
  Immutable<U> property<U>(U Function(T) current, {T Function(T, U) change}) {
    var state = new Immutable<U>(current(this.current));
    _children.add(state);
    if (change == null) return state.._onChange.close();
    return state..onChange.listen((u) => this.change((t) => change(t, u)));
  }
}
