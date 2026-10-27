# frozen_string_literal: true

module Api
  # Executive analytics. All aggregation happens in AnalyticsService inside an
  # explicit Rhino.for_user(...).in_organization(...) context so organization
  # scoping is never bypassed.
  class AnalyticsController < BaseController
    before_action :authorize_analytics!

    # GET /api/:organization/analytics?range=30&location=SFO-01
    def show
      render json: AnalyticsService.new(
        user: current_user,
        organization: current_organization,
        range: params[:range].presence || '30',
        location: params[:location]
      ).call
    end

    # GET /api/:organization/analytics/export.csv
    def export
      require 'csv'
      data = AnalyticsService.new(
        user: current_user, organization: current_organization,
        range: params[:range].presence || '30', location: params[:location]
      ).call

      body = CSV.generate(headers: true) do |csv|
        csv << %w[section metric value]
        data['kpis'].each { |kpi| csv << ['kpi', kpi['label'], kpi['value']] }
        data['deposits'].each { |key, value| csv << ['deposits', key, value] }
        data['maintenance'].each { |key, value| csv << ['maintenance', key, value] }
        data['charts'].each do |chart|
          chart['values'].each { |point| csv << [chart['title'], point['label'], point['value']] }
        end
      end

      send_data body, filename: 'driveflow-analytics.csv', type: 'text/csv', disposition: 'attachment'
    end

    private

    def authorize_analytics!
      return true if permitted?('analytics', 'show') ||
                     (permitted?('rentals', 'index') && permitted?('payments', 'index'))

      render json: { message: 'This action is unauthorized.' }, status: :forbidden
      false
    end
  end
end
