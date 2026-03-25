import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/Models/item_location_model.dart';
import '/theme/theme.dart';

class ItemLocationSearchFieldGlobal extends StatefulWidget {
  final List<ItemLocationModel> itemLocation;
  final ItemLocationModel? selectedItemLocation;
  final Function(ItemLocationModel) onSelected;

  const ItemLocationSearchFieldGlobal({
    super.key,
    required this.itemLocation,
    this.selectedItemLocation,
    required this.onSelected,
  });

  @override
  State<ItemLocationSearchFieldGlobal> createState() =>
      _ItemLocationSearchFieldGlobalState();
}

class _ItemLocationSearchFieldGlobalState
    extends State<ItemLocationSearchFieldGlobal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<ItemLocationModel> _filtered = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _filtered = widget.itemLocation;

    // Set selected item location if available
    if (widget.selectedItemLocation != null) {
      _controller.text = widget.selectedItemLocation!.LocationName;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.addListener(() {
      final query = _controller.text.toLowerCase();
      _filtered = widget.itemLocation.where((cust) {
        return cust.LocationName.toLowerCase().contains(query);
      }).toList();
      _updateOverlay();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), _showOverlay);
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_focusNode.hasFocus) _removeOverlay();
        });
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
  }

  void _removeOverlay() async {
    if (_overlayEntry != null) {
      await _animController.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void didUpdateWidget(covariant ItemLocationSearchFieldGlobal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedItemLocation != null &&
        widget.selectedItemLocation != oldWidget.selectedItemLocation) {
      _controller.text = widget.selectedItemLocation!.LocationName;
    }

    _filtered = widget.itemLocation;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                    child: _filtered.isNotEmpty
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final cust = _filtered[index];
                                return InkWell(
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        _controller.text = cust.LocationName;
                                        widget.onSelected(cust);
                                        _focusNode.unfocus();
                                        _removeOverlay();
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: Text(
                                      (index + 1).toString().padLeft(2, '0'),
                                      style: const TextStyle(
                                        fontFamily: AppFontFamily.poppinsMedium,
                                      ),
                                    ),
                                    title: Text(
                                      cust.LocationName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.textLabel(context)
                                          .copyWith(
                                            fontFamily:
                                                AppFontFamily.poppinsSemiBold,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Select Scrap Item Location*',
              hintText: 'Search by location name',
              counter: const SizedBox.shrink(),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                child: Icon(HugeIconsSolid.locationUser03),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(HugeIconsSolid.arrowDown01),
                      onPressed: () {
                        FocusScope.of(context).requestFocus(_focusNode);
                        _filtered = widget.itemLocation;
                        _updateOverlay();
                      },
                    ),
                  ),
                ],
              ),
            ),
            style: AppInputDecoration.inputTextStyle(context),
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Scrap Item Location Required';
              } else if (!RegExp(r'^[a-zA-Z&()/ ]+$').hasMatch(value)) {
                return 'Must contain only letters';
              }
              return null;
            },
            maxLength: 20,
          ),
        ],
      ),
    );
  }
}
