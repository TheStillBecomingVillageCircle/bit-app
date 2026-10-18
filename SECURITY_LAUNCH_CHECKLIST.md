# B. I. T. — Privacy and account safety launch gate

**Status: NOT VERIFIED / NOT READY FOR SENSITIVE DATA.**

## Required before public testing
1. Run `supabase/security_audit.sql` in the actual Supabase project. Inspect RLS and all policies, including any added since `schema.sql` was created.
2. Test with two unrelated authenticated accounts and a third unconnected account. Attempt direct API reads, inserts, updates and deletes of private reflections, profiles, messages, invites, check-ins and agreements. Deny unauthorized access at the database, not merely the interface.
3. Audit `accept_partnership_invite` for token expiry, consent, authorization, replay protection and safe handling of invitations. Avoid logging raw invite tokens.
4. Build server-side **delete account** using authenticated, recently reverified identity. Delete personal reflections, profile, invitations, owned data and Auth user; explicitly document and test shared-message retention. Handle errors and partial failures. Never expose service-role keys in the browser.
5. Build **deactivate account** using a trusted server-side operation that blocks access to Auth and protected data; provide a secure reactivation path. A browser-only flag is insufficient.
6. Publish a plain-language privacy notice and terms, including collected data, recipients/processors, retention, deletion, security limits, crisis/abuse safety boundaries and contact method. Have a qualified legal reviewer check them before launch.
7. Test logout, account deletion, deactivation, expired sessions, shared-device/browser data, invite URLs and browser back-navigation. Clear local per-user preferences on verified deletion.
8. AI must be opt-in and not receive private reflections for another user's cue. Confirm provider data retention and training terms before using real content.
9. Test rate limiting, content length limits, security headers/CSP, dependency integrity, backups and incident response.
10. Do not remove the in-app test warning until the live database and all destructive account flows are verified.

**Current reality:** GitHub contains a proposed RLS schema, but that is not proof the live database has those policies. Reflect currently uses browser-session memory, not encrypted persistent storage. Account deletion/deactivation are not implemented.

**Shared-message decision needed:** whether deleting a user deletes their authored messages for both parties, or retains them for the other party with an anonymized sender. Decide and disclose before enabling account deletion.
