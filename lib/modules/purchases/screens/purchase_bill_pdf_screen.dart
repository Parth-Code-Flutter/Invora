import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/business_profile_model.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../data/services/purchase_bill_pdf_service.dart';

class PurchaseBillPdfArgs {
  const PurchaseBillPdfArgs.saved(this.billId) : bill = null;
  const PurchaseBillPdfArgs.draft(this.bill) : billId = null;

  final int? billId;
  final PurchaseBillModel? bill;
}

class PurchaseBillPdfScreen extends StatefulWidget {
  const PurchaseBillPdfScreen({super.key});

  @override
  State<PurchaseBillPdfScreen> createState() => _PurchaseBillPdfScreenState();
}

class _PurchaseBillPdfScreenState extends State<PurchaseBillPdfScreen> {
  final _pdf = Get.find<PurchaseBillPdfService>();
  PurchaseBillModel? bill;
  BusinessProfileModel? business;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final args = Get.arguments;
      PurchaseBillModel? current;
      if (args is PurchaseBillPdfArgs && args.bill != null) {
        current = args.bill;
      } else {
        final id = args is PurchaseBillPdfArgs ? args.billId : args as int?;
        if (id != null) {
          current = await Get.find<PurchaseRepository>().getBill(id);
        }
      }
      final profile = await Get.find<BusinessRepository>().getProfile();
      if (!mounted) return;
      if (current == null) {
        setState(() {
          error = 'This purchase bill was not found.';
          loading = false;
        });
        return;
      }
      if (profile == null || profile.businessName.trim().isEmpty) {
        setState(() {
          bill = current;
          error = 'Complete business setup before generating a PDF.';
          loading = false;
        });
        return;
      }
      setState(() {
        bill = current;
        business = profile;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = bill;
    final profile = business;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: AppBarTitle(
          current?.billNumber ?? 'Purchase bill PDF',
          subtitle: 'Document',
        ),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Save PDF'),
            onPressed: current == null || profile == null ? null : _save,
            icon: Icons.download_outlined,
          ),
          AppBarIconButton(
            tooltip: l10n('Share PDF'),
            onPressed: current == null || profile == null ? null : _share,
            icon: Icons.share_outlined,
          ),
          AppBarIconButton(
            tooltip: l10n('Print'),
            onPressed: current == null || profile == null ? null : _print,
            icon: Icons.print_outlined,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, textAlign: TextAlign.center),
              ),
            )
          : PdfPreview(
              build: (_) => _pdf.build(bill: current!, business: profile!),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
            ),
    );
  }

  Future<void> _save() async {
    try {
      await _pdf.saveBill(bill: bill!, business: business!);
    } catch (e) {
      AppNotification.error('Could not save PDF', e.toString());
    }
  }

  Future<void> _share() async {
    try {
      await _pdf.shareBill(bill: bill!, business: business!);
    } catch (e) {
      AppNotification.error('Could not share PDF', e.toString());
    }
  }

  Future<void> _print() async {
    try {
      await _pdf.printBill(bill: bill!, business: business!);
    } catch (e) {
      AppNotification.error('Could not print PDF', e.toString());
    }
  }
}
