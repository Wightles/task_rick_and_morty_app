import 'package:json_annotation/json_annotation.dart';
import 'character_model.dart';

part 'character_response_model.g.dart';

@JsonSerializable()
class CharacterResponseModel {
  final Info info;
  final List<CharacterModel> results;

  CharacterResponseModel({
    required this.info,
    required this.results,
  });

  factory CharacterResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterResponseModelToJson(this);
}

@JsonSerializable()
class Info {
  final int count;
  final int pages;
  final String? next;
  final String? prev;

  Info({
    required this.count,
    required this.pages,
    this.next,
    this.prev,
  });

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);
  Map<String, dynamic> toJson() => _$InfoToJson(this);
}