class AnalysisProgress {
  final int done;
  final int total;

  const AnalysisProgress(this.done, this.total);

  String get label => 'Analyzing songs · $done of $total';

  double get fraction => done / total;
}
