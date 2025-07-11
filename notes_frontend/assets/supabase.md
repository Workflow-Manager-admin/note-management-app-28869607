# Supabase Integration Guide

This app uses Supabase as its backend to store and manage notes. 

## Configuration
- **SUPABASE_URL**: https://mzxyorlnbfdkneiezgjz.supabase.co
- **SUPABASE_KEY**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16eHlvcmxuYmZka25laWV6Z2p6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDUxMDksImV4cCI6MjA2NzYyMTEwOX0.URYpbwtC2u5ORBlUzpWPNspXMWq_cLBOKWMOgGbilyQ

Set these values in your Flutter project as seen in `main.dart`.

## Required Table

Create the following table and columns in your Supabase instance:

Table: **notes**
| Column       | Type     | Required | Description        |
|--------------|----------|----------|--------------------|
| id           | integer  | Yes (PK) | Note ID, auto-inc  |
| title        | text     | Yes      | Note title         |
| content      | text     | Yes      | Note body/content  |
| created_at   | timestamp| Yes      | Creation time      |
| updated_at   | timestamp| Yes      | Last update time   |

The app uses the `notes` table for all note CRUD operations.

## Flutter Supabase Client
This app is set up with [supabase_flutter](https://pub.dev/packages/supabase_flutter) and [supabase](https://pub.dev/packages/supabase) dependencies.

- Initialization is present in `main.dart`.
- CRUD is handled in `NotesService` within `main.dart`.

## Usage
No other configuration is necessary–simply run the app. Ensure your Supabase backend is provisioned with the right table and permissions for anonymous use.
