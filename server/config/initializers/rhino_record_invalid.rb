# frozen_string_literal: true

# Rhino's model-validation create/update path only validates the fields the
# policy permits. An empty payload therefore reaches `create!` with nothing to
# validate and escapes as a raw ActiveRecord::RecordInvalid (a 500). Surface it
# as the standard 422 error envelope instead.
Rails.application.config.to_prepare do
  Rhino::ResourcesController.rescue_from(ActiveRecord::RecordInvalid) do |e|
    render json: { errors: e.record.errors.to_hash }, status: :unprocessable_entity
  end
end
