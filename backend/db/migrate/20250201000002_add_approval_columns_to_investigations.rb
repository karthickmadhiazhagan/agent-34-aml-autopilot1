class AddApprovalColumnsToInvestigations < ActiveRecord::Migration[7.1]
  def change
    add_column :investigations, :narrative_approved_at, :datetime
    add_column :investigations, :narrative_approved_by, :string
    add_column :investigations, :sar_approved_at, :datetime
    add_column :investigations, :sar_approved_by, :string
    add_column :investigations, :regeneration_count, :integer, default: 0
  end
end
