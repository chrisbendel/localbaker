class AddCoverPhotoToStores < ActiveRecord::Migration[8.1]
  # Points at a gallery_photos attachment id. Nullable — falls back to the
  # first gallery photo. Replaces the separate banner_image attachment.
  def change
    add_column :stores, :cover_photo_id, :integer
  end
end
