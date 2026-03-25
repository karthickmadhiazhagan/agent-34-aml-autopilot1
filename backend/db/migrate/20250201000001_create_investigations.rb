class CreateInvestigations < ActiveRecord::Migration[7.1]
  def change
    create_table :investigations do |t|
      t.string  :alert_id,           null: false
      t.string  :status,             null: false, default: "pending"
      t.text    :alert_data
      t.text    :evidence
      t.text    :pattern_analysis
      t.text    :red_flag_mapping
      t.text    :narrative
      t.text    :qa_result
      t.text    :sar_output
      t.string  :approved_by
      t.datetime :approved_at
      t.text    :error_message

      t.timestamps
    end

    add_index :investigations, :alert_id
    add_index :investigations, :status
  end
end
