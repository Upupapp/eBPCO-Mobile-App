import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The citizen portal's printable documents (`.doc-generated-*` in its
/// styles.scss) as widgets: an A4 page that looks like paper, not like an app
/// card — serif body, black rules, uppercase headings, dotted field rows, a
/// signature line and a faint watermark. The permit and the receipt are drawn
/// from these, so both apps show the citizen the same document.
///
/// On a phone the page reflows to the screen's width and scrolls, as the
/// portal's does under 840 px (design review I1, 4 Nov 2026: a scaled-down
/// A4 page was unreadable, and the portal's cut off): one field to a line,
/// nothing wider than the screen. On a tablet it keeps its real proportions
/// (A4 at 96 dpi), scaled to the width, and can be pinched to read.

/// A4 at 96 dpi.
const double _pageWidth = 794;
const double _pageMinHeight = 1123;

/// Below this width the page reflows instead of being scaled: the portal's breakpoint.
const double paperReflowWidth = 840;

const Color _ink = Color(0xFF1A1A1A);
const Color _muted = Color(0xFF5A5A5A);

/// Pending and placeholder text: upright, in the portal's #6b7080 (design
/// review I12: pale italic read as a fault).
const Color _pending = Color(0xFF6B7080);

/// A plain fact in body ink ("No conditions were recorded by the office.").
const Color _bodyInk = Color(0xFF454A58);
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

/// Whether the paper widgets below lay out for a phone ([PaperDocumentViewer]
/// under [paperReflowWidth]): the page as wide as the screen, one field to a
/// line. A4 when there is no viewer above them.
class PaperLayout extends InheritedWidget {
  const PaperLayout({super.key, required this.compact, required super.child});

  final bool compact;

  static bool compactOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaperLayout>()?.compact ?? false;

  @override
  bool updateShouldNotify(PaperLayout oldWidget) => compact != oldWidget.compact;
}

/// Shows [page]: reflowed and scrolling on a phone; on a wider screen fitted
/// to the width, scrollable and pinch-zoomable.
class PaperDocumentViewer extends StatelessWidget {
  final Widget page;
  const PaperDocumentViewer({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < paperReflowWidth) {
          return Scrollbar(
            child: SingleChildScrollView(
              key: const ValueKey('paper-scroll'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              child: PaperLayout(compact: true, child: page),
            ),
          );
        }
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
    final compact = PaperLayout.compactOf(context);
    return Container(
      width: compact ? null : _pageWidth,
      constraints: compact ? null : const BoxConstraints(minHeight: _pageMinHeight),
      // A4: 16mm top/bottom, 18mm sides. A phone: the portal's 20px / 16px.
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
          : const EdgeInsets.symmetric(horizontal: 68, vertical: 60),
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
                      // Scaled down to fit a phone-width page, never cut off.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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
          // Flexible, so a long office name wraps on a phone instead of running off the page.
          Flexible(
            child: Column(
              children: [
                Text('Republic of the Philippines', textAlign: TextAlign.center, style: line),
                Text(
                  _isBfp ? 'Department of the Interior and Local Government' : 'Province of Sorsogon',
                  textAlign: TextAlign.center,
                  style: line,
                ),
                Text(
                  _isBfp ? 'Bureau of Fire Protection' : 'Municipality of Castilla',
                  textAlign: TextAlign.center,
                  style: _sans.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                Text(office, textAlign: TextAlign.center, style: _sans.copyWith(fontSize: 11.5, color: _muted)),
              ],
            ),
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
              // Flexible: on a narrow phone, or with large text, the number wraps instead of running off the page.
              Flexible(
                child: Text(
                  value,
                  style: pending
                      ? _serif.copyWith(fontSize: 15, color: _pending)
                      : _sans.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
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

/// Label / value pairs over dotted lines: two to a row on A4, a [wide] one
/// (an address, the occupancy) on a row of its own; one to a line on a phone.
class PaperFields extends StatelessWidget {
  final List<(String, String)> rows;

  /// The labels whose row takes the full width of the page.
  final Set<String> wide;
  const PaperFields({super.key, required this.rows, this.wide = const {}});

  @override
  Widget build(BuildContext context) {
    final compact = PaperLayout.compactOf(context);
    Widget line(List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );
    final lines = <Widget>[];
    (String, String)? waiting;
    void flush() {
      if (waiting case (final label, final value)) {
        lines.add(line([
          Expanded(child: _PaperField(label: label, value: value)),
          const SizedBox(width: 24),
          const Expanded(child: SizedBox()),
        ]));
        waiting = null;
      }
    }

    for (final row in rows) {
      if (compact || wide.contains(row.$1)) {
        flush();
        lines.add(line([Expanded(child: _PaperField(label: row.$1, value: row.$2))]));
      } else if (waiting case (final label, final value)) {
        lines.add(line([
          Expanded(child: _PaperField(label: label, value: value)),
          const SizedBox(width: 24),
          Expanded(child: _PaperField(label: row.$1, value: row.$2)),
        ]));
        waiting = null;
      } else {
        waiting = row;
      }
    }
    flush();
    return Column(children: lines);
  }
}

class _PaperField extends StatelessWidget {
  final String label;
  final String value;
  const _PaperField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final missing = value == 'Not on file' ||
        value == 'Not provided' ||
        value == 'Pending' ||
        value == 'Not yet assigned' ||
        value == 'Not recorded';
    return CustomPaint(
      painter: const _DottedUnderline(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Never wider than two fifths of the line, so a long label wraps rather than overflows.
            Flexible(flex: 2, child: Text(label, style: _sans.copyWith(fontSize: 11.5, color: _muted))),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: missing ? _serif.copyWith(color: _pending) : _serif.copyWith(fontWeight: FontWeight.w600),
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

/// A ruled table. A row whose second field is true is set in bold. Every
/// column after the first holds an amount and is right-aligned (design
/// review I12).
class PaperTable extends StatelessWidget {
  final List<String>? header;
  final List<(List<String>, bool)> rows;
  const PaperTable({super.key, this.header, required this.rows});

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool bold = false, bool head = false}) => TableRow(
          decoration: head ? const BoxDecoration(color: Color(0xFFF2F2F2)) : null,
          children: [
            for (final (i, cell) in cells.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  head ? cell.toUpperCase() : cell,
                  textAlign: i == 0 ? TextAlign.left : TextAlign.right,
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

/// Plain paragraph text at the document's note size; a [placeholder] (what
/// is not there yet) upright in #6b7080, and a [fact] (none recorded) in
/// body ink — never pale italic (design review I3, I12).
class PaperNote extends StatelessWidget {
  final String text;
  final bool placeholder;
  final bool fact;
  const PaperNote(this.text, {super.key, this.placeholder = false, this.fact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        text,
        style: fact
            ? _serif.copyWith(fontSize: 12.5, color: _bodyInk)
            : placeholder
                ? _serif.copyWith(fontSize: 12.5, color: _pending)
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
    // 320 px: the office's full name fits on two lines with no word left
    // alone on the last (design review I12); narrower on a phone if need be.
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
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
                            textAlign: TextAlign.center,
                            style: _serif.copyWith(fontSize: 11.5, color: _pending),
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

/// The verification QR code, or why there is none yet. The caption names the
/// address on one line and the [number] whole on the next, so both can be
/// read and typed (design review I12).
class PaperQr extends StatelessWidget {
  final String? url;
  final String? number;
  final String unavailable;
  const PaperQr({super.key, required this.url, this.number, required this.unavailable});

  /// "Scan to verify at citizen.castilla-ebpco.online/verify/".
  static String captionFor(String url) => 'Scan to verify at ${Uri.parse(url).authority}/verify/';

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
              width: 260,
              child: Text.rich(
                TextSpan(
                  text: captionFor(url!),
                  children: [
                    if (number != null) ...[
                      const TextSpan(text: '\n'),
                      TextSpan(text: number, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
                textAlign: TextAlign.center,
                style: caption,
              ),
            ),
          ] else
            SizedBox(
              width: 200,
              child: Text(unavailable, textAlign: TextAlign.center, style: caption.copyWith(color: _pending)),
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
              child: Text(line, textAlign: TextAlign.center, style: _sans.copyWith(fontSize: 10, color: _pending)),
            ),
        ],
      ),
    );
  }
}
