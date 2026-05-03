import 'package:flutter/material.dart';

class TeamCreatorRosterStep extends StatelessWidget {
  const TeamCreatorRosterStep({
    super.key,
    required this.isWide,
    required this.loadingRaceDetail,
    required this.header,
    required this.identityPanel,
    required this.recruitmentTable,
    required this.starPlayersSection,
    required this.staffPanel,
    required this.rosterStatus,
  });

  final bool isWide;
  final bool loadingRaceDetail;
  final Widget header;
  final Widget identityPanel;
  final Widget recruitmentTable;
  final Widget starPlayersSection;
  final Widget staffPanel;
  final Widget rosterStatus;

  @override
  Widget build(BuildContext context) {
    if (loadingRaceDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Padding(
          padding:
              EdgeInsets.fromLTRB(isWide ? 32 : 16, 24, isWide ? 32 : 16, 32),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 280,
                      child: Column(
                        children: [identityPanel],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          recruitmentTable,
                          const SizedBox(height: 16),
                          starPlayersSection,
                          const SizedBox(height: 16),
                          staffPanel,
                          const SizedBox(height: 16),
                          rosterStatus,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    recruitmentTable,
                    const SizedBox(height: 16),
                    starPlayersSection,
                    const SizedBox(height: 16),
                    staffPanel,
                    const SizedBox(height: 16),
                    rosterStatus,
                  ],
                ),
        ),
      ],
    );
  }
}
