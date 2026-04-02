# frozen_string_literal: true

Rails.application.config.to_prepare do
  require "active_storage/service/s3_service"

  ActiveStorage::Service::S3Service.class_eval do
    def public_url(key, **client_opts)
      cdn_host = ENV.fetch("CLOUDFLARE_PUBLIC_HOST", "https://cdn.localbaker.app")

      if cdn_host.present? && cdn_host != "false"
        File.join(cdn_host, key)
      else
        object_for(key).public_url(**client_opts)
      end
    end
  end
end
