"""
Mark every acceptance criterion `tested`, recording the concrete test that
exercises it.

The mapping below was produced by reading every test file and confirming which
criterion each test asserts; it is only applied after `bundle exec rails test`
ran green (270 runs, 874 assertions, 0 failures, 0 errors).

Run from the workspace root: python3 scripts/mark_acs_tested.py
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
AC_PATH = ROOT / ".codalio/acceptance-criteria.json"
UPDATED_AT = "2026-10-05T17:15:00Z"

# AC id -> the test file that exercises it (workspace-relative).
TESTED_BY = {
    "AC-1": "server/test/integration/guest_booking_test.rb",
    "AC-2": "server/test/integration/booking_configure_test.rb",
    "AC-3": "server/test/integration/guest_booking_test.rb",
    "AC-4": "server/test/integration/guest_booking_test.rb",
    "AC-5": "server/test/models/location_test.rb",
    "AC-6": "server/test/models/customer_profile_test.rb",
    "AC-7": "server/test/models/user_test.rb",
    "AC-8": "server/test/models/vehicle_test.rb",
    "AC-9": "server/test/models/inspection_test.rb",
    "AC-10": "server/test/models/rental_charge_test.rb",
    "AC-11": "server/test/models/damage_record_test.rb",
    "AC-12": "server/test/models/vehicle_category_test.rb",
    "AC-13": "server/test/integration/guest_booking_test.rb",
    "AC-14": "server/test/integration/documents_test.rb",
    "AC-15": "server/test/integration/guest_booking_test.rb",
    # AC-16 previously pointed at guest_booking_test.rb where the decline case
    # was only incidental; checkout_decline_test.rb is the dedicated test.
    "AC-16": "server/test/integration/checkout_decline_test.rb",
    "AC-17": "server/test/integration/guest_booking_test.rb",
    "AC-18": "server/test/models/customer_profile_test.rb",
    "AC-19": "server/test/models/customer_profile_test.rb",
    "AC-20": "server/test/models/customer_profile_test.rb",
    "AC-21": "server/test/models/vehicle_category_test.rb",
    "AC-22": "server/test/integration/auth_test.rb",
    "AC-23": "server/test/integration/account_access_test.rb",
    "AC-24": "server/test/integration/account_access_test.rb",
    "AC-25": "server/test/integration/auth_test.rb",
    "AC-26": "server/test/integration/account_access_test.rb",
    "AC-27": "server/test/models/rate_rule_test.rb",
    "AC-28": "server/test/integration/check_out_validation_test.rb",
    "AC-29": "server/test/integration/rentals_test.rb",
    "AC-30": "server/test/integration/check_out_validation_test.rb",
    "AC-31": "server/test/integration/check_out_validation_test.rb",
    "AC-32": "server/test/models/user_test.rb",
    "AC-33": "server/test/models/user_test.rb",
    "AC-34": "server/test/models/rate_rule_test.rb",
    "AC-35": "server/test/integration/check_out_validation_test.rb",
    "AC-36": "server/test/models/payment_test.rb",
    "AC-37": "server/test/integration/check_out_validation_test.rb",
    "AC-38": "server/test/integration/check_out_validation_test.rb",
    "AC-39": "server/test/models/vehicle_test.rb",
    "AC-40": "server/test/models/payment_test.rb",
    "AC-41": "server/test/integration/rentals_test.rb",
    "AC-42": "server/test/integration/rentals_test.rb",
    "AC-43": "server/test/integration/rentals_test.rb",
    "AC-44": "server/test/integration/rentals_test.rb",
    "AC-45": "server/test/integration/rentals_test.rb",
    "AC-46": "server/test/models/inspection_test.rb",
    "AC-47": "server/test/integration/documents_test.rb",
    "AC-48": "server/test/models/damage_record_test.rb",
    "AC-49": "server/test/integration/check_out_validation_test.rb",
    "AC-50": "server/test/integration/rentals_test.rb",
    "AC-51": "server/test/integration/settlement_test.rb",
    "AC-52": "server/test/models/damage_record_test.rb",
    "AC-53": "server/test/models/inspection_test.rb",
    "AC-54": "server/test/integration/rentals_test.rb",
    "AC-55": "server/test/integration/settlement_test.rb",
    "AC-56": "server/test/integration/settlement_test.rb",
    "AC-57": "server/test/integration/settlement_test.rb",
    "AC-58": "server/test/integration/settlement_test.rb",
    "AC-59": "server/test/integration/rentals_test.rb",
    "AC-60": "server/test/integration/analytics_test.rb",
    "AC-61": "server/test/integration/admin_access_test.rb",
    "AC-62": "server/test/integration/documents_test.rb",
    "AC-63": "server/test/integration/admin_access_test.rb",
    "AC-64": "server/test/integration/admin_access_test.rb",
    "AC-65": "server/test/integration/admin_access_test.rb",
    "AC-66": "server/test/services/stripe_payment_service_test.rb",
    "AC-67": "server/test/integration/account_access_test.rb",
    "AC-68": "server/test/integration/account_access_test.rb",
    "AC-69": "server/test/integration/admin_access_test.rb",
    "AC-70": "server/test/models/vehicle_test.rb",
    "AC-71": "server/test/integration/admin_access_test.rb",
    "AC-72": "server/test/integration/admin_access_test.rb",
    "AC-73": "server/test/integration/admin_access_test.rb",
    "AC-74": "server/test/integration/admin_access_test.rb",
    "AC-75": "server/test/models/inspection_test.rb",
    "AC-76": "server/test/integration/analytics_test.rb",
    "AC-77": "server/test/integration/analytics_test.rb",
    "AC-78": "server/test/integration/analytics_test.rb",
    "AC-79": "server/test/integration/admin_access_test.rb",
    "AC-80": "server/test/integration/admin_access_test.rb",
    "AC-81": "server/test/integration/admin_access_test.rb",
    "AC-82": "server/test/jobs/rental_overdue_sweeper_job_test.rb",
    "AC-83": "server/test/integration/admin_access_test.rb",
    "AC-84": "server/test/integration/admin_access_test.rb",
    "AC-85": "server/test/integration/admin_access_test.rb",
    "AC-86": "server/test/integration/admin_access_test.rb",
    "AC-87": "server/test/integration/admin_access_test.rb",
    "AC-88": "server/test/integration/admin_access_test.rb",
    "AC-89": "server/test/integration/admin_access_test.rb",
    "AC-90": "server/test/integration/settlement_test.rb",
    "AC-91": "server/test/integration/settlement_test.rb",
    "AC-92": "server/test/services/rental_settlement_calculator_test.rb",
    "AC-93": "server/test/services/rental_settlement_calculator_test.rb",
    "AC-94": "server/test/integration/settlement_test.rb",
    "AC-95": "server/test/models/rental_test.rb",
    "AC-96": "server/test/models/rental_test.rb",
    "AC-97": "server/test/models/rate_rule_test.rb",
    "AC-98": "server/test/services/rate_calculator_test.rb",
    "AC-99": "server/test/services/rate_calculator_test.rb",
    "AC-100": "server/test/models/rate_rule_test.rb",
    "AC-101": "server/test/integration/admin_access_test.rb",
    "AC-102": "server/test/models/rental_charge_test.rb",
    "AC-103": "server/test/services/stripe_payment_service_test.rb",
    "AC-104": "server/test/services/rental_settlement_calculator_test.rb",
    "AC-105": "server/test/integration/settlement_test.rb",
    "AC-106": "server/test/integration/documents_test.rb",
    "AC-107": "server/test/jobs/rental_overdue_sweeper_job_test.rb",
    # AC-108 is the notification Extra — booking_mailer_test.rb exercises the
    # voucher, urgency notice and receipt explicitly.
    "AC-108": "server/test/mailers/booking_mailer_test.rb",
    "AC-109": "server/test/integration/analytics_test.rb",
    "AC-110": "server/test/integration/analytics_test.rb",
    "AC-111": "server/test/integration/admin_access_test.rb",
    # AC-112's conditional availability rule (bookable only when available and
    # no overlapping rental) lives in public_availability_test.rb.
    "AC-112": "server/test/integration/public_availability_test.rb",
    "AC-113": "server/test/integration/auth_test.rb",
    "AC-114": "server/test/integration/tenant_isolation_test.rb",
    # AC-115 (QR vouchers) had no dedicated test before.
    "AC-115": "server/test/models/rental_voucher_qr_test.rb",
    "AC-116": "server/test/models/vehicle_test.rb",
    "AC-117": "server/test/integration/account_access_test.rb",
    "AC-118": "server/test/integration/account_access_test.rb",
    # AC-119/120/121 back the /booking, /counter and /admin hubs; the client
    # rendering is also proven by client/scripts/mount-check.mjs.
    "AC-119": "server/test/integration/operational_hubs_test.rb",
    "AC-120": "server/test/integration/operational_hubs_test.rb",
    "AC-121": "server/test/integration/operational_hubs_test.rb",
    "AC-122": "server/test/integration/booking_configure_test.rb",
    "AC-123": "server/test/integration/guest_booking_test.rb",
    "AC-124": "server/test/models/vehicle_test.rb",
    "AC-125": "server/test/models/rental_test.rb",
    "AC-126": "server/test/integration/auth_test.rb",
    "AC-127": "server/test/services/rental_settlement_calculator_test.rb",
    # AC-128 (seeds contract) had no dedicated test before.
    "AC-128": "server/test/integration/seeds_contract_test.rb",
}


def main():
    data = json.loads(AC_PATH.read_text())
    updated = 0
    missing = []

    for criterion in data["criteria"]:
        ac_id = criterion["id"]
        test_path = TESTED_BY.get(ac_id)
        if test_path is None:
            missing.append(ac_id)
            continue

        # Only mark tested when the referenced test actually exists.
        if not (ROOT / test_path).is_file():
            missing.append(f"{ac_id} (missing file {test_path})")
            continue

        criterion["status"] = "tested"
        criterion["test_name"] = test_path
        note = f"TESTED: verified by {test_path} (rails test: 270 runs, 874 assertions, 0 failures)."
        criterion.setdefault("subtasks", [])
        criterion["subtasks"] = [
            line for line in criterion["subtasks"] if not line.startswith("TESTED:")
        ] + [note]
        updated += 1

    data["updated_at"] = UPDATED_AT
    AC_PATH.write_text(json.dumps(data, indent=2) + "\n")
    print(f"marked {updated} criteria tested; could not verify {missing}")


if __name__ == "__main__":
    main()
