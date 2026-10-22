
ALTER TABLE public.product_images
ADD COLUMN enhancement_status text
    NOT NULL DEFAULT 'not_requested',
ADD COLUMN enhanced_storage_path text,
ADD COLUMN is_enhanced_selected boolean
    NOT NULL DEFAULT false;

ALTER TABLE public.product_images
ADD CONSTRAINT product_images_enhancement_status_check
CHECK (
    enhancement_status IN (
        'not_requested',
        'processing',
        'completed',
        'failed'
    )
);

ALTER TABLE public.product_images
ADD CONSTRAINT product_images_enhanced_path_check
CHECK (
    is_enhanced_selected = false
    OR enhanced_storage_path IS NOT NULL
);
