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

ActiveRecord::Schema[7.2].define(version: 2025_02_01_000002) do
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
    t.index ["alert_id"], name: "index_investigations_on_alert_id"
    t.index ["status"], name: "index_investigations_on_status"
  end
end
