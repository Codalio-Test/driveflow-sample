# frozen_string_literal: true

module Api
  # Public vehicle catalog for `/vehicles`: rentable categories with their
  # specs, effective rate and available vehicles. Anonymous-friendly.
  class VehicleCatalogController < PublicController
    def index
      categories = public_scope(VehicleCategory).order(:base_daily_rate)
      categories = categories.where(code: params[:category]) if params[:category].present?
      categories = categories.where(transmission: params[:transmission]) if params[:transmission].present?

      if params[:query].present?
        categories = categories.where('vehicle_categories.name ILIKE :q OR vehicle_categories.code ILIKE :q',
                                      q: "%#{params[:query]}%")
      end

      data = categories.map do |category|
        vehicles = public_scope(Vehicle).where(vehicle_category_id: category.id)
        vehicles = vehicles.where(location_id: params[:location_id]) if params[:location_id].present?

        {
          'id' => category.id,
          'name' => category.name,
          'code' => category.code,
          'description' => category.description,
          'rate' => RateCalculator.new(category).daily_rate.to_f,
          'base_daily_rate' => category.base_daily_rate.to_f,
          'security_deposit_amount' => category.security_deposit_amount.to_f,
          'mileage_allowance_per_day' => category.mileage_allowance_per_day,
          'excess_mileage_rate' => category.excess_mileage_rate.to_d.to_f,
          'late_hourly_fee' => category.late_hourly_fee.to_d.to_f,
          'passenger_capacity' => category.passenger_capacity,
          'baggage_capacity' => category.baggage_capacity,
          'transmission' => category.transmission,
          'available_count' => vehicles.where(status: 'available').count,
          'vehicles' => vehicles.limit(10).map do |vehicle|
            { 'id' => vehicle.id, 'make' => vehicle.make, 'model' => vehicle.model,
              'year' => vehicle.year, 'status' => vehicle.status,
              'license_plate' => vehicle.license_plate, 'fuel_type' => vehicle.fuel_type }
          end
        }
      end

      render json: { data: data, meta: { organization: current_organization.slug } }
    end
  end
end
