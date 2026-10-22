-- Migration for product image storage setup

-- Create a private bucket for artisan product images.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', false)
on conflict (id) do nothing;

-- Policy to allow an artisan to upload images only within their own folder.
-- Expected object path:
-- user-uuid/product-uuid/random-file-name.jpg
create policy "product_images_storage_upload_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

-- Policy to allow owners to view their own uploaded images.
-- Anyone can read an image once it belongs to a published product.
create policy "product_images_storage_read"
on storage.objects for select to anon, authenticated
using (
  bucket_id = 'product-images'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or exists (
      select 1
      from public.product_images pi
      join public.products p on p.id = pi.product_id
      where pi.storage_path = name
        and p.status = 'published'
    )
  )
);

-- Policy to allow owners to delete their own uploaded images.
create policy "product_images_storage_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
