/*
This file serves as documentation for the Supabase database schema.
The actual schema will be created in the Supabase dashboard.

Database Tables:
---------------

1. profiles
   - id (uuid, primary key) - References auth.users.id
   - created_at (timestamp with time zone)
   - email (text)
   - name (text)

2. pallets
   - id (uuid, primary key)
   - created_at (timestamp with time zone) 
   - name (text, not null)
   - tag (text)
   - date (timestamp with time zone, not null)
   - total_cost (numeric, not null)
   - is_closed (boolean, default false)
   - user_id (uuid, references profiles.id)
   - original_id (integer) - to preserve id from shared preferences data migration

3. pallet_items
   - id (uuid, primary key)
   - created_at (timestamp with time zone)
   - name (text, not null)
   - sale_price (numeric, default 0)
   - is_sold (boolean, default false)
   - sale_date (timestamp with time zone)
   - allocated_cost (numeric, default 0)
   - retail_price (numeric)
   - condition (text)
   - list_price (numeric)
   - product_code (text)
   - pallet_id (uuid, references pallets.id)
   - user_id (uuid, references profiles.id)
   - original_id (integer) - to preserve id from shared preferences data migration

4. item_photos
   - id (uuid, primary key)
   - created_at (timestamp with time zone)
   - url (text, not null)
   - item_id (uuid, references pallet_items.id)
   - user_id (uuid, references profiles.id)

5. tags
   - id (uuid, primary key)
   - created_at (timestamp with time zone)
   - name (text, not null)
   - user_id (uuid, references profiles.id)

Row Level Security Policies:
--------------------------
Each table should have RLS enabled with policies that:
1. Allow users to only see and modify their own data
2. Allow service roles full access for admin operations

Example policy for pallets table:
- CREATE POLICY "Users can view their own pallets" ON pallets FOR SELECT USING (auth.uid() = user_id);
- CREATE POLICY "Users can insert their own pallets" ON pallets FOR INSERT WITH CHECK (auth.uid() = user_id);
- CREATE POLICY "Users can update their own pallets" ON pallets FOR UPDATE USING (auth.uid() = user_id);
- CREATE POLICY "Users can delete their own pallets" ON pallets FOR DELETE USING (auth.uid() = user_id);
*/ 