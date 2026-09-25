import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, child) => builder(context, a, b, child),
      ),
    );
  }
}

class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  const ValueListenableBuilder3({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.builder,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final Widget Function(BuildContext context, A a, B b, C c, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) => ValueListenableBuilder2<B, C>(
        first: second,
        second: third,
        builder: (context, b, c, child) => builder(context, a, b, c, child),
      ),
    );
  }
}

class ValueListenableBuilder4<A, B, C, D> extends StatelessWidget {
  const ValueListenableBuilder4({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.builder,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final List<ValueListenable> fourth;
  final Widget Function(BuildContext context, A a, B b, C c, List<dynamic> d, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, child) => ValueListenableBuilder<C>(
          valueListenable: third,
          builder: (context, c, child) => _MultiValueListenableBuilder(
            notifiers: fourth,
            builder: (context, dList, child) => builder(context, a, b, c, dList, child),
          ),
        ),
      ),
    );
  }
}

class ValueListenableBuilder5<A, B, C, D, E> extends StatelessWidget {
  const ValueListenableBuilder5({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.fifth,
    required this.builder,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final List<ValueListenable> fourth;
  final ValueListenable<E> fifth;
  final Widget Function(BuildContext context, A a, B b, C c, List<dynamic> d, E e, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, child) => ValueListenableBuilder<C>(
          valueListenable: third,
          builder: (context, c, child) => _MultiValueListenableBuilder(
            notifiers: fourth,
            builder: (context, dList, child) => ValueListenableBuilder<E>(
              valueListenable: fifth,
              builder: (context, e, child) => builder(context, a, b, c, dList, e, child),
            ),
          ),
        ),
      ),
    );
  }
}

class ValueListenableBuilder6<A, B, C, D, E, F> extends StatelessWidget {
  const ValueListenableBuilder6({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.fifth,
    required this.sixth,
    required this.builder,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final ValueListenable<C> third;
  final List<ValueListenable> fourth;
  final ValueListenable<E> fifth;
  final ValueListenable<F> sixth;
  final Widget Function(BuildContext context, A a, B b, C c, List<dynamic> d, E e, F f, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, child) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, child) => ValueListenableBuilder<C>(
          valueListenable: third,
          builder: (context, c, child) => _MultiValueListenableBuilder(
            notifiers: fourth,
            builder: (context, dList, child) => ValueListenableBuilder<E>(
              valueListenable: fifth,
              builder: (context, e, child) => ValueListenableBuilder<F>(
                valueListenable: sixth,
                builder: (context, f, child) => builder(context, a, b, c, dList, e, f, child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiValueListenableBuilder extends StatelessWidget {
  final List<ValueListenable> notifiers;
  final Widget Function(BuildContext context, List<dynamic> values, Widget? child) builder;

  const _MultiValueListenableBuilder({required this.notifiers, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (notifiers.isEmpty) return builder(context, [], null);
    return ValueListenableBuilder(
      valueListenable: notifiers.first,
      builder: (context, value, child) {
        return _MultiValueListenableBuilder(
          notifiers: notifiers.sublist(1),
          builder: (context, otherValues, child) {
            return builder(context, [value, ...otherValues], child);
          },
        );
      },
    );
  }
}
