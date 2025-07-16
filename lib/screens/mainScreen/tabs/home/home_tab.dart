import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import '../../../../shared/components/kg_button.dart';

class LucyTab extends StatefulWidget {
  const LucyTab({super.key});

  @override
  State<LucyTab> createState() => _LucyTabState();
}

class _LucyTabState extends State<LucyTab> with AutomaticKeepAliveClientMixin {

  bool launchMailError = false;

  double consumesVariation = -12;
  double costsVariation = 47;
  double consumes = 37.46;
  double costs = 15.22;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30),
      child: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 30, top: 40),
            child: SvgPicture.asset("assets/icons/onBoarding/onBoarding1.svg",
              height: MediaQuery.of(context).size.height * 0.3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              "Installa Lucy Smart Meter a 5€/mese e monitora i consumi quotidiani della tua casa",
              style: KlimmeckGuideTheme.instance.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Mediamente con Lucy Smart Meter si risparmia 8,64€/mese",
              style: KlimmeckGuideTheme.instance.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
              child: KGButton(text: "Invia mail", onTap: () => {})),
          if(launchMailError)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                "Errore invio mail!",
                style: KlimmeckGuideTheme.instance.errorText,
                textAlign: TextAlign.center,
              ),
            ),
          const Spacer()
        ],
      ),
    );
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget label(String label, double variation) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      decoration: KlimmeckGuideTheme.getDarkDungeonBackground(),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Text(
                "$label ",
                style: KlimmeckGuideTheme.instance.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
            Text("${variation > 0 ? "+" : ""}$variation %",
                style: KlimmeckGuideTheme.instance.bodyMedium,
                textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
