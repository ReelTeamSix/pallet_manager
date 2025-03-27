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
    final dateController = TextEditingController(
      text: "${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}"
    );
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();

    // Function to show date picker
    Future<void> selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (picked != null && picked != selectedDate) {
        selectedDate = picked;
        dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      }
    }

    // Function to show tag selection in a bottom sheet
    void showTagSelector() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          // Directly access the model inside the builder for freshest data
          final tagsToShow =
              Provider.of<PalletModel>(context).savedTags.toList();
          
          if (tagsToShow.isEmpty) {
            return Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.label_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No tags created yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Create a new tag for your pallet",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select a Tag",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Show a chips layout for better UX
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagsToShow.map((tag) {
                    return AnimatedBuilder(
                      animation: tagController,
                      builder: (context, _) {
                        final isSelected = tagController.text == tag;
                        return InkWell(
                          onTap: () {
                            tagController.text = tag;
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Done"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void handleSubmit() {
      if (formKey.currentState!.validate()) {
        final name = nameController.text.trim();
        final tag = tagController.text.trim();
        final cost = double.parse(costController.text);
        
        Provider.of<PalletModel>(context, listen: false).addPallet(
          Pallet(
            id: Provider.of<PalletModel>(context, listen: false)
                .generatePalletId(),
            name: name,
            tag: tag,
            totalCost: cost,
            date: selectedDate,
          ),
        );
        Navigator.pop(context);
      }
    }

    // Show the dialog with keyboard awareness
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(
              Icons.add_box,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              "Add New Pallet",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: KeyboardAware(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Pallet Name",
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      if (palletModel.palletNameExists(value.trim())) {
                        return 'This name already exists';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Tag field
                  TextFormField(
                    controller: tagController,
                    decoration: InputDecoration(
                      labelText: "Tag (Optional)",
                      prefixIcon: Icon(Icons.label),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.arrow_drop_down),
                        onPressed: showTagSelector,
                        tooltip: "Select from existing tags",
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Date field
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Date",
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onTap: selectDate,
                  ),
                  SizedBox(height: 16),
                  
                  // Cost field
                  TextFormField(
                    controller: costController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Total Cost",
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL"),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text("SAVE"),
            onPressed: handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
