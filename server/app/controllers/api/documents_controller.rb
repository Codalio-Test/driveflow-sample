# frozen_string_literal: true

module Api
  # Photo & document uploads: 4-quadrant inspection photos, damage close-ups,
  # driver-license images, vehicle registration documents and signature images.
  #
  # Content types are whitelisted per document kind; the file itself is stored
  # with ActiveStorage.
  class DocumentsController < BaseController
    CONTENT_TYPES = {
      'inspection_photo' => %w[image/jpeg image/png],
      'damage_photo' => %w[image/jpeg image/png],
      'driver_license' => %w[image/jpeg image/png application/pdf],
      'vehicle_registration' => %w[image/jpeg image/png application/pdf],
      'registration_document' => %w[image/jpeg image/png application/pdf],
      'signature' => %w[image/png image/jpeg]
    }.freeze

    MAX_BYTES = 15.megabytes

    # POST /api/:organization/documents  (multipart)
    def create
      kind = params[:document_type].presence || params[:kind].presence || 'inspection_photo'
      file = params[:file] || params[:document]
      return render(json: { errors: { file: ['is required'] } }, status: :unprocessable_entity) if file.blank?

      allowed = CONTENT_TYPES.fetch(kind, nil)
      unless allowed
        return render json: { errors: { document_type: ["must be one of #{CONTENT_TYPES.keys.join(', ')}"] } },
                      status: :unprocessable_entity
      end

      unless allowed.include?(file.content_type.to_s)
        return render json: {
          errors: { file: ["content type #{file.content_type} is not allowed for #{kind} (accepted: #{allowed.join(', ')})"] }
        }, status: :unprocessable_entity
      end

      if file.size.to_i > MAX_BYTES
        return render json: { errors: { file: ['must be smaller than 15MB'] } }, status: :unprocessable_entity
      end

      return unless authorize_documents!

      record = attach(kind, file)

      render json: {
        id: record.id,
        document_type: kind,
        url: attachment_url(record, kind, file),
        content_type: file.content_type,
        byte_size: file.size,
        filename: file.original_filename
      }, status: :created
    end

    # POST /api/:organization/documents/attach_to_damage
    def attach_to_damage
      return unless authorize_permission!('damage_records', 'update')

      record = scoped(DamageRecord).find(params[:damage_record_id])
      file = params[:file]
      return render(json: { errors: { file: ['is required'] } }, status: :unprocessable_entity) if file.blank?

      record.update!(
        photo_url: params[:url].presence || public_url_for(file),
        photo_taken_at: Time.current,
        captured_angle: params[:angle],
        dimensions: params[:dimensions]
      )

      render json: { damage_record: record.as_rhino_json.merge(record.rhino_computed_attributes) }, status: :created
    end

    private

    # Uploads are shared by the tablet walkaround (inspections), fleet
    # onboarding (vehicles) and the renter portal (their own licence), so any of
    # those write permissions grants access. Evaluated in one pass — calling
    # `authorize_permission!` repeatedly would render a 403 for each failed
    # branch and blow up with a double render.
    def authorize_documents!
      allowed = permitted?('inspections', 'store') || permitted?('vehicles', 'update') ||
                permitted?('customer_profiles', 'update')
      return true if allowed

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end

    def attach(kind, file)
      case kind
      when 'driver_license'
        profile = scoped(CustomerProfile).find_by(id: params[:customer_profile_id])
        return standalone_blob(file) if profile.nil?

        profile.update!(license_verified: false)
        upload(profile, :driver_license, file)
      when 'vehicle_registration', 'registration_document'
        vehicle = scoped(Vehicle).find_by(id: params[:vehicle_id])
        vehicle ? upload(vehicle, :registration_document, file) : standalone_blob(file)
      when 'signature'
        inspection = scoped(Inspection).find_by(id: params[:inspection_id])
        inspection ? upload(inspection, :signature_image, file) : standalone_blob(file)
      when 'damage_photo'
        damage = scoped(DamageRecord).find_by(id: params[:damage_record_id])
        damage ? upload(damage, :photo, file) : standalone_blob(file)
      else
        inspection = scoped(Inspection).find_by(id: params[:inspection_id])
        inspection ? upload(inspection, :photos, file) : standalone_blob(file)
      end
    end

    # A capture taken before its parent row exists (the first walkaround photo is
    # often snapped before the inspection is saved) is still stored, so its URL
    # can be attached to the record once it is created.
    def standalone_blob(file)
      ActiveStorage::Blob.create_and_upload!(
        io: file.tempfile, filename: file.original_filename, content_type: file.content_type
      )
    end

    def upload(record, attachment_name, file)
      return record unless record.respond_to?(attachment_name)

      record.public_send(attachment_name).attach(
        io: file.tempfile, filename: file.original_filename, content_type: file.content_type
      )
      record
    end

    def attachment_url(record, kind, file)
      return public_url_for(file) unless record.respond_to?(:id)

      attachment = if kind == 'driver_license' && record.respond_to?(:driver_license)
                     record.driver_license
                   elsif record.respond_to?(:photos)
                     record.photos
                   end

      target = if record.is_a?(ActiveStorage::Blob)
                 record
               elsif attachment.respond_to?(:attached?) && attachment.attached?
                 attachment
               end
      return public_url_for(file) if target.nil?

      Rails.application.routes.url_helpers.rails_blob_path(target, only_path: true)
    rescue StandardError
      public_url_for(file)
    end

    def public_url_for(file)
      return file if file.is_a?(String)

      "/uploads/#{SecureRandom.hex(8)}-#{file.original_filename}"
    end
  end
end
