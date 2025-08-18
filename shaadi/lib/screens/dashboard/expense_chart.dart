import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseChart extends StatelessWidget {
  final Map<String, double> categorySummary;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  ExpenseChart({super.key, required this.categorySummary});

  @override
  Widget build(BuildContext context) {
    return categorySummary.isEmpty
        ? const Center(child: Text('No expense data'))
        : PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _getSections(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          );
  }

  List<PieChartSectionData> _getSections() {
    final List<Color> colors = [
      Colors.pink[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.amber[300]!,
      Colors.orange[300]!,
      Colors.red[300]!,
      Colors.teal[300]!,
    ];

    double total = categorySummary.values.fold(0, (sum, amount) => sum + amount);
    List<PieChartSectionData> sections = [];

    int i = 0;
    categorySummary.forEach((category, amount) {
      final double percentage = (amount / total) * 100;
      final color = colors[i % colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _Badge(
            category,
            currencyFormat.format(amount),
            color,
          ),
          badgePositionPercentageOffset: 1.2,
        ),
      );

      i++;
    });

    return sections;
  }
}

class _Badge extends StatelessWidget {
  final String category;
  final String amount;
  final Color color;

  const _Badge(this.category, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}