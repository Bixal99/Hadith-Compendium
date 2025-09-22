import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hadith_iq/api/project_api.dart';
import 'package:hadith_iq/components/basic_app_bar.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:iconsax/iconsax.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String projectName; // Project name passed
  final VoidCallback projectButtonOnPressed;

  const DashboardPage(
      {super.key,
      required this.projectName,
      required this.onToggleTheme,
      required this.projectButtonOnPressed});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ---------------- Local Variables ----------------
  late String currentProjectName;
  ProjectService projectService = ProjectService();
  List<int?> countStats = List.filled(4, null);
  List<Map<String, dynamic>> topNarrators = [];
  List<Map<String, dynamic>> hadithsByBook = [];
  List<Map<String, dynamic>> narratorOpinions = [];
  bool _hasFetched = false;
  int _pieTouchedIndex = -1;
  int _hoveredVertBarIndex = -1;
  int _hoveredHorBarIndex = -1;
  // Define your specific colors for each label
  late Map<String, Color> opinionColors;

  // ---------------------------------------------

  // ---------------- Constructor ----------------
  @override
  void initState() {
    super.initState();
    currentProjectName = widget.projectName;
  }
  // ---------------------------------------------

  // ---------------- Helper Methods ----------------

  Future<void> getProjectStats(String projectName) async {
    Map<String, dynamic> response =
        await projectService.getProjectStats(projectName);

    if (response.containsKey('counts') &&
        response['counts'] != null &&
        response['counts'] is Map<String, dynamic> &&
        (response['counts'] as Map).isNotEmpty) {
      Map<String, dynamic> counts = response['counts'];

      setState(() {
        countStats[0] = counts['books'];
        countStats[1] = counts['hadiths'];
        countStats[2] = counts['sanads'];
        countStats[3] = counts['narrators_from_sanads'];
        topNarrators.clear();
        hadithsByBook.clear();
        narratorOpinions.clear();
        topNarrators =
            List<Map<String, dynamic>>.from(response["top_narrators"]);
        hadithsByBook =
            List<Map<String, dynamic>>.from(response["hadiths_by_book"]);
        narratorOpinions =
            List<Map<String, dynamic>>.from(response["narrator_opinions"]);
      });
    } else {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
            context,
            'Project counts data is missing or invalid',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
      }
    }
  }

  Widget _buildDashboard() {
    final int vertmaxCount = topNarrators.isNotEmpty
        ? topNarrators
            .map((e) => e['count'] as int)
            .reduce((a, b) => a > b ? a : b)
        : 100;
    final double vertMaxY = (vertmaxCount / 100).ceil() * 100;

    final sortedHadithCountByBook = [...hadithsByBook];
    sortedHadithCountByBook.sort((a, b) =>
        (b['hadith_count'] as int).compareTo(a['hadith_count'] as int));

    final horMaxCount = sortedHadithCountByBook.isNotEmpty
        ? sortedHadithCountByBook
            .map((e) => e['hadith_count'] as int)
            .reduce((a, b) => a > b ? a : b)
        : 0;

    final horMaxY = (horMaxCount / 100).ceil() * 100;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              MyBasicAppBar(
                onToggleTheme: widget.onToggleTheme,
                projectName: currentProjectName,
                projectButtonOnPressed: widget.projectButtonOnPressed,
              ),
              const SizedBox(
                height: 7,
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 35, left: 35, top: 10, bottom: 25),
                      child: Row(
                        spacing: 25,
                        children: [
                          Expanded(
                              child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                VariedIcon.varied(
                                  Symbols.newsstand_rounded,
                                  fill: 1,
                                  weight: 700,
                                  opticalSize: 43,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  size: 37,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Books",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    Text(
                                        countStats[0] == null
                                            ? "___"
                                            : "${countStats[0]}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          Expanded(
                              child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 34,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Hadiths",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    Text(
                                        countStats[1] == null
                                            ? "___"
                                            : "${countStats[1]}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          Expanded(
                              child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Icon(
                                  Iconsax.link_15,
                                  size: 34,
                                  color: Colors.grey,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Sanads",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    Text(
                                        countStats[2] == null
                                            ? "___"
                                            : "${countStats[2]}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          Expanded(
                              child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Iconsax.profile_2user5,
                                  size: 28,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Narrators",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    Text(
                                        countStats[3] == null
                                            ? "___"
                                            : "${countStats[3]}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 35, left: 35, bottom: 25),
                        child: Row(
                          spacing: 25,
                          children: [
                            Expanded(
                                flex: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      width: 0.5,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 7,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: topNarrators.isEmpty
                                      ? Center(
                                          child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.dnd_forwardslash_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              size: 50,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'No Data Available!',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface),
                                            ),
                                          ],
                                        ))
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            left: 25,
                                            right: 20,
                                            top: 20,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            spacing: 30,
                                            children: [
                                              Text(
                                                "Top Narrators by Hadith Count",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface),
                                              ),
                                              Expanded(
                                                child: BarChart(
                                                  BarChartData(
                                                    maxY: vertMaxY,
                                                    barTouchData: BarTouchData(
                                                      enabled: true,
                                                      handleBuiltInTouches:
                                                          true,
                                                      touchCallback:
                                                          (FlTouchEvent event,
                                                              BarTouchResponse?
                                                                  response) {
                                                        // Only update state if the event is a hover or touch
                                                        if (response != null &&
                                                            response.spot !=
                                                                null) {
                                                          setState(() {
                                                            _hoveredVertBarIndex =
                                                                response.spot!
                                                                    .touchedBarGroupIndex;
                                                          });
                                                        } else {
                                                          // If no bar is touched/hovered, reset the index
                                                          setState(() {
                                                            _hoveredVertBarIndex =
                                                                -1;
                                                          });
                                                        }
                                                      },
                                                      touchTooltipData:
                                                          BarTouchTooltipData(
                                                        tooltipBorderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        getTooltipColor:
                                                            (BarChartGroupData
                                                                group) {
                                                          return Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .secondary
                                                              .withValues(
                                                                  alpha: 0.8);
                                                        },
                                                        tooltipPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 6),
                                                        tooltipMargin: 12,
                                                        getTooltipItem: (group,
                                                            groupIndex,
                                                            rod,
                                                            rodIndex) {
                                                          final count =
                                                              rod.toY.toInt();
                                                          final name =
                                                              topNarrators[group
                                                                      .x
                                                                      .toInt()]
                                                                  ['name'];
                                                          return BarTooltipItem(
                                                            '$name\n رواية : $count',
                                                            TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSecondary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    barGroups: topNarrators
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      final index = entry.key;
                                                      final data = entry.value;
                                                      // Determine if this bar is currently hovered
                                                      final bool
                                                          isThisBarHovered =
                                                          index ==
                                                              _hoveredVertBarIndex;
                                                      const double
                                                          defaultBarWidth = 43;
                                                      double hoveredBarWidth =
                                                          55; // Adjust this value as needed

                                                      return BarChartGroupData(
                                                        x: index,
                                                        barRods: [
                                                          BarChartRodData(
                                                            toY: (data['count']
                                                                    as int)
                                                                .toDouble(),
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            // Dynamically set the width based on hover state
                                                            width: isThisBarHovered
                                                                ? hoveredBarWidth
                                                                : defaultBarWidth,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                    titlesData: FlTitlesData(
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 40,
                                                          getTitlesWidget:
                                                              (value, meta) {
                                                            final int index =
                                                                value.toInt();
                                                            if (index < 0 ||
                                                                index >=
                                                                    topNarrators
                                                                        .length) {
                                                              return Container();
                                                            }
                                                            String fullName =
                                                                topNarrators[
                                                                        index]
                                                                    ['name'];
                                                            String displayName =
                                                                fullName.length >
                                                                        16
                                                                    ? '…${fullName.substring(0, 15)}'
                                                                    : fullName;
                                                            return SideTitleWidget(
                                                              meta: meta,
                                                              space: 4.0,
                                                              angle: 0.0,
                                                              child: Text(
                                                                displayName,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            11),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          interval: 100,
                                                          getTitlesWidget:
                                                              (value, meta) {
                                                            return Text(value
                                                                .toInt()
                                                                .toString());
                                                          },
                                                          reservedSize: 32,
                                                        ),
                                                      ),
                                                      topTitles: const AxisTitles(
                                                          sideTitles:
                                                              SideTitles(
                                                                  showTitles:
                                                                      false)),
                                                      rightTitles:
                                                          const AxisTitles(
                                                              sideTitles:
                                                                  SideTitles(
                                                                      showTitles:
                                                                          false)),
                                                    ),
                                                    gridData: const FlGridData(
                                                      show: true,
                                                      drawVerticalLine: false,
                                                      drawHorizontalLine: true,
                                                    ),
                                                    borderData: FlBorderData(
                                                        show: false),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                )),
                            Expanded(
                                flex: 3,
                                child: Column(
                                  spacing: 25,
                                  children: [
                                    Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(15)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 7,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: sortedHadithCountByBook.isEmpty
                                              ? Center(
                                                  child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .dnd_forwardslash_outlined,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                      size: 40,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      'No Data Available!',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface),
                                                    ),
                                                  ],
                                                ))
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 20,
                                                          right: 20,
                                                          top: 20,
                                                          left: 10),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    spacing: 10,
                                                    children: [
                                                      Text(
                                                        "Hadith Count by books",
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface),
                                                      ),
                                                      Expanded(
                                                        child: RotatedBox(
                                                          quarterTurns:
                                                              1, // Horizontal chart
                                                          child: BarChart(
                                                            BarChartData(
                                                              maxY: horMaxY
                                                                  .toDouble(),
                                                              minY: 0,
                                                              barGroups:
                                                                  sortedHadithCountByBook
                                                                      .asMap()
                                                                      .entries
                                                                      .map(
                                                                (entry) {
                                                                  final index =
                                                                      entry.key;
                                                                  final data =
                                                                      entry
                                                                          .value;
                                                                  // Determine bar width based on hover state
                                                                  final barWidth =
                                                                      (_hoveredHorBarIndex ==
                                                                              index)
                                                                          ? 28.0
                                                                          : 18.0;

                                                                  return BarChartGroupData(
                                                                    x: index,
                                                                    barsSpace:
                                                                        4,
                                                                    barRods: [
                                                                      BarChartRodData(
                                                                        toY: data['hadith_count']
                                                                            .toDouble(),
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .secondary,
                                                                        width:
                                                                            barWidth, // Dynamically set width
                                                                        borderRadius:
                                                                            BorderRadius.circular(7),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              ).toList(),
                                                              titlesData:
                                                                  FlTitlesData(
                                                                leftTitles:
                                                                    const AxisTitles(
                                                                  sideTitles: SideTitles(
                                                                      showTitles:
                                                                          false),
                                                                ),
                                                                rightTitles:
                                                                    AxisTitles(
                                                                  sideTitles:
                                                                      SideTitles(
                                                                    interval: (horMaxY /
                                                                            7)
                                                                        .ceilToDouble(),
                                                                    showTitles:
                                                                        true,
                                                                    getTitlesWidget:
                                                                        (value,
                                                                            meta) {
                                                                      return RotatedBox(
                                                                        quarterTurns:
                                                                            3,
                                                                        child:
                                                                            Text(
                                                                          value
                                                                              .toInt()
                                                                              .toString(),
                                                                          style:
                                                                              const TextStyle(fontSize: 12),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                                topTitles:
                                                                    const AxisTitles(
                                                                  sideTitles: SideTitles(
                                                                      showTitles:
                                                                          false),
                                                                ),
                                                                bottomTitles:
                                                                    AxisTitles(
                                                                  sideTitles:
                                                                      SideTitles(
                                                                    showTitles:
                                                                        true,
                                                                    reservedSize:
                                                                        80,
                                                                    getTitlesWidget:
                                                                        (value,
                                                                            meta) {
                                                                      final index =
                                                                          value
                                                                              .toInt();
                                                                      if (index <
                                                                              0 ||
                                                                          index >=
                                                                              sortedHadithCountByBook.length) {
                                                                        return Container();
                                                                      }
                                                                      return Padding(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                4.0),
                                                                        child:
                                                                            RotatedBox(
                                                                          quarterTurns:
                                                                              3,
                                                                          child:
                                                                              Text(
                                                                            sortedHadithCountByBook[index]['title'],
                                                                            style:
                                                                                const TextStyle(fontSize: 12),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                              gridData:
                                                                  const FlGridData(
                                                                show: true,
                                                                drawVerticalLine:
                                                                    false,
                                                                drawHorizontalLine:
                                                                    true,
                                                              ),
                                                              borderData:
                                                                  FlBorderData(
                                                                      show:
                                                                          false),
                                                              barTouchData:
                                                                  BarTouchData(
                                                                enabled: true,
                                                                handleBuiltInTouches:
                                                                    true,
                                                                touchTooltipData:
                                                                    BarTouchTooltipData(
                                                                  fitInsideHorizontally:
                                                                      true,
                                                                  fitInsideVertically:
                                                                      true,
                                                                  rotateAngle:
                                                                      270,
                                                                  tooltipBorderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                  getTooltipColor:
                                                                      (BarChartGroupData
                                                                          group) {
                                                                    return Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .secondary
                                                                        .withValues(
                                                                            alpha:
                                                                                0.8);
                                                                  },
                                                                  tooltipPadding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          6),
                                                                  tooltipMargin:
                                                                      12,
                                                                  getTooltipItem: (group,
                                                                      groupIndex,
                                                                      rod,
                                                                      rodIndex) {
                                                                    final title =
                                                                        sortedHadithCountByBook[group
                                                                            .x
                                                                            .toInt()]['title'];
                                                                    return BarTooltipItem(
                                                                      '$title\n',
                                                                      TextStyle(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .onSecondary,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                      children: [
                                                                        TextSpan(
                                                                          text:
                                                                              '${rod.toY.toInt()} : أحاديث',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Theme.of(context).colorScheme.onSecondary,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ),
                                                                touchCallback:
                                                                    (FlTouchEvent
                                                                            event,
                                                                        BarTouchResponse?
                                                                            response) {
                                                                  if (event
                                                                          .isInterestedForInteractions &&
                                                                      response !=
                                                                          null &&
                                                                      response.spot !=
                                                                          null) {
                                                                    setState(
                                                                        () {
                                                                      _hoveredHorBarIndex = response
                                                                          .spot!
                                                                          .touchedBarGroupIndex;
                                                                    });
                                                                  } else {
                                                                    setState(
                                                                        () {
                                                                      _hoveredHorBarIndex =
                                                                          -1;
                                                                    });
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        )),
                                    Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(15)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 7,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: narratorOpinions.isEmpty
                                              ? Center(
                                                  child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .dnd_forwardslash_outlined,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                      size: 40,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      'No Data Available!',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface),
                                                    ),
                                                  ],
                                                ))
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 20,
                                                          right: 20,
                                                          top: 20,
                                                          left: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    spacing: 20,
                                                    children: [
                                                      Text(
                                                        'Narrator Opinions Distribution',
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          spacing: 20,
                                                          children: <Widget>[
                                                            // Pie Chart on the left
                                                            Expanded(
                                                              flex:
                                                                  2, // Give more space to the pie chart
                                                              child:
                                                                  AspectRatio(
                                                                aspectRatio:
                                                                    1, // Make the pie chart square
                                                                child: PieChart(
                                                                  PieChartData(
                                                                    pieTouchData:
                                                                        PieTouchData(
                                                                      touchCallback:
                                                                          (FlTouchEvent event,
                                                                              pieTouchResponse) {
                                                                        setState(
                                                                            () {
                                                                          if (!event.isInterestedForInteractions ||
                                                                              pieTouchResponse == null ||
                                                                              pieTouchResponse.touchedSection == null) {
                                                                            _pieTouchedIndex =
                                                                                -1;
                                                                            return;
                                                                          }
                                                                          _pieTouchedIndex = pieTouchResponse
                                                                              .touchedSection!
                                                                              .touchedSectionIndex;
                                                                        });
                                                                      },
                                                                    ),
                                                                    borderData:
                                                                        FlBorderData(
                                                                      show:
                                                                          false,
                                                                    ),
                                                                    sectionsSpace:
                                                                        2, // Space between sections
                                                                    centerSpaceRadius:
                                                                        30, // Inner circle radius
                                                                    sections:
                                                                        showingSections(),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex:
                                                                  1, // Give less space to the labels
                                                              child: ListView
                                                                  .builder(
                                                                itemCount:
                                                                    narratorOpinions
                                                                        .length,
                                                                itemBuilder:
                                                                    (context,
                                                                        index) {
                                                                  final opinion =
                                                                      narratorOpinions[
                                                                          index];
                                                                  final String
                                                                      opinionType =
                                                                      opinion['opinion']
                                                                          .toString();
                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            4.0),
                                                                    child: Row(
                                                                      spacing:
                                                                          10,
                                                                      children: [
                                                                        Container(
                                                                          width:
                                                                              16,
                                                                          height:
                                                                              16,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                opinionColors[opinionType] ?? Colors.black,
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                            boxShadow: [
                                                                              BoxShadow(
                                                                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                                                                blurRadius: 4,
                                                                                offset: const Offset(0, 2),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          '${opinion['opinion']} (${opinion['count']})',
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight: _pieTouchedIndex == index
                                                                                ? FontWeight.bold
                                                                                : FontWeight.normal,
                                                                            color: _pieTouchedIndex == index
                                                                                ? opinionColors[opinionType] ?? Colors.teal
                                                                                : Theme.of(context).colorScheme.onSurface,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        )),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return narratorOpinions.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == _pieTouchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 55.0 : 45.0;
      final double value =
          (data['count'] as num).toDouble(); // Ensure it's a double
      final String opinionType = data['opinion'].toString();

      return PieChartSectionData(
        color: opinionColors[opinionType] ?? Colors.black,
        value: value,
        title: '${value.toInt()}', // Display the count on the slice
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimary,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        badgeWidget: isTouched
            ? _buildBadge(data['opinion'].toString(), isTouched)
            : null, // Custom badge for touched section
        badgePositionPercentageOffset: 1.2, // Adjust badge position
      );
    }).toList();
  }

  Widget _buildBadge(String text, bool isTouched) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondary,
          fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    opinionColors = {
      "positive": Theme.of(context).colorScheme.tertiary,
      "negative": Theme.of(context).colorScheme.primary,
      "neutral": Theme.of(context).colorScheme.secondary,
      "not known": Colors.grey,
    };
    return VisibilityDetector(
      key: const Key('dashboard-visibility'),
      onVisibilityChanged: (visibilityInfo) {
        final visibleFraction = visibilityInfo.visibleFraction;
        if (visibleFraction > 0 && !_hasFetched) {
          getProjectStats(widget.projectName);
          _hasFetched = true;
        } else if (visibleFraction == 0.0) {
          _hasFetched = false;
        }
      },
      child: _buildDashboard(),
    );
  }
}
