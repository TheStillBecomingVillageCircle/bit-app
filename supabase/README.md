# BIT backend setup

BIT is moving from a browser-only prototype to a real app. This folder contains the first database schema for Supabase.

## What this schema is for

- Individual profiles tied to authenticated accounts
- Relationship spaces that are pending until a partner accepts
- Shared messages and relationship tools
- Private reflections that only the author can read

## Set up the free Supabase project

1. Open https://supabase.com and create an account (the free plan is enough to begin testing).
2. Create a new project named `bit-app`. Save the database password somewhere private.
3. In the project, open **SQL Editor** and create a new query.
4. Open `schema.sql` in this folder, copy its contents into the SQL Editor, and run it.
5. In **Authentication → URL Configuration**, set the site URL to the published BIT site and add that site URL to the allowed redirect URLs.
6. Keep database secrets private. Never put a Supabase service-role key or an AI-provider secret into `index.html` or any other browser code.

## Important status

This schema is a development foundation, not a launch-ready security review. Partner invitation acceptance must be implemented through a trusted server-side function that validates the invite token and records the partner's consent. Do not use real sensitive relationship information until the full authentication, invitation flow, access policies, and security testing are complete.

The current GitHub Pages prototype is still a static front end. Adding this schema does not connect it to Supabase by itself; the next development step is to add sign-in and configure the public Supabase project URL and publishable/anon key in the client, then wire each feature to authenticated database access.
