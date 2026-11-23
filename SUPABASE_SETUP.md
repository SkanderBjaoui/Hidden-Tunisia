# Supabase setup for Hidden Tunisia

## 1. Create the project
1. Go to https://supabase.com, sign in and click **New project** (free plan is fine).
2. Choose a name, a database password (save it) and a region close to you.

## 2. Create the database
1. Dashboard → **SQL Editor** → **New query**.
2. Paste the whole content of `supabase/schema.sql` → **Run**. It creates the tables
   (`profiles`, `places`, `reviews`, `favorites`), the profile trigger, all RLS
   policies, the `place-images` storage bucket + its policies, and Realtime.
3. New query → paste `supabase/seed.sql` → **Run**. This inserts the 16 starter places.
4. Check: **Table Editor** shows 4 tables, `places` has 16 rows; **Storage** shows the
   `place-images` bucket.

## 3. Authentication settings
Dashboard → **Authentication**:
- **Sign In / Providers → Email**: enabled. While developing you can turn off
  **Confirm email** so registration logs in immediately. If you leave it on, the app
  tells the user to confirm by e-mail first.
- **URL Configuration → Redirect URLs**: add `io.supabase.hiddentunisia://login-callback/`
  (needed so the "Forgot password" e-mail link reopens the app).

## 4. Give the app your keys
1. Dashboard → **Project Settings → API**. Copy the **Project URL** and the
   **anon / publishable** key. NEVER copy the `service_role` / secret key.
2. Copy `env.example.json` to `env.json` and fill it in (`env.json` is git-ignored).
3. Run:
   ```
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```
   In Android Studio: Run → Edit Configurations → "Additional run args" →
   `--dart-define-from-file=env.json`.

## 5. Test checklist
1. Register (username, email, password + confirmation) → you land on Explore with 16 places.
2. Close the app completely and reopen → still logged in. Profile → **Log out** → login screen.
3. Login with a wrong password → "Wrong email or password."
4. Login screen → **Forgot password?** → open the e-mail on the phone → choose a new password.
5. Heart a place, restart the app → still favorited (Table Editor → `favorites`).
6. Place details → **Write a review** → appears at once; writing again edits your review.
7. Add a place with a photo → image appears in Storage → `place-images/<your-user-id>/`.
8. Log in on a second device/emulator, add a place → it appears on the first one within seconds.
9. Security: in the SQL editor, `select * from favorites` shows rows, but from the app
   a user can only ever see their own favorites (RLS).

## Notes
- Ratings and reviews share one table: every review has a 1–5 star rating, one review per user per place.
- Places found through OpenStreetMap are copied into `places` the first time a user
  favorites or reviews them (keyed by `source_id`).
- Users can edit/delete only places they created (seed places have no owner, so nobody can edit them from the app).
