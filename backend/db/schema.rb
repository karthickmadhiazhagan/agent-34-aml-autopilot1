# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_01_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "account_number", null: false
    t.string "account_type", default: "checking"
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.string "currency", default: "USD"
    t.string "status", default: "active"
    t.string "branch"
    t.date "opened_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_accounts_on_account_number", unique: true
    t.index ["customer_id"], name: "index_accounts_on_customer_id"
  end

  create_table "alerts", force: :cascade do |t|
    t.string "alert_id", null: false
    t.string "alert_type", null: false
    t.string "severity", default: "medium"
    t.string "status", default: "open"
    t.bigint "customer_id", null: false
    t.bigint "account_id", null: false
    t.text "description"
    t.string "rule_triggered"
    t.json "txn_refs"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_alerts_on_account_id"
    t.index ["alert_id"], name: "index_alerts_on_alert_id", unique: true
    t.index ["customer_id"], name: "index_alerts_on_customer_id"
    t.index ["severity"], name: "index_alerts_on_severity"
    t.index ["status"], name: "index_alerts_on_status"
  end

  create_table "customers", force: :cascade do |t|
    t.string "customer_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "nationality", default: "US"
    t.string "country_of_residence", default: "US"
    t.string "occupation"
    t.date "date_of_birth"
    t.integer "risk_score", default: 0
    t.string "kyc_status", default: "verified"
    t.boolean "is_pep", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customers_on_customer_id", unique: true
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.string "txn_ref", null: false
    t.bigint "from_account_id"
    t.bigint "to_account_id"
    t.decimal "amount", precision: 15, scale: 2
    t.string "currency", default: "USD"
    t.string "txn_type"
    t.text "description"
    t.string "location"
    t.string "counterparty_name"
    t.string "counterparty_country"
    t.string "status", default: "completed"
    t.datetime "transacted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_account_id"], name: "index_financial_transactions_on_from_account_id"
    t.index ["to_account_id"], name: "index_financial_transactions_on_to_account_id"
    t.index ["transacted_at"], name: "index_financial_transactions_on_transacted_at"
    t.index ["txn_ref"], name: "index_financial_transactions_on_txn_ref", unique: true
  end

  create_table "investigations", force: :cascade do |t|
    t.string "alert_id", null: false
    t.string "status", default: "pending", null: false
    t.text "alert_data"
    t.text "evidence"
    t.text "pattern_analysis"
    t.text "red_flag_mapping"
    t.text "narrative"
    t.text "qa_result"
    t.text "sar_output"
    t.string "approved_by"
    t.datetime "approved_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "narrative_approved_at"
    t.string "narrative_approved_by"
    t.datetime "sar_approved_at"
    t.string "sar_approved_by"
    t.integer "regeneration_count", default: 0
    t.string "ai_provider", default: "claude", null: false
    t.index ["alert_id"], name: "index_investigations_on_alert_id"
    t.index ["status"], name: "index_investigations_on_status"
  end

  add_foreign_key "accounts", "customers"
  add_foreign_key "alerts", "accounts"
  add_foreign_key "alerts", "customers"
  add_foreign_key "financial_transactions", "accounts", column: "from_account_id"
  add_foreign_key "financial_transactions", "accounts", column: "to_account_id"
end
