select u.email, p.role
from auth.users u
join public.profiles p on p.id = u.id
where u.id = '073d4125-7996-459f-b96d-992a3f6b29cf';