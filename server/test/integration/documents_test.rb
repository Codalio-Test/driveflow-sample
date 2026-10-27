# frozen_string_literal: true

require "test_helper"

# AC-14 / AC-47 / AC-62 / AC-106 — document & photo uploads with per-kind
# content-type whitelisting, used by the booking licence capture, the tablet
# walkaround photos and fleet registration documents.
class DocumentsTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization(slug: "documents-org")
    @role = create_role(slug: "counter_agent")
    crud!(@org, @role, "inspections", "vehicles", "customer_profiles", "damage_records",
          "rentals", "vehicle_categories", "locations")
    @agent = member_of(@org, role_slug: "counter_agent", role: @role, email: "docs-agent@example.com")
    @graph = build_rental_graph(organization: @org)
  end

  def png
    fixture_file_upload("sample.png", "image/png")
  end

  test "an inspection photo uploads and is attached (AC-47 / AC-106)" do
    post "/api/#{@org.slug}/documents",
         params: { file: png, kind: "inspection_photo" },
         headers: auth_headers(@agent)

    assert_response :created
    body = response.parsed_body
    assert_equal "inspection_photo", body["document_type"]
    assert_equal "image/png", body["content_type"]
    assert body["url"].present?
  end

  test "a driver's licence accepts PNG, JPG and PDF but not arbitrary types (AC-14)" do
    post "/api/#{@org.slug}/documents",
         params: { file: png, kind: "driver_license",
                   customer_profile_id: @graph[:profile].id },
         headers: auth_headers(@agent)
    assert_response :created

    pdf = fixture_file_upload("sample.png", "application/pdf")
    post "/api/#{@org.slug}/documents",
         params: { file: pdf, kind: "driver_license",
                   customer_profile_id: @graph[:profile].id },
         headers: auth_headers(@agent)
    assert_response :created

    bogus = fixture_file_upload("sample.png", "application/octet-stream")
    post "/api/#{@org.slug}/documents",
         params: { file: bogus, kind: "driver_license" },
         headers: auth_headers(@agent)
    assert_response :unprocessable_entity
    assert_match(/not allowed/, response.parsed_body.dig("errors", "file").first)
  end

  test "a vehicle registration document uploads (AC-62)" do
    post "/api/#{@org.slug}/documents",
         params: { file: png, kind: "registration_document", vehicle_id: @graph[:vehicle].id },
         headers: auth_headers(@agent)

    assert_response :created
    assert_equal "registration_document", response.parsed_body["document_type"]
  end

  test "an unknown document kind is rejected" do
    post "/api/#{@org.slug}/documents",
         params: { file: png, kind: "passport" },
         headers: auth_headers(@agent)

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].key?("document_type")
  end

  test "an upload without a file is rejected" do
    post "/api/#{@org.slug}/documents",
         params: { kind: "inspection_photo" },
         headers: auth_headers(@agent)

    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].key?("file")
  end

  test "an explicit content type whitelist cannot be bypassed" do
    post "/api/#{@org.slug}/documents",
         params: { file: fixture_file_upload("sample.png", "text/plain"), kind: "inspection_photo" },
         headers: auth_headers(@agent)

    assert_response :unprocessable_entity
  end

  test "uploads require authentication and a write permission" do
    post "/api/#{@org.slug}/documents", params: { file: png, kind: "inspection_photo" }
    assert_response :unauthorized

    viewer_role = create_role(slug: "viewer_only")
    grant(@org, viewer_role, "inspections.index", "inspections.show")
    viewer = member_of(@org, role_slug: "viewer_only", role: viewer_role, email: "docs-viewer@example.com")
    post "/api/#{@org.slug}/documents",
         params: { file: png, kind: "inspection_photo" },
         headers: auth_headers(viewer)
    assert_response :forbidden
  end

  test "a damage close-up attaches to its pin (AC-106)" do
    inspection = Inspection.create!(organization: @org, rental: @graph[:rental],
                                    vehicle: @graph[:vehicle], inspection_type: "check_in",
                                    odometer_reading: 10_000, fuel_percentage: 100, status: "completed")
    damage = DamageRecord.create!(organization: @org, inspection: inspection, vehicle: @graph[:vehicle],
                                  panel_location: "driver_door", severity: "dent",
                                  description: "fresh dent", is_pre_existing: false,
                                  photo_url: "https://example.com/placeholder.jpg")

    post "/api/#{@org.slug}/documents/attach_to_damage",
         params: { file: png, damage_record_id: damage.id, angle: "driver_side" },
         headers: auth_headers(@agent)

    assert_response :created
    assert damage.reload.photo_url.present?
    assert_equal "driver_side", damage.captured_angle
  end
end
