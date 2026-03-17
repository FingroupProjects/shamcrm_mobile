enum RequestPriority {
  critical(0),
  high(1),
  normal(2),
  low(3),
  background(4);

  const RequestPriority(this.weight);

  final int weight;
}
