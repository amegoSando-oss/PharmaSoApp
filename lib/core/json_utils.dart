/// Laravel/MySQL often serializes bigint columns as JSON strings rather than
/// numbers, so every numeric field coming from the API is parsed leniently
/// instead of relying on a hard `as int`/`as num` cast.
int asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  return asInt(value);
}

num asNum(dynamic value) {
  if (value is num) return value;
  return num.parse(value.toString());
}

num? asNumOrNull(dynamic value) {
  if (value == null) return null;
  return asNum(value);
}
