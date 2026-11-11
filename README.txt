DRIFT UNITED – working implementation (not deployed)

Files:
 index.html – public site; registration buttons now link to portal.html
 portal.html – login, signup, approved-driver dashboard and weekend applications
 admin.html – organizer approval and management
 portal.css, portal.js, admin.js, common.js – client code
 schema.sql – Supabase database, RLS policies and initial 3 weekends
 config.js – PUBLIC Supabase URL and anon/publishable key only

SETUP:
1. Create a Supabase project. Run schema.sql in SQL Editor.
2. Sign up as the initial organizer in portal.html. Promote this account manually using the commented SQL at end of schema.sql.
3. Fill in config.js with public project URL and publishable/anon key. Never use service_role key in browser.
4. Configure Auth Site URL and redirect URLs for your deployed domain. Enable email verification and email delivery.
5. Add real event dates, prices, approved terms/documents and open registration via admin.html.
6. Deploy all files together to HTTPS hosting (Netlify works). Test permissions with separate admin/driver accounts.

IMPORTANT: This is a code implementation, NOT an operational service until a real Supabase project is configured and deployment/security testing is completed. No ZIP generated yet.
