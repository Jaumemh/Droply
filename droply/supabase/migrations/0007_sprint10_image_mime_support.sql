update storage.buckets
set allowed_mime_types = array(
  select distinct mime
  from unnest(
    coalesce(allowed_mime_types, '{}'::text[])
    || array[
      'image/avif',
      'image/bmp',
      'image/heic',
      'image/heif',
      'image/tiff'
    ]::text[]
  ) as allowed(mime)
  order by mime
)
where id = 'droply-files';
