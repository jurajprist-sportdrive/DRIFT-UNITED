-- Drift United: run once in Supabase SQL Editor.
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', phone text not null default '', country text not null default '',
 car text not null default '', number text not null default '', team text not null default '',
 status text not null default 'pending' check(status in ('pending','approved','rejected','blocked')),
 is_admin boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.events (
 id uuid primary key default gen_random_uuid(), number int unique not null check(number between 1 and 3),
 title text not null, date_label text, capacity int not null default 30 check(capacity>0),
 price_eur numeric(10,2), open boolean not null default false
);
create table if not exists public.documents (
 id uuid primary key default gen_random_uuid(), title text not null, version text not null default '1',
 body text not null default '', active boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.applications (
 id uuid primary key default gen_random_uuid(), driver_id uuid not null references public.profiles(id) on delete cascade,
 event_id uuid not null references public.events(id), participation text not null check(participation in ('full','saturday','sunday')),
 status text not null default 'pending' check(status in ('pending','approved','rejected','cancelled')),
 terms_accepted boolean not null default false, terms_accepted_at timestamptz not null default now(),
 created_at timestamptz not null default now(), reviewed_at timestamptz, reviewed_by uuid references public.profiles(id),
 unique(driver_id,event_id)
);
create index if not exists idx_apps_event_status on public.applications(event_id,status);
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and is_admin=true and status='approved')
$$;
create or replace function public.is_approved() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and status='approved')
$$;
create or replace function public.new_driver_profile() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,full_name,phone,country,car,number,team)
 values(new.id, left(coalesce(new.raw_user_meta_data->>'full_name',''),100),left(coalesce(new.raw_user_meta_data->>'phone',''),35),left(coalesce(new.raw_user_meta_data->>'country',''),60),left(coalesce(new.raw_user_meta_data->>'car',''),100),left(coalesce(new.raw_user_meta_data->>'number',''),12),left(coalesce(new.raw_user_meta_data->>'team',''),100));
 return new;
end $$;
drop trigger if exists on_driver_created on auth.users;
create trigger on_driver_created after insert on auth.users for each row execute function public.new_driver_profile();
-- Prevent privilege changes by ordinary users. No UPDATE policy for profiles.
alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.documents enable row level security;
alter table public.applications enable row level security;
create policy "own or admin profile" on public.profiles for select to authenticated using (id=(select auth.uid()) or (select public.is_admin()));
create policy "admin profile update" on public.profiles for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "approved event read" on public.events for select to authenticated using ((select public.is_approved()));
create policy "admin event write" on public.events for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "approved docs read" on public.documents for select to authenticated using ((select public.is_approved()) and active=true);
create policy "admin docs manage" on public.documents for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "own or admin applications read" on public.applications for select to authenticated using (driver_id=(select auth.uid()) or (select public.is_admin()));
create policy "approved driver apply" on public.applications for insert to authenticated with check (
 driver_id=(select auth.uid()) and (select public.is_approved()) and status='pending' and terms_accepted=true
 and exists(select 1 from public.events where id=event_id and open=true)
);
create policy "admin applications update" on public.applications for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
-- Prevent overbooking under simultaneous admin approvals.
create or replace function public.enforce_capacity() returns trigger language plpgsql security definer set search_path='' as $$
declare maximum int; used int;
begin
 if new.status='approved' and (tg_op='INSERT' or old.status is distinct from 'approved' or old.event_id is distinct from new.event_id) then
  select capacity into maximum from public.events where id=new.event_id for update;
  select count(*) into used from public.applications where event_id=new.event_id and status='approved' and id<>new.id;
  if used>=maximum then raise exception 'Capacity reached for this weekend'; end if;
 end if;
 return new;
end $$;
drop trigger if exists check_capacity on public.applications;
create trigger check_capacity before insert or update on public.applications for each row execute function public.enforce_capacity();
insert into public.events(number,title,date_label,capacity,open) values
(1,'UNITED DRIFT CAMP #01','Termín pripravujeme',30,false),
(2,'UNITED DRIFT CAMP #02','Termín pripravujeme',30,false),
(3,'UNITED DRIFT CAMP #03','Termín pripravujeme',30,false)
on conflict(number) do nothing;
-- FIRST ADMIN: after signing up, use the Supabase SQL Editor (trusted admin context):
-- update public.profiles set status='approved',is_admin=true where id=(select id from auth.users where email='YOUR_EMAIL_HERE');
-- Never grant admin privileges via client-side code.
