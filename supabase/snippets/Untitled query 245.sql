select slug, status, kcal, auto_tags, allergen_ids
from public.recipes
order by slug;

select count(*) as product_count
from public.products;
