enum PostCategory {
  casual('Casual'),
  meme('Meme'),
  news('News'),
  question('Question'),
  discussion('Discussion');

  final String label;
  const PostCategory(this.label);

  factory PostCategory.fromString(String value) {
    return PostCategory.values.firstWhere(
      (category) => category.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PostCategory.casual,
    );
  }

  String toJson() => name;
  
  static PostCategory fromJson(String json) {
    return PostCategory.fromString(json);
  }
}
