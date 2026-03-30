class AddAllowedOriginsToNpsSurveys < ActiveRecord::Migration[7.2]
  def change
    add_column :nps_surveys, :allowed_origins, :text
  end
end
