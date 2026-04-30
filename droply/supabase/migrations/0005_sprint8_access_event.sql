do $$
begin
  if not exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'event_action'
      and e.enumlabel = 'ACCESS'
  ) then
    alter type public.event_action add value 'ACCESS';
  end if;
end $$;

