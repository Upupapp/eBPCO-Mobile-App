import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The citizen portal's printable documents (`.doc-generated-*` in its
/// styles.scss) as widgets: an A4 page that looks like paper, not like an app
/// card — serif body, black rules, uppercase headings, dotted field rows, a
/// signature line and a faint watermark. The permit and the receipt are drawn
/// from these, so both apps show the citizen the same document.
///
/// The page keeps its real proportions (A4 at 96 dpi) and is scaled to the
/// phone's width; [PaperDocumentViewer] lets the citizen pinch to read it.

/// A4 at 96 dpi.
const double _pageWidth = 794;
const double _pageMinHeight = 1123;

const Color _ink = Color(0xFF1A1A1A);
const Color _muted = Color(0xFF5A5A5A);
const Color _faint = Color(0xFF8A8A8A);
const Color _rule = Color(0xFF000000);
const Color _tableRule = Color(0xFF333333);
const Color _dots = Color(0xFFB0B0B0);

/// Georgia first, like the portal; the platform serif otherwise.
const _serif = TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: ['Times New Roman', 'serif', 'Noto Serif'],
  color: _ink,
  fontSize: 14, // 10.5pt
  height: 1.45,
);

/// Arial-like, for labels and headings — the portal's `Arial, Helvetica`.
const _sans = TextStyle(
  fontFamily: 'Arial',
  fontFamilyFallback: ['Helvetica', 'sans-serif', 'Roboto'],
  color: _ink,
  height: 1.3,
);

/// Shows [page] fitted to the screen's width, scrollable and pinch-zoomable.
class PaperDocumentViewer extends StatelessWidget {
  final Widget page;
  const PaperDocumentViewer({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 24;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.pinch_outlined, size: 16, color: _muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pinch to zoom in on the document.',
                      style: _sans.copyWith(fontSize: 12, color: _muted),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                minScale: 1,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.only(bottom: 40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                  child: SizedBox(
                    width: width,
                    child: FittedBox(fit: BoxFit.fitWidth, alignment: Alignment.topCenter, child: page),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One sheet of paper, with an optional diagonal watermark over everything.
class PaperPage extends StatelessWidget {
  final List<Widget> children;
  final String? watermark;
  const PaperPage({super.key, required this.children, this.watermark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _pageWidth,
      constraints: const BoxConstraints(minHeight: _pageMinHeight),
      // 16mm top/bottom, 18mm sides.
      padding: const EdgeInsets.symmetric(horizontal: 68, vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D0D0)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: DefaultTextStyle(
        style: _serif,
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            if (watermark != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.5236, // -30°
                      child: Text(
                        watermark!.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        style: _sans.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: const Color(0x2E961414),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Republic / Province / Municipality — or the DILG / BFP lines for a Bureau
/// of Fire Protection document — over a heavy rule, like the portal's
/// `agencyHeaderFor`.
class PaperHeader extends StatelessWidget {
  final String office;
  const PaperHeader({super.key, required this.office});

  bool get _isBfp => RegExp('fire protection|bfp', caseSensitive: false).hasMatch(office);

  @override
  Widget build(BuildContext context) {
    final line = _sans.copyWith(fontSize: 12);
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _rule, width: 2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/ebpco_seal.png', width: 52, height: 52, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Column(
            children: [
              Text('Republic of the Philippines', style: line),
              Text(_isBfp ? 'Department of the Interior and Local Government' : 'Province of Sorsogon', style: line),
              Text(
                _isBfp ? 'Bureau of Fire Protection' : 'Municipality of Castilla',
                style: _sans.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              Text(office, style: _sans.copyWith(fontSize: 11.5, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class PaperTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const PaperTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: _serif.copyWith(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: _sans.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.75, color: _muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// The boxed number line: the document's own number, then its dates.
class PaperNumberBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool pending;
  final List<(String, String)> facts;
  const PaperNumberBlock({super.key, required this.label, required this.value, this.pending = false, required this.facts});

  @override
  Widget build(BuildContext context) {
    final small = _sans.copyWith(fontSize: 11.5, color: _muted);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: _rule)),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label.toUpperCase(), style: small.copyWith(letterSpacing: 0.4)),
              const SizedBox(width: 8),
              Text(
                value,
                style: pending
                    ? _serif.copyWith(fontSize: 15, fontStyle: FontStyle.italic, color: _faint)
                    : _sans.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ],
          ),
          Wrap(
            spacing: 20,
            runSpacing: 2,
            children: [
              for (final (name, fact) in facts)
                Text.rich(
                  TextSpan(
                    text: '$name: ',
                    style: small,
                    children: [TextSpan(text: fact, style: small.copyWith(color: _ink, fontWeight: FontWeight.w700))],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An uppercase heading over a rule, then its content.
class PaperSection extends StatelessWidget {
  final String title;
  final Widget child;
  const PaperSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 3),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _rule))),
            child: Text(
              title.toUpperCase(),
              style: _sans.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Label / value pairs, two to a row, each over a dotted line.
class PaperFields extends StatelessWidget {
  final List<(String, String)> rows;
  const PaperFields({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final pairs = <Widget>[];
    for (var i = 0; i < rows.length; i += 2) {
      pairs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PaperField(label: rows[i].$1, value: rows[i].$2)),
              const SizedBox(width: 24),
              Expanded(child: i + 1 < rows.length ? _PaperField(label: rows[i + 1].$1, value: rows[i + 1].$2) : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: pairs);
  }
}

class _PaperField extends StatelessWidget {
  final String label;
  final String value;
  const _PaperField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Not on file' || value == 'Not provided' || value == 'Pending' || value == 'Not yet assigned';
    return CustomPaint(
      painter: const _DottedUnderline(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _sans.copyWith(fontSize: 11.5, color: _muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: missing
                    ? _serif.copyWith(fontStyle: FontStyle.italic, color: _faint)
                    : _serif.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedUnderline extends CustomPainter {
  const _DottedUnderline();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _dots
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 3) {
      canvas.drawLine(Offset(x, size.height - 0.5), Offset(x + 1, size.height - 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A ruled table. A row whose third field is true is set in bold.
class PaperTable extends StatelessWidget {
  final List<String>? header;
  final List<(List<String>, bool)> rows;
  const PaperTable({super.key, this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool bold = false, bool head = false}) => TableRow(
          decoration: head ? const BoxDecoration(color: Color(0xFFF2F2F2)) : null,
          children: [
            for (final cell in cells)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  head ? cell.toUpperCase() : cell,
                  style: head
                      ? _sans.copyWith(fontSize: 10.5, letterSpacing: 0.3, fontWeight: FontWeight.w700)
                      : _serif.copyWith(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
                ),
              ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Table(
        border: TableBorder.all(color: _tableRule),
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
        children: [
          if (header != null) row(header!, head: true),
          for (final (cells, bold) in rows) row(cells, bold: bold),
        ],
      ),
    );
  }
}

/// Plain paragraph text at the document's note size.
class PaperNote extends StatelessWidget {
  final String text;
  final bool placeholder;
  const PaperNote(this.text, {super.key, this.placeholder = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        text,
        style: placeholder
            ? _serif.copyWith(fontSize: 12.5, fontStyle: FontStyle.italic, color: _faint)
            : _sans.copyWith(fontSize: 11.5, color: _muted),
      ),
    );
  }
}

/// A numbered list, for a permit's conditions.
class PaperNumberedList extends StatelessWidget {
  final List<String> items;
  const PaperNumberedList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 22, child: Text('${i + 1}.', style: _serif.copyWith(fontSize: 12.5))),
                  Expanded(child: Text(item, style: _serif.copyWith(fontSize: 12.5, height: 1.5))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A signature line with the signatory beneath it.
class PaperSignature extends StatelessWidget {
  final String heading;
  final String? pendingLabel;
  final String name;
  final String? position;
  const PaperSignature({super.key, required this.heading, this.pendingLabel, required this.name, this.position});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Center(
        child: SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                heading.toUpperCase(),
                style: _sans.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              SizedBox(
                height: 48,
                child: pendingLabel == null
                    ? null
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            pendingLabel!,
                            style: _serif.copyWith(fontSize: 11.5, fontStyle: FontStyle.italic, color: _faint),
                          ),
                        ),
                      ),
              ),
              Container(height: 1, color: _rule),
              const SizedBox(height: 5),
              Text(name, textAlign: TextAlign.center, style: _serif.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700)),
              if (position != null)
                Text(position!, textAlign: TextAlign.center, style: _sans.copyWith(fontSize: 10.5, color: _muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The verification QR code, or why there is none yet.
class PaperQr extends StatelessWidget {
  final String? url;
  final String unavailable;
  const PaperQr({super.key, required this.url, required this.unavailable});

  @override
  Widget build(BuildContext context) {
    final caption = _sans.copyWith(fontSize: 9.5, color: _muted);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          if (url != null) ...[
            Container(
              decoration: BoxDecoration(border: Border.all(color: _tableRule)),
              child: QrImageView(data: url!, size: 78, padding: const EdgeInsets.all(3), backgroundColor: Colors.white),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 220,
              child: Text('Scan to verify this document at\n$url', textAlign: TextAlign.center, style: caption),
            ),
          ] else
            SizedBox(
              width: 200,
              child: Text(unavailable, textAlign: TextAlign.center, style: caption.copyWith(fontStyle: FontStyle.italic, color: _faint)),
            ),
        ],
      ),
    );
  }
}

/// The small print under a rule at the foot of the page.
class PaperFooter extends StatelessWidget {
  final List<String> lines;
  const PaperFooter({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _tableRule))),
      child: Column(
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line, textAlign: TextAlign.center, style: _sans.copyWith(fontSize: 10, color: _faint)),
            ),
        ],
      ),
    );
  }
}
