import 'package:equatable/equatable.dart';

enum PostStatus { draft, scheduled, publishing, published, failed, cancelled }

class PlatformModel extends Equatable {
  const PlatformModel({
    required this.id,
    required this.name,
    required this.color,
    required this.accounts,
  });

  final String id;
  final String name;
  final int color;
  final List<String> accounts;

  @override
  List<Object?> get props => [id, name, color, accounts];
}

class PostModel extends Equatable {
  const PostModel({
    required this.id,
    required this.title,
    required this.caption,
    required this.platforms,
    required this.status,
    this.publishAt,
    this.thumbnail,
    this.scheduledDate,
  });

  final String id;
  final String title;
  final String caption;
  final List<String> platforms;
  final PostStatus status;
  final String? publishAt;
  final String? thumbnail;
  final DateTime? scheduledDate;

  @override
  List<Object?> get props =>
      [id, title, caption, platforms, status, publishAt, thumbnail, scheduledDate];
}

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String time;
  final bool read;

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        time: time,
        read: read ?? this.read,
      );

  @override
  List<Object?> get props => [id, type, title, body, time, read];
}

class PlanModel extends Equatable {
  const PlanModel({
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.current = false,
    this.popular = false,
  });

  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool current;
  final bool popular;

  @override
  List<Object?> get props => [name, price, period, features, current, popular];
}

class CalEvent extends Equatable {
  const CalEvent({
    required this.title,
    required this.platforms,
    required this.time,
  });

  final String title;
  final List<String> platforms;
  final String time;

  @override
  List<Object?> get props => [title, platforms, time];
}

class TrendPoint extends Equatable {
  const TrendPoint({required this.date, required this.pub, required this.fail});
  final String date;
  final double pub;
  final double fail;
  @override
  List<Object?> get props => [date, pub, fail];
}

class FreqPoint extends Equatable {
  const FreqPoint({required this.day, required this.v});
  final String day;
  final double v;
  @override
  List<Object?> get props => [day, v];
}

class PieSlice extends Equatable {
  const PieSlice({required this.name, required this.value, required this.color});
  final String name;
  final double value;
  final int color;
  @override
  List<Object?> get props => [name, value, color];
}
