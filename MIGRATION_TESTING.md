# Migration Testing Guide: Local Storage to Cloud

This document provides step-by-step instructions for testing the data migration process from local storage (SharedPreferences) to cloud storage (Supabase) in the Pallet Manager app.

## Prerequisites

- A device with the Pallet Manager app installed
- Internet connection
- A Supabase account (for cloud storage)

## Testing Tools

The app includes built-in testing tools to help with migration testing. These tools are accessible in the Settings screen under the "Testing Tools" section (only visible in debug builds).

- **Generate Test Data**: Creates random pallet and item data in SharedPreferences
- **Reset Local Data**: Clears all data from SharedPreferences
- **Force Migration Check**: Manually triggers the migration detection process

## Test Scenarios

### Scenario 1: Fresh User Migration

This scenario tests how a new user who has been using the app with local storage will migrate to cloud storage.

1. **Reset the app state**
   - Launch the app
   - If already signed in, sign out from Settings > Account > Sign Out
   - Go to Settings > Testing Tools > Reset Local Data
   - Confirm the reset

2. **Generate test data**
   - Go to Settings > Testing Tools > Generate Test Data
   - Set the number of pallets (e.g., 5) and items per pallet (e.g., 10)
   - Tap "GENERATE"
   - Verify that the data appears in the Inventory screen

3. **Create a Supabase account or sign in**
   - Sign out if currently signed in
   - Go to Account > Sign In or use the login screen
   - Either sign in with existing credentials or create a new account

4. **Verify migration prompt appears**
   - After signing in, a migration screen should appear
   - If it doesn't, go to Settings > Testing Tools > Force Migration Check
   - Restart the app if needed

5. **Perform migration**
   - On the migration screen, review the data summary
   - Tap "Start One-Way Migration"
   - Wait for the migration to complete
   - Tap "CONTINUE TO CLOUD APP"

6. **Verify migrated data**
   - Check the Inventory screen to ensure all pallets and items are present
   - Navigate through different pallets to verify item details
   - Ensure that the Settings screen shows "Your data is stored in the cloud"

7. **Test CRUD operations post-migration**
   - Add a new pallet
   - Add items to the pallet
   - Edit an existing pallet
   - Delete an item
   - Delete a pallet
   - Verify all operations work correctly with cloud storage

### Scenario 2: Account Switching

This scenario tests how the app handles switching between different user accounts.

1. **Prepare test data**
   - Follow steps 1-6 from Scenario 1 to have a user with migrated data

2. **Sign out**
   - Go to Settings > Account > Sign Out
   - Verify that you are redirected to the login screen

3. **Sign in with a different account**
   - Sign in with a different account or create a new one
   - Verify that you don't see the previous user's data
   - Verify that the app starts with empty data for the new user

4. **Generate new test data for this user**
   - Use the Testing Tools to generate different test data
   - Migrate this data to the cloud as well

5. **Switch back to the first account**
   - Sign out
   - Sign in with the first account's credentials
   - Verify that the first user's data is correctly loaded
   - Ensure no data from the second user appears

### Scenario 3: Handling Migration Errors

This scenario tests how the app handles errors during migration.

1. **Prepare test data with network interruption**
   - Reset the app state and generate test data
   - Enable airplane mode or disconnect from the internet
   - Sign in and attempt migration
   - Verify that an appropriate error message appears
   - Verify that "RETRY MIGRATION" and "CONTINUE WITHOUT MIGRATING" options are provided

2. **Retry migration after restoring connectivity**
   - Disable airplane mode or reconnect to the internet
   - Tap "RETRY MIGRATION"
   - Verify that migration completes successfully

3. **Skip migration and try later**
   - Reset the app state and generate new test data
   - During migration, tap "CONTINUE WITHOUT MIGRATING"
   - Verify you can access the app with local data
   - Go to Settings and verify the "Migrate to Cloud" option is available
   - Use this option to migrate later

## Database Maintenance

If you encounter data inconsistencies or duplicates during testing, use the Database Maintenance tool:

1. Go to Settings > Data Management > Database Maintenance
2. Tap "CLEAN UP DATABASE"
3. Verify that duplicate data is removed and data consistency is restored

## Step-by-Step Migration Guide for Your Wife

If your wife is currently using the local storage version and needs to migrate:

1. Install the latest version of the app that supports cloud storage

2. Create a Supabase account:
   - Open the app
   - On the login screen, tap "Sign Up"
   - Enter email address and create a secure password
   - Tap "SIGN UP"
   - Verify the email if required
   - Sign in with the newly created account

3. Follow the migration prompt:
   - After signing in, a migration screen should appear automatically
   - Review the data summary to ensure all pallets and items are accounted for
   - Tap "Start One-Way Migration"
   - Wait for the migration to complete (this may take a few minutes depending on data size)
   - Once complete, tap "CONTINUE TO CLOUD APP"

4. Verify data after migration:
   - Check that all pallets appear in the Inventory screen
   - Navigate through pallets to verify items are present
   - Test adding, editing, and deleting pallets and items to ensure everything works

5. If any issues occur during migration:
   - Try again by tapping "RETRY MIGRATION"
   - If problems persist, you can choose "CONTINUE WITHOUT MIGRATING" and try again later from Settings

## Common Issues and Solutions

- **Missing Data After Migration**: Use the Database Maintenance option in Settings to clean up data inconsistencies
- **"Failed to Sign Out" Error**: If you encounter this error, simply restart the app and try again
- **Migration Not Appearing**: Use the "Force Migration Check" tool in Settings > Testing Tools
- **Duplicated Pallets**: Use the Database Maintenance option to clean up duplicates 