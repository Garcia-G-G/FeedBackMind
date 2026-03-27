class CreateNpsSurveysAndResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :nps_surveys do |t|
      t.references :account, null: false, foreign_key: true

      t.string :name, null: false
      t.string :question, null: false, default: "How likely are you to recommend us to a friend or colleague?"
      t.string :followup_question, default: "What's the main reason for your score?"
      t.string :thank_you_message, default: "Thanks for your feedback!"
      t.string :survey_token, null: false
      t.boolean :active, default: true
      t.string :brand_color, default: "#1c1917"
      t.string :position, default: "bottom-right"
      t.integer :responses_count, default: 0, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :nps_surveys, [:account_id, :active]
    add_index :nps_surveys, :survey_token, unique: true

    create_table :nps_responses do |t|
      t.references :nps_survey, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :feedback, null: true, foreign_key: true

      t.integer :score, null: false
      t.text :comment
      t.string :respondent_email
      t.string :respondent_name
      t.string :respondent_id
      t.string :page_url
      t.string :category
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :nps_responses, [:nps_survey_id, :created_at]
    add_index :nps_responses, [:account_id, :category]
    add_index :nps_responses, [:nps_survey_id, :respondent_email]
  end
end
