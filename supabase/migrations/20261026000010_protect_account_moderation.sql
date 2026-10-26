alter table public.app_settings
  drop constraint app_settings_updated_by_fkey,
  add constraint app_settings_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

create or replace function public.profiles_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not has_role(array['admin']::app_role[]) then
    new.role := old.role;
    new.blocked_at := old.blocked_at;
    new.blocked_until := old.blocked_until;
    new.block_reason := old.block_reason;
    new.blocked_by := old.blocked_by;
  end if;
  return new;
end $$;
