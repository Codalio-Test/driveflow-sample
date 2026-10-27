# frozen_string_literal: true

module Api
  # Tablet walkaround operations beyond plain CRUD: the departure/return
  # comparison payload, the required-photo validation gate, and photo capture.
  class InspectionsController < BaseController
    before_action :authorize_inspections!

    # GET /api/:organization/inspections/:id/comparison
    def comparison
      inspection = scoped(Inspection).find(params[:id])
      rental = inspection.rental

      departure = rental.inspections.kept.find_by(inspection_type: 'check_out')
      arrival = rental.inspections.kept.find_by(inspection_type: 'check_in')

      render json: {
        inspection: serialize(inspection),
        departure: serialize(departure),
        return: serialize(arrival),
        completeness: completeness(inspection)
      }
    end

    # POST /api/:organization/inspections/:id/photos
    def photos
      inspection = scoped(Inspection).find(params[:id])
      file = params[:file]
      return render(json: { errors: { file: ['is required'] } }, status: :unprocessable_entity) if file.blank?

      angle = params[:angle].presence || 'front'
      unless Inspection::REQUIRED_PHOTO_ANGLES.include?(angle)
        return render json: {
          errors: { angle: ["must be one of #{Inspection::REQUIRED_PHOTO_ANGLES.join(', ')}"] }
        }, status: :unprocessable_entity
      end

      inspection.photos.attach(io: file.tempfile, filename: file.original_filename, content_type: file.content_type)
      inspection.update!(notes: append_angle(inspection.notes, angle)) if params[:record_angle] != 'false'

      render json: { inspection: serialize(inspection.reload), angle: angle, completeness: completeness(inspection) },
             status: :created
    end

    # POST /api/:organization/inspections/:id/finish
    # Blocks completion until odometer, fuel and the required 4-quadrant photos
    # are present.
    def finish
      inspection = scoped(Inspection).find(params[:id])
      missing = missing_requirements(inspection)

      if missing.any?
        return render json: {
          errors: { inspection: missing.map { |field| "#{field} is required before finishing" } },
          missing: missing
        }, status: :unprocessable_entity
      end

      inspection.update!(status: 'completed', performed_at: inspection.performed_at || Time.current)

      render json: { message: 'Inspection complete', inspection: serialize(inspection.reload) }, status: :ok
    end

    private

    def authorize_inspections!
      return true if permitted?('inspections', 'index')

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end

    def serialize(inspection)
      return nil if inspection.nil?

      inspection.as_rhino_json.merge(inspection.rhino_computed_attributes).merge(
        'photo_angles' => recorded_angles(inspection),
        'damage' => inspection.damage_records.kept.map do |record|
          { 'id' => record.id, 'panel_location' => record.panel_location, 'severity' => record.severity,
            'photo_url' => record.photo_url, 'is_pre_existing' => record.is_pre_existing,
            'description' => record.description, 'repair_cost_estimate' => record.repair_cost_estimate.to_d.to_f }
        end
      )
    end

    def completeness(inspection)
      missing = missing_requirements(inspection)
      { 'complete' => missing.empty?, 'missing' => missing,
        'angles_required' => Inspection::REQUIRED_PHOTO_ANGLES,
        'angles_recorded' => recorded_angles(inspection) }
    end

    def missing_requirements(inspection)
      missing = []
      missing << 'odometer_reading' if inspection.odometer_reading.nil?
      missing << 'fuel_percentage' if inspection.fuel_percentage.nil?
      (Inspection::REQUIRED_PHOTO_ANGLES - recorded_angles(inspection)).each do |angle|
        missing << "#{angle}_photo"
      end
      missing
    end

    def recorded_angles(inspection)
      inspection.notes.to_s.scan(/\[angle:(\w+)\]/).flatten.uniq
    end

    def append_angle(notes, angle)
      marker = "[angle:#{angle}]"
      return notes.to_s if notes.to_s.include?(marker)

      [notes, marker].compact_blank.join(' ')
    end
  end
end
