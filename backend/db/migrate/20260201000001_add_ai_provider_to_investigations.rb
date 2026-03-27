class AddAiProviderToInvestigations < ActiveRecord::Migration[7.1]
  def change
    add_column :investigations, :ai_provider, :string, default: "claude", null: false
  end
end
