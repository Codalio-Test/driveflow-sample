# frozen_string_literal: true

# Soft-delete support shared by every DriveFlow resource.
#
# Rhino's generated index/show actions query the model class directly (they do
# NOT call `.kept`), so discarding a row only hides it if the MODEL excludes
# discarded rows by default. `include Discard::Model` alone does not do that —
# Discard deliberately ships no default scope — which meant a soft-deleted
# vehicle or rental kept appearing in the list endpoints.
#
# The `discarded` scope is redefined to lift the default condition first,
# otherwise `Model.discarded` (used by /trashed, restore and force-delete) would
# AND `discarded_at IS NULL` with `discarded_at IS NOT NULL` and always be empty.
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    default_scope { kept }

    scope :discarded, -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
  end

  class_methods do
    # Rhino's organization scoping is `relation.merge(model.for_organization(org))`.
    # The engine's own implementation is `where(organization_id: ...)`, which —
    # now that the model has a soft-delete default scope — carries
    # `discarded_at IS NULL` into every merge and CLOBBERS the caller's own
    # `discarded_at IS NOT NULL` condition. That made /trashed (and the
    # restore / force-delete lookups) return live rows.
    #
    # Built from `unscoped` so it contributes only the organization predicate and
    # composes safely with any soft-delete condition on either side.
    def for_organization(organization)
      unscoped.where(organization_id: organization.id)
    end
  end
end
