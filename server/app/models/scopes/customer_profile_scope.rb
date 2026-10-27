# frozen_string_literal: true

module Scopes
  # Customers only see their own profile; staff see every profile in the org.
  class CustomerProfileScope < Rhino::ResourceScope
    def apply(relation)
      return relation unless role == 'customer'

      relation.where(user_id: user.id)
    end
  end
end
