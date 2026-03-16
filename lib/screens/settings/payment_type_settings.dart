import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/providers/payment_type_provider.dart';
import '/theme/theme.dart';

class PaymentTypeSettingsScreen extends ConsumerStatefulWidget {
  const PaymentTypeSettingsScreen({super.key});

  @override
  ConsumerState<PaymentTypeSettingsScreen> createState() =>
      _PaymentTypeSettingsScreenState();
}

class _PaymentTypeSettingsScreenState
    extends ConsumerState<PaymentTypeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final paymentTypes = ref.watch(paymentTypeProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Text(
          "Payments Types",
          style: AppTheme.textTitle(
            context,
          ).copyWith(fontSize: 20, fontFamily: AppFontFamily.poppinsLight),
        ),
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: paymentTypes.length,
        itemBuilder: (context, index) {
          final type = paymentTypes[index];
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: index == 0 ? 0 : 2,
              bottom: index == paymentTypes.length - 1 ? 0 : 2,
            ),
            child: Card(
              color: AppTheme.cardBg(context),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: CheckboxListTile(
                activeColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColor.neutral_70
                    : AppColor.neutral_20,
                checkColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColor.neutral_20
                    : AppColor.neutral_70,
                selectedTileColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColor.neutral_70
                    : AppColor.neutral_20,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                value: type.isVisible,
                onChanged: (_) {
                  ref
                      .read(paymentTypeProvider.notifier)
                      .togglePaymentType(type.name);
                },
                controlAffinity: ListTileControlAffinity.leading,
                secondary: (type.isIcon)
                    ? Icon(
                        type.icon,
                        size: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutral_70
                            : AppColor.neutral_20,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: EdgeInsets.all(3),
                          color: AppColor.white,
                          child: Image.asset(
                            type.imageUrl,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                title: Text(
                  type.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontFamily: AppFontFamily.poppinsSemiBold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
