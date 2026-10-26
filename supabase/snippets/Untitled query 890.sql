select u.email, p.role
from auth.users u join public.profiles p on p.id = u.id
where p.role = 'admin';
