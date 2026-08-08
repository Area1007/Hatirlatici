import 'package:flutter/material.dart';

import 'ai_reminder_service.dart';
import 'core/app_colors.dart';
import 'core/app_spacing.dart';
import 'core/app_text_styles.dart';

class QuickReminderAction {
  final AiReminderResult result;
  final bool detaylariDuzenle;

  const QuickReminderAction({
    required this.result,
    required this.detaylariDuzenle,
  });
}

class QuickReminderScreen extends StatefulWidget {
  const QuickReminderScreen({super.key});

  @override
  State<QuickReminderScreen> createState() => _QuickReminderScreenState();
}

class _QuickReminderScreenState extends State<QuickReminderScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  AiReminderResult? _sonuc;
  bool _analizEdiliyor = false;
  String? _hata;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _karakterEkle(String karakter) {
    final TextEditingValue value = _controller.value;
    final TextSelection selection = value.selection;

    final int start = selection.isValid ? selection.start : value.text.length;
    final int end = selection.isValid ? selection.end : value.text.length;

    final String yeniMetin = value.text.replaceRange(
      start,
      end,
      karakter,
    );

    final int yeniKonum = start + karakter.length;

    _controller.value = TextEditingValue(
      text: yeniMetin,
      selection: TextSelection.collapsed(offset: yeniKonum),
    );

    _focusNode.requestFocus();
  }

  Future<void> _analizEt() async {
    final String metin = _controller.text.trim();

    if (metin.isEmpty) {
      setState(() {
        _hata = 'Önce neyi hatırlatmam gerektiğini yaz.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _analizEdiliyor = true;
      _hata = null;
      _sonuc = null;
    });

    try {
      final AiReminderResult sonuc =
          await AiReminderService.analizEt(metin);

      if (!mounted) return;

      setState(() {
        _sonuc = sonuc;
        _analizEdiliyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _analizEdiliyor = false;
        _hata =
            'AI servisine ulaşılamadı.\n\n'
            'Backend açık mı kontrol et.\n'
            'Hata: $e';
      });
    }
  }

  String _tarihYazisi(DateTime tarih) {
    final DateTime now = DateTime.now();
    final DateTime bugun = DateTime(now.year, now.month, now.day);
    final DateTime hedef = DateTime(tarih.year, tarih.month, tarih.day);
    final int fark = hedef.difference(bugun).inDays;

    if (fark == 0) return 'Bugün';
    if (fark == 1) return 'Yarın';
    if (fark == 2) return 'Öbür gün';

    const List<String> aylar = <String>[
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${tarih.day} ${aylar[tarih.month]} ${tarih.year}';
  }

  String _saatYazisi(AiReminderResult sonuc) {
    return '${sonuc.saat.toString().padLeft(2, '0')}:'
        '${sonuc.dakika.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color surface = AppColors.surface(brightness);
    final Color border = AppColors.border(brightness);
    final Color primaryText = AppColors.textPrimary(brightness);
    final Color secondaryText = AppColors.textSecondary(brightness);
    final Color mutedText = AppColors.textMuted(brightness);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Hızlı Hatırlatıcı'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            24,
            AppSpacing.screenHorizontal,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ne hatırlatayım?',
                style: AppTextStyles.screenTitle.copyWith(
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Doğal bir cümle yaz. Tarih ve saati AI senin için ayarlasın.',
                style: AppTextStyles.body.copyWith(
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: border.withValues(alpha: 0.7),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  enableSuggestions: true,
                  autocorrect: true,
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_analizEdiliyor) {
                      _analizEt();
                    }
                  },
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Örn. Yarın saat 5te toplantı',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: mutedText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <String>[
                  'Yarın saat 5te toplantı',
                  'Cuma 14:30 ders',
                  '2 saat sonra annemi ara',
                ].map((String ornek) {
                  return ActionChip(
                    label: Text(ornek),
                    onPressed: () {
                      _controller.text = ornek;
                      _controller.selection =
                          TextSelection.collapsed(offset: ornek.length);
                      _focusNode.requestFocus();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _analizEdiliyor ? null : _analizEt,
                  icon: _analizEdiliyor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _analizEdiliyor
                        ? 'AI analiz ediyor...'
                        : 'AI ile Oluştur',
                  ),
                ),
              ),
              if (_hata != null) ...<Widget>[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.overdue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.overdue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _hata!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.overdue,
                    ),
                  ),
                ),
              ],
              if (_sonuc != null) ...<Widget>[
                const SizedBox(height: 28),
                Text(
                  'AI önerisi',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                _sonucKarti(context, _sonuc!),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        QuickReminderAction(
                          result: _sonuc!,
                          detaylariDuzenle: false,
                        ),
                      );
                    },
                    child: const Text('Hatırlatıcıyı Oluştur'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        QuickReminderAction(
                          result: _sonuc!,
                          detaylariDuzenle: true,
                        ),
                      );
                    },
                    child: const Text('Ayrıntıları Düzenle'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sonucKarti(
    BuildContext context,
    AiReminderResult sonuc,
  ) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color surface = AppColors.surface(brightness);
    final Color border = AppColors.border(brightness);
    final Color primaryText = AppColors.textPrimary(brightness);
    final Color secondaryText = AppColors.textSecondary(brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sonuc.baslik,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: primaryText,
                    fontSize: 19,
                  ),
                ),
              ),
            ],
          ),
          if (sonuc.aciklama.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              sonuc.aciklama,
              style: AppTextStyles.body.copyWith(
                color: secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _bilgiChip(
                context,
                Icons.calendar_today_outlined,
                _tarihYazisi(sonuc.tarih),
              ),
              _bilgiChip(
                context,
                Icons.schedule_rounded,
                _saatYazisi(sonuc),
              ),
              if (sonuc.tekrar != 'Yok')
                _bilgiChip(
                  context,
                  Icons.repeat_rounded,
                  sonuc.tekrar,
                ),
              _bilgiChip(
                context,
                Icons.flag_outlined,
                sonuc.oncelik,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bilgiChip(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    final Brightness brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.metadata.copyWith(
              color: AppColors.textSecondary(brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
