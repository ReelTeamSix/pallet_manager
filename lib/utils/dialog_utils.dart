import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pallet_model.dart';
import '../responsive_utils.dart';
// Import app theme
import '../theme/theme_extensions.dart'; // Import theme extensions

/// A utility class for common dialog operations across the app
/// This reduces code duplication in multiple screens
class DialogUtils {
  /// Shows a dialog to add a new pallet
  /// Used in both HomeScreen and InventoryScreen
  static void showAddPalletDialog(BuildContext context) {
    final palletModel = Provider.of<PalletModel>(context, listen: false);

    // Set default name "Pallet X" based on the next ID
    final int nextId = palletModel.getNextPalletId();
    final nameController = TextEditingController(text: "Pallet $nextId");
    final tagController = TextEditingController();
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Function to show tag selection in a bottom sheet
    void showTagSelector() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          // Directly access the model inside the builder for freshest data
          final tagsToShow =
              Provider.of<PalletModel>(context).savedTags.toList();

          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select a Tag",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Show tags or a message if empty
                tagsToShow.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No tags available"),
                      )
                    : Container(
                        height: 200, // Fixed height container
                        child: ListView.builder(
                          itemCount: tagsToShow.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(Icons.label),
                              title: Text(tagsToShow[index]),
                              onTap: () {
                                tagController.text = tagsToShow[index];
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),

                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("CLOSE", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Function to handle form submission
    void submitForm() {
      if (formKey.currentState!.validate()) {
        final name = nameController.text;
        final tag = tagController.text.trim();
        final cost = double.tryParse(costController.text) ?? 0.0;

        Provider.of<PalletModel>(context, listen: false).addPallet(
          Pallet(
            id: Provider.of<PalletModel>(context, listen: false)
                .generatePalletId(),
            name: name,
            tag: tag,
            totalCost: cost,
            date: DateTime.now(),
          ),
        );
        Navigator.pop(context);
      }
    }

    // Show the dialog with keyboard awareness
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Pallet",
            style: context.largeTextWeight(FontWeight.bold)),
        content: KeyboardAware(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Pallet Name",
                      border: OutlineInputBorder(),
                      contentPadding: ResponsiveUtils.getPaddingHV(
                          context, PaddingType.small, PaddingType.small),
                      prefixIcon: Icon(
                        Icons.inventory_2_outlined,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.medium),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter pallet name";
                      }
                      if (palletModel.palletNameExists(value)) {
                        return "A pallet with this name already exists";
                      }
                      return null;
                    },
                    style: context.mediumText,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getPadding(
                              context, PaddingType.medium)
                          .top),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tagController,
                          decoration: InputDecoration(
                            labelText: "Tag",
                            border: OutlineInputBorder(),
                            contentPadding: ResponsiveUtils.getPaddingHV(
                                context, PaddingType.small, PaddingType.small),
                            prefixIcon: Icon(
                              Icons.sell_outlined,
                              size: ResponsiveUtils.getIconSize(
                                  context, IconSizeType.medium),
                            ),
                          ),
                          style: context.mediumText,
                          readOnly: false, // Allow direct editing too
                        ),
                      ),
                      if (palletModel.savedTags.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.list,
                            size: ResponsiveUtils.getIconSize(
                                context, IconSizeType.medium),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: ResponsiveUtils.getIconSize(
                                    context, IconSizeType.medium) +
                                12,
                            minHeight: ResponsiveUtils.getIconSize(
                                    context, IconSizeType.medium) +
                                12,
                          ),
                          tooltip: "Select saved tag",
                          onPressed: showTagSelector,
                        ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getPadding(
                              context, PaddingType.medium)
                          .top),
                  TextFormField(
                    controller: costController,
                    decoration: InputDecoration(
                      labelText: "Total Cost",
                      prefixIcon: Icon(
                        Icons.attach_money,
                        size: ResponsiveUtils.getIconSize(
                            context, IconSizeType.medium),
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: ResponsiveUtils.getPaddingHV(
                          context, PaddingType.small, PaddingType.small),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter cost";
                      }
                      if (double.tryParse(value) == null) {
                        return "Enter a valid number";
                      }
                      return null;
                    },
                    style: context.mediumText,
                    onEditingComplete: submitForm, // Submit on keyboard done
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: context.mediumText),
            style: TextButton.styleFrom(
              minimumSize: Size(60, 36),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: submitForm,
            child: Text("ADD", style: context.mediumText),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              minimumSize: Size(60, 36),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a tag filter dialog
  /// Used in both InventoryScreen and AnalyticsScreen
  static void showTagFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // This causes the dialog to rebuild whenever the model changes
        return Consumer<PalletModel>(
          builder: (context, palletModel, child) {
            // Get a direct copy of the tags within the Consumer builder
            final List<String> tagsList = palletModel.savedTags.toList();

            return AlertDialog(
              title: Text("Filter by Tag",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // All option
                    ListTile(
                      leading:
                          Icon(Icons.all_inclusive, color: context.accentColor),
                      title: Text("All",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: palletModel.currentTagFilter == null,
                      tileColor: palletModel.currentTagFilter == null
                          ? context.accentColor.withOpacity(0.2)
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onTap: () {
                        palletModel.setTagFilter(null);
                        Navigator.pop(context);
                      },
                    ),

                    // Build tag list items dynamically from saved tags
                    ...tagsList
                        .map((tag) => ListTile(
                              leading: Icon(Icons.label,
                                  color: context.primaryColor),
                              title: Text(tag,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              selected: palletModel.currentTagFilter == tag,
                              tileColor: palletModel.currentTagFilter == tag
                                  ? context.primaryColor.withOpacity(0.2)
                                  : null,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              onTap: () {
                                palletModel.setTagFilter(tag);
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CLOSE",
                      style: TextStyle(color: context.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog to edit a pallet's name
  /// Used in both PalletDetailScreen and InventoryScreen
  static void showEditPalletNameDialog(
      BuildContext context, PalletModel model, Pallet pallet) {
    final nameController = TextEditingController(text: pallet.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Pallet Name",
              style: context.largeTextWeight(FontWeight.bold)),
          content: KeyboardAware(
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Pallet Name",
                  border: OutlineInputBorder(),
                  contentPadding: ResponsiveUtils.getPaddingHV(
                      context, PaddingType.small, PaddingType.small),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter pallet name";
                  }
                  // Check for duplicate names, but allow keeping the current name
                  if (value != pallet.name && model.palletNameExists(value)) {
                    return "A pallet with this name already exists";
                  }
                  return null;
                },
                style: context.mediumText,
                autofocus: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: context.mediumText),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  model.updatePalletName(pallet.id, nameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text("SAVE", style: context.mediumText),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A widget that adjusts for keyboard appearance
/// Used in all dialog forms throughout the app
class KeyboardAware extends StatelessWidget {
  final Widget child;
  final bool autoscroll;
  final ScrollController? scrollController;

  const KeyboardAware({
    super.key,
    required this.child,
    this.autoscroll = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    // If keyboard is visible and autoscroll is enabled, use SingleChildScrollView
    if (isKeyboardVisible && autoscroll) {
      return SingleChildScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        // Add padding at the bottom to prevent content from being obscured by keyboard
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: child,
      );
    }

    // Otherwise, just return the child
    return child;
  }
}
