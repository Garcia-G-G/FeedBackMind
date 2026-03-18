# FeedbackMind — Prompts for Claude Code Max

## How to use

Copy each prompt below into Claude Code Max **in order**. Wait for it to complete before sending the next one. After each step, bring the output back for review.

---

## PROMPT 1 — Project Scaffolding + Gemfile + Base Config

```
I'm building a SaaS called FeedbackMind — an AI feedback synthesizer for Product Managers. Create the full Rails project scaffolding from scratch.

## Step 1: Create the Rails project

Run this exact command:

rails new feedbackmind \
  --database=postgresql \
  --skip-test \
  --skip-jbuilder \
  --css=tailwind \
  --javascript=esbuild \
  --skip-action-mailbox

Then cd into the project directory.

## Step 2: Replace the Gemfile

Replace the generated Gemfile with this exact content:

source "https://rubygems.org"

ruby "~> 3.2"

gem "rails", "~> 7.2"

# Core
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "redis", ">= 5.0"

# Frontend (Hotwire)
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "tailwindcss-rails", "~> 2.7"
gem "sprockets-rails"

# Background Jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 2.0"

# AI & Vector Search
gem "ruby-openai", "~> 7.3"
gem "neighbor", "~> 0.4"

# Authentication & Multi-tenancy
gem "devise", "~> 5.0"
gem "acts_as_tenant", "~> 1.0"

# Billing
gem "stripe", "~> 12.0"

# Email
gem "postmark-rails", "~> 0.22"

# Deployment
gem "kamal", "~> 2.0"
gem "thruster", "~> 0.1"

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: [:windows, :jruby]

group :development, :test do
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.4"
  gem "dotenv-rails", "~> 3.1"
  gem "debug", platforms: [:mri, :windows, :mswin]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener", "~> 1.10"
  gem "annotate", "~> 3.2"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "webmock", "~> 3.23"
  gem "vcr", "~> 6.3"
  gem "simplecov", require: false
  gem "capybara"
  gem "selenium-webdriver"
end

## Step 3: Run bundle install

bundle install

## Step 4: Initialize RSpec

rails generate rspec:install

## Step 5: Initialize Devise

rails generate devise:install

## Step 6: Create config/sidekiq.yml

Create config/sidekiq.yml with this content:

---
:concurrency: 5
:timeout: 25
:max_retries: 3

:queues:
  - [critical, 6]
  - [default, 4]
  - [low, 2]
  - [mailers, 3]

## Step 7: Create Procfile.dev

Create Procfile.dev with:

web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
js: yarn build --watch
worker: bundle exec sidekiq -C config/sidekiq.yml

## Step 8: Create Procfile (production)

Create Procfile with:

web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml

## Step 9: Create config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

## Step 10: Create config/initializers/openai.rb

OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openai, :api_key) || ENV.fetch("OPENAI_API_KEY", nil)
  config.log_errors = Rails.env.development?
end

## Step 11: Create config/initializers/stripe.rb

Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV.fetch("STRIPE_SECRET_KEY", nil)

## Step 12: Create .env.example

OPENAI_API_KEY=sk-your-key-here
REDIS_URL=redis://localhost:6379/0
STRIPE_SECRET_KEY=sk_test_your-key-here
STRIPE_PUBLISHABLE_KEY=pk_test_your-key-here
STRIPE_WEBHOOK_SECRET=whsec_your-secret-here
DATABASE_URL=postgres://localhost/feedbackmind_development
POSTMARK_API_KEY=your-postmark-key

## Step 13: Update .gitignore

Add these lines to .gitignore:

.env
.env.local
.env.production
tmp/
log/
node_modules/
coverage/

## Step 14: Create the directory structure for services, prompts, and jobs

mkdir -p app/services/openai
mkdir -p app/services/feedback
mkdir -p app/services/synthesis
mkdir -p app/prompts

After completing all steps, run `rails db:create` and show me the output of `tree -I 'node_modules|tmp|log' --dirsfirst` so I can verify the project structure.
```

---

## PROMPT 2 — Database Migrations (pgvector + HNSW + all tables)

```
In the feedbackmind Rails project, create all database migrations in this exact order. Each migration must be a separate file.

IMPORTANT: Use HNSW index instead of IVFFlat for the vector column — HNSW has 15x better query performance (40.5 QPS vs 2.6 QPS) and can be created on empty tables.

### Migration 1: Enable pgvector extension

rails generate migration EnablePgvector

Content:

class EnablePgvector < ActiveRecord::Migration[7.2]
  def up
    enable_extension "vector"
  end

  def down
    disable_extension "vector"
  end
end

### Migration 2: Create accounts table

rails generate migration CreateAccounts

class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.integer :plan, null: false, default: 0
      t.integer :feedback_count_this_month, default: 0
      t.timestamps
    end

    add_index :accounts, :subdomain, unique: true
    add_index :accounts, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"
    add_index :accounts, :plan
  end
end

### Migration 3: Create users table (Devise compatible)

rails generate migration CreateUsers

class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      # Devise fields
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      # Custom fields
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [:account_id, :role]
  end
end

### Migration 4: Create sources table

rails generate migration CreateSources

class CreateSources < ActiveRecord::Migration[7.2]
  def change
    create_table :sources do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :source_type, null: false
      t.jsonb :config, default: {}
      t.boolean :active, default: false, null: false
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :sources, [:account_id, :source_type]
    add_index :sources, [:account_id, :active]
  end
end

### Migration 5: Create feedbacks table

rails generate migration CreateFeedbacks

class CreateFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :feedbacks do |t|
      t.references :account, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: true
      t.string :external_id
      t.text :content, null: false
      t.string :author_email
      t.string :author_name
      t.integer :sentiment
      t.string :topics, array: true, default: []
      t.jsonb :metadata, default: {}
      t.datetime :received_at
      t.datetime :processed_at
      t.timestamps
    end

    add_index :feedbacks, [:source_id, :external_id], unique: true, where: "external_id IS NOT NULL"
    add_index :feedbacks, [:account_id, :received_at]
    add_index :feedbacks, :sentiment
    add_index :feedbacks, :topics, using: :gin
    add_index :feedbacks, :processed_at, where: "processed_at IS NULL", name: "index_feedbacks_unprocessed"
  end
end

### Migration 6: Add vector embedding column to feedbacks

rails generate migration AddEmbeddingToFeedbacks

class AddEmbeddingToFeedbacks < ActiveRecord::Migration[7.2]
  def change
    add_column :feedbacks, :embedding, :vector, limit: 1536
    add_index :feedbacks, :embedding,
              using: :hnsw,
              opclass: :vector_cosine_ops,
              name: "index_feedbacks_on_embedding_hnsw"
  end
end

### Migration 7: Create weekly_syntheses table

rails generate migration CreateWeeklySyntheses

class CreateWeeklySyntheses < ActiveRecord::Migration[7.2]
  def change
    create_table :weekly_syntheses do |t|
      t.references :account, null: false, foreign_key: true
      t.date :week_start, null: false
      t.integer :feedback_count, default: 0
      t.jsonb :top_themes, default: []
      t.text :executive_summary
      t.jsonb :biggest_risk, default: {}
      t.string :quick_wins, array: true, default: []
      t.datetime :sent_at
      t.timestamps
    end

    add_index :weekly_syntheses, [:account_id, :week_start], unique: true
    add_index :weekly_syntheses, :week_start
  end
end

### Migration 8: Create chat_messages table

rails generate migration CreateChatMessages

class CreateChatMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :chat_messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.text :content, null: false
      t.integer :source_feedback_ids, array: true, default: []
      t.timestamps
    end

    add_index :chat_messages, [:account_id, :created_at]
    add_index :chat_messages, [:user_id, :created_at]
  end
end

After creating all migration files, run:

rails db:migrate

Then show me the output of `rails db:migrate:status` and `rails runner "puts ActiveRecord::Base.connection.tables.sort"` so I can verify everything ran correctly.
```

---

## PROMPT 3 — Complete Models with Associations, Validations, Enums & Scopes

```
In the feedbackmind Rails project, create all model files. These models use the neighbor gem for pgvector, acts_as_tenant for multi-tenancy, and Devise for authentication.

### app/models/application_record.rb

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

### app/models/account.rb

class Account < ApplicationRecord
  # Associations
  has_many :users, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :weekly_syntheses, dependent: :destroy
  has_many :chat_messages, dependent: :destroy

  # Enums
  enum :plan, { starter: 0, growth: 1, scale: 2 }, prefix: true

  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/,
                       message: "must be lowercase alphanumeric with hyphens only" },
            length: { minimum: 3, maximum: 63 }
  validates :plan, presence: true
  validates :feedback_count_this_month, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { joins(:sources).where(sources: { active: true }).distinct }
  scope :with_plan, ->(plan) { where(plan: plan) }
  scope :billable, -> { where.not(stripe_subscription_id: nil) }

  # Plan Limits
  PLAN_LIMITS = {
    "starter" => { users: 1, sources: 3, feedbacks_per_month: 500, chat_enabled: false, prd_enabled: false },
    "growth"  => { users: 5, sources: 10, feedbacks_per_month: 2_000, chat_enabled: true, prd_enabled: false },
    "scale"   => { users: Float::INFINITY, sources: Float::INFINITY, feedbacks_per_month: Float::INFINITY, chat_enabled: true, prd_enabled: true }
  }.freeze

  def plan_limits
    PLAN_LIMITS[plan]
  end

  def feedback_limit_reached?
    return false if plan_scale?
    feedback_count_this_month >= plan_limits[:feedbacks_per_month]
  end

  def chat_enabled?
    plan_limits[:chat_enabled]
  end

  def prd_enabled?
    plan_limits[:prd_enabled]
  end

  def max_users
    plan_limits[:users]
  end

  def max_sources
    plan_limits[:sources]
  end

  def increment_feedback_count!
    increment!(:feedback_count_this_month)
  end

  def reset_feedback_count!
    update!(feedback_count_this_month: 0)
  end
end

### app/models/user.rb

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  belongs_to :account
  has_many :chat_messages, dependent: :destroy

  acts_as_tenant(:account)

  enum :role, { owner: 0, member: 1 }, prefix: true

  validates :role, presence: true

  scope :owners, -> { where(role: :owner) }
  scope :members, -> { where(role: :member) }

  def owner?
    role_owner?
  end

  def display_name
    name.presence || email.split("@").first
  end
end

### app/models/source.rb

class Source < ApplicationRecord
  belongs_to :account
  has_many :feedbacks, dependent: :destroy

  acts_as_tenant(:account)

  enum :source_type, {
    intercom: 0, gmail: 1, appstore: 2, playstore: 3,
    typeform: 4, jira: 5, slack: 6, csv: 7
  }, prefix: true

  validates :source_type, presence: true
  validate :within_source_limit, on: :create

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_type, ->(type) { where(source_type: type) }
  scope :needs_sync, -> { active.where("last_synced_at IS NULL OR last_synced_at < ?", 1.hour.ago) }
  scope :app_store_sources, -> { where(source_type: [:appstore, :playstore]).active }

  def mark_synced!
    update!(last_synced_at: Time.current)
  end

  def api_key
    config&.dig("api_key")
  end

  private

  def within_source_limit
    return if account.nil?
    max = account.max_sources
    return if max == Float::INFINITY
    if account.sources.count >= max
      errors.add(:base, "Source limit reached for your plan (#{max}). Please upgrade.")
    end
  end
end

### app/models/feedback.rb

class Feedback < ApplicationRecord
  has_neighbors :embedding

  belongs_to :account
  belongs_to :source

  acts_as_tenant(:account)

  enum :sentiment, { positive: 0, neutral: 1, negative: 2 }, prefix: true

  validates :content, presence: true
  validates :external_id, uniqueness: { scope: :source_id }, allow_nil: true

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :with_embedding, -> { where.not(embedding: nil) }
  scope :without_embedding, -> { where(embedding: nil) }
  scope :recent, -> { order(received_at: :desc) }
  scope :this_week, -> { where(received_at: 1.week.ago.beginning_of_day..Time.current) }
  scope :last_7_days, -> { where("received_at >= ?", 7.days.ago.beginning_of_day) }
  scope :by_sentiment, ->(sentiment) { where(sentiment: sentiment) }
  scope :by_topic, ->(topic) { where("? = ANY(topics)", topic) }
  scope :from_source_type, ->(type) { joins(:source).where(sources: { source_type: type }) }

  after_create :increment_account_feedback_count
  after_create_commit :enqueue_embedding_job

  # Semantic search via neighbor gem + HNSW index
  scope :nearest_to, ->(embedding_vector, limit: 20) {
    nearest_neighbors(:embedding, embedding_vector, distance: "cosine").limit(limit)
  }

  def processed?
    processed_at.present?
  end

  def has_embedding?
    embedding.present?
  end

  def mark_processed!
    update!(processed_at: Time.current)
  end

  def to_context_string
    parts = []
    parts << "[Source: #{source.source_type}]"
    parts << "[Date: #{received_at&.strftime('%Y-%m-%d')}]"
    parts << "[Author: #{author_name || author_email || 'Anonymous'}]"
    parts << "[Sentiment: #{sentiment}]"
    parts << content
    parts.join(" ")
  end

  private

  def increment_account_feedback_count
    account.increment_feedback_count!
  end

  def enqueue_embedding_job
    FeedbackEmbedJob.perform_async(id)
  end
end

### app/models/weekly_synthesis.rb

class WeeklySynthesis < ApplicationRecord
  belongs_to :account

  acts_as_tenant(:account)

  validates :week_start, presence: true
  validates :week_start, uniqueness: { scope: :account_id }

  scope :recent, -> { order(week_start: :desc) }
  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }
  scope :for_week, ->(date) { where(week_start: date.beginning_of_week(:monday)) }

  def sent?
    sent_at.present?
  end

  def mark_sent!
    update!(sent_at: Time.current)
  end

  def week_end
    week_start + 6.days
  end

  def week_label
    "#{week_start.strftime('%b %d')} — #{week_end.strftime('%b %d, %Y')}"
  end

  def themes
    (top_themes || []).map { |t| OpenStruct.new(t) }
  end

  def risk
    OpenStruct.new(biggest_risk) if biggest_risk.present?
  end
end

### app/models/chat_message.rb

class ChatMessage < ApplicationRecord
  belongs_to :account
  belongs_to :user

  acts_as_tenant(:account)

  enum :role, { user: 0, assistant: 1 }, prefix: true

  validates :content, presence: true
  validates :role, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :from_user_role, -> { where(role: :user) }
  scope :from_assistant, -> { where(role: :assistant) }

  def source_feedbacks
    return Feedback.none if source_feedback_ids.blank?
    Feedback.where(id: source_feedback_ids)
  end
end

After creating all models, run `rails runner "puts 'Models loaded OK'"` to verify they all load without errors. Also show me `rails runner "ApplicationRecord.descendants.map(&:name).sort"` to confirm all models are registered.
```

---

## PROMPT 4 — Sidekiq Jobs (FeedbackIngestJob, FeedbackEmbedJob, WeeklySynthesisJob, and more)

```
In the feedbackmind Rails project, create all Sidekiq background jobs. These jobs handle the core AI pipeline: ingesting raw feedback, generating embeddings, classifying sentiment/topics, running weekly synthesis, and resetting monthly counters.

### app/jobs/application_job.rb

class ApplicationJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def self.perform_unique_async(*args)
    # Simple idempotency check using Sidekiq's built-in uniqueness
    perform_async(*args)
  end
end

### app/jobs/feedback_ingest_job.rb

class FeedbackIngestJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  # Receives a raw feedback hash from any source adapter, normalizes it
  # to the internal Feedback schema, deduplicates via external_id,
  # and enqueues FeedbackEmbedJob for AI processing.
  #
  # @param account_id [Integer]
  # @param source_id [Integer]
  # @param raw_data [Hash] with keys:
  #   - external_id (String, optional)
  #   - content (String, required)
  #   - author_email (String, optional)
  #   - author_name (String, optional)
  #   - metadata (Hash, optional)
  #   - received_at (String/ISO8601, optional)
  def perform(account_id, source_id, raw_data)
    account = Account.find(account_id)
    source = Source.find(source_id)

    # Enforce plan limits
    if account.feedback_limit_reached?
      Rails.logger.warn("[FeedbackIngestJob] Account #{account_id} hit feedback limit. Skipping.")
      # TODO: Trigger upgrade notification
      return
    end

    raw = raw_data.with_indifferent_access

    # Deduplicate by external_id
    if raw[:external_id].present?
      existing = Feedback.find_by(source_id: source_id, external_id: raw[:external_id])
      if existing
        Rails.logger.info("[FeedbackIngestJob] Duplicate feedback #{raw[:external_id]} for source #{source_id}. Skipping.")
        return
      end
    end

    feedback = Feedback.create!(
      account: account,
      source: source,
      external_id: raw[:external_id],
      content: raw[:content],
      author_email: raw[:author_email],
      author_name: raw[:author_name],
      metadata: raw[:metadata] || {},
      received_at: raw[:received_at] ? Time.parse(raw[:received_at]) : Time.current
    )

    Rails.logger.info("[FeedbackIngestJob] Created feedback ##{feedback.id} for account #{account_id}")
    # FeedbackEmbedJob is enqueued automatically via Feedback after_create_commit callback
  end
end

### app/jobs/feedback_embed_job.rb

class FeedbackEmbedJob
  include Sidekiq::Job

  sidekiq_options queue: :default, retry: 3

  EMBEDDING_MODEL = "text-embedding-3-small".freeze
  CLASSIFICATION_MODEL = "gpt-4.1-mini".freeze

  # Takes a Feedback record, generates its vector embedding using OpenAI,
  # classifies sentiment and generates topic tags, then marks it as processed.
  #
  # @param feedback_id [Integer]
  def perform(feedback_id)
    feedback = Feedback.find_by(id: feedback_id)
    return unless feedback
    return if feedback.processed?

    client = OpenAI::Client.new

    # Step 1: Generate embedding vector via text-embedding-3-small
    embedding_response = client.embeddings(
      parameters: {
        model: EMBEDDING_MODEL,
        input: feedback.content.truncate(8000) # Safety limit
      }
    )

    embedding_vector = embedding_response.dig("data", 0, "embedding")

    unless embedding_vector
      Rails.logger.error("[FeedbackEmbedJob] No embedding returned for feedback ##{feedback_id}")
      raise "Embedding generation failed for feedback ##{feedback_id}"
    end

    # Step 2: Classify sentiment + generate topic tags via gpt-4.1-mini
    classification_response = client.chat(
      parameters: {
        model: CLASSIFICATION_MODEL,
        response_format: { type: "json_object" },
        temperature: 0.1,
        max_tokens: 200,
        messages: [
          {
            role: "system",
            content: <<~PROMPT
              You are a feedback classifier for a SaaS product. Analyze the user feedback below and return ONLY valid JSON:

              {
                "sentiment": "positive" | "neutral" | "negative",
                "topics": ["topic1", "topic2", "topic3"]
              }

              Rules:
              - sentiment: classify the overall tone
              - topics: 1-5 short lowercase tags describing what the feedback is about (e.g., "onboarding", "billing", "performance", "ui", "mobile", "pricing", "support")
              - Return ONLY the JSON, no explanations
            PROMPT
          },
          {
            role: "user",
            content: feedback.content.truncate(4000)
          }
        ]
      }
    )

    raw_json = classification_response.dig("choices", 0, "message", "content")
    classification = JSON.parse(raw_json)

    # Step 3: Update the feedback record with all AI-generated data
    feedback.update!(
      embedding: embedding_vector,
      sentiment: classification["sentiment"],
      topics: Array(classification["topics"]).map(&:downcase).uniq.first(5),
      processed_at: Time.current
    )

    Rails.logger.info("[FeedbackEmbedJob] Processed feedback ##{feedback_id}: sentiment=#{classification['sentiment']}, topics=#{classification['topics']}")

  rescue JSON::ParserError => e
    Rails.logger.error("[FeedbackEmbedJob] JSON parse error for feedback ##{feedback_id}: #{e.message}")
    raise # Retry via Sidekiq
  rescue Faraday::Error => e
    Rails.logger.error("[FeedbackEmbedJob] OpenAI API error for feedback ##{feedback_id}: #{e.message}")
    raise # Retry via Sidekiq
  end
end

### app/jobs/weekly_synthesis_job.rb

class WeeklySynthesisJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, retry: 2

  SYNTHESIS_MODEL = "gpt-4.1".freeze

  # Runs every Monday at 8am UTC via sidekiq-cron.
  # For each active account: collects last 7 days of feedback,
  # groups by semantic similarity, sends to GPT-4.1 for synthesis,
  # saves the WeeklySynthesis record, and sends the email digest.
  def perform
    week_start = Date.current.beginning_of_week(:monday)

    Account.active.find_each do |account|
      ActsAsTenant.with_tenant(account) do
        process_account(account, week_start)
      end
    rescue => e
      Rails.logger.error("[WeeklySynthesisJob] Error processing account #{account.id}: #{e.message}")
      # Continue with next account, don't let one failure block all
    end
  end

  private

  def process_account(account, week_start)
    # Skip if synthesis already exists for this week
    return if WeeklySynthesis.exists?(account: account, week_start: week_start)

    feedbacks = account.feedbacks.processed.last_7_days
    return if feedbacks.empty?

    # Group feedbacks by semantic similarity for better synthesis
    clustered_text = build_clustered_context(feedbacks)

    # Call GPT-4.1 for synthesis
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: SYNTHESIS_MODEL,
        response_format: { type: "json_object" },
        temperature: 0.3,
        max_tokens: 2000,
        messages: [
          { role: "system", content: synthesis_prompt(feedbacks.count, week_start, week_start + 6.days) },
          { role: "user", content: clustered_text }
        ]
      }
    )

    raw_json = response.dig("choices", 0, "message", "content")
    result = JSON.parse(raw_json)

    # Save the synthesis
    synthesis = WeeklySynthesis.create!(
      account: account,
      week_start: week_start,
      feedback_count: feedbacks.count,
      top_themes: result["top_themes"] || [],
      executive_summary: result["executive_summary"],
      biggest_risk: result["biggest_risk"] || {},
      quick_wins: result["quick_wins"] || []
    )

    # Send email digest to all account users
    WeeklyDigestMailer.digest_email(synthesis).deliver_later
    synthesis.mark_sent!

    Rails.logger.info("[WeeklySynthesisJob] Synthesis created for account #{account.id}, week #{week_start}")
  end

  def build_clustered_context(feedbacks)
    # Group feedbacks by topics for thematic clustering
    grouped = feedbacks.group_by { |f| f.topics&.first || "uncategorized" }

    grouped.map do |topic, items|
      section = "## Topic: #{topic} (#{items.count} feedbacks)\n\n"
      items.each do |f|
        section += "- [#{f.sentiment}] [#{f.source.source_type}] [#{f.received_at&.strftime('%Y-%m-%d')}]: #{f.content.truncate(500)}\n"
      end
      section
    end.join("\n\n")
  end

  def synthesis_prompt(feedback_count, week_start, week_end)
    File.read(Rails.root.join("app/prompts/weekly_synthesis.txt"))
        .gsub("{{feedback_count}}", feedback_count.to_s)
        .gsub("{{week_start}}", week_start.strftime("%B %d, %Y"))
        .gsub("{{week_end}}", week_end.strftime("%B %d, %Y"))
  end
end

### app/jobs/app_store_scraper_job.rb

class AppStoreScraperJob
  include Sidekiq::Job

  sidekiq_options queue: :low, retry: 2

  # Runs every 6 hours via sidekiq-cron.
  # Scrapes new reviews for accounts with active appstore/playstore sources.
  def perform
    Source.app_store_sources.includes(:account).find_each do |source|
      ActsAsTenant.with_tenant(source.account) do
        scrape_reviews(source)
      end
    rescue => e
      Rails.logger.error("[AppStoreScraperJob] Error scraping source #{source.id}: #{e.message}")
    end
  end

  private

  def scrape_reviews(source)
    # TODO: Implement App Store / Play Store review scraping
    # This would use the app_id from source.config to fetch new reviews
    # and enqueue each as a FeedbackIngestJob
    #
    # Example flow:
    # reviews = AppStoreClient.fetch_reviews(source.config["app_id"], since: source.last_synced_at)
    # reviews.each do |review|
    #   FeedbackIngestJob.perform_async(source.account_id, source.id, {
    #     external_id: review[:id],
    #     content: review[:text],
    #     author_name: review[:author],
    #     metadata: { rating: review[:rating], title: review[:title] },
    #     received_at: review[:date].iso8601
    #   })
    # end
    # source.mark_synced!
    Rails.logger.info("[AppStoreScraperJob] Scraping not yet implemented for source #{source.id}")
  end
end

### app/jobs/monthly_feedback_count_reset_job.rb

class MonthlyFeedbackCountResetJob
  include Sidekiq::Job

  sidekiq_options queue: :critical, retry: 1

  # Runs on the 1st of each month via sidekiq-cron.
  # Resets feedback_count_this_month to 0 for all accounts.
  def perform
    count = Account.update_all(feedback_count_this_month: 0)
    Rails.logger.info("[MonthlyFeedbackCountResetJob] Reset feedback count for #{count} accounts")
  end
end

### Update config/initializers/sidekiq_cron.rb — Create this file:

# Scheduled jobs via sidekiq-cron
Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule = {
      "weekly_synthesis" => {
        "cron" => "0 8 * * 1",                          # Every Monday at 8:00 AM UTC
        "class" => "WeeklySynthesisJob",
        "queue" => "critical",
        "description" => "Generate weekly feedback synthesis for all active accounts"
      },
      "app_store_scraper" => {
        "cron" => "0 */6 * * *",                         # Every 6 hours
        "class" => "AppStoreScraperJob",
        "queue" => "low",
        "description" => "Scrape new App Store and Play Store reviews"
      },
      "monthly_feedback_reset" => {
        "cron" => "0 0 1 * *",                           # 1st of each month at midnight UTC
        "class" => "MonthlyFeedbackCountResetJob",
        "queue" => "critical",
        "description" => "Reset monthly feedback counters for all accounts"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end

After creating all files, show me the directory listing of app/jobs/ and config/initializers/ to verify.
```

---

## PROMPT 5 — Services + OpenAI Prompts + Mailer

```
In the feedbackmind Rails project, create the service layer and prompt templates. These handle the OpenAI API interactions and email delivery.

### app/services/openai/client.rb

module Openai
  class Client
    attr_reader :client

    def initialize
      @client = OpenAI::Client.new
    end

    # Generate embedding for a text string using text-embedding-3-small
    # Returns an array of 1536 floats
    def embed(text, model: "text-embedding-3-small")
      response = client.embeddings(
        parameters: {
          model: model,
          input: text.truncate(8000)
        }
      )
      response.dig("data", 0, "embedding")
    end

    # Chat completion with JSON response format
    def chat_json(messages:, model: "gpt-4.1", temperature: 0.3, max_tokens: 2000)
      response = client.chat(
        parameters: {
          model: model,
          response_format: { type: "json_object" },
          temperature: temperature,
          max_tokens: max_tokens,
          messages: messages
        }
      )
      raw = response.dig("choices", 0, "message", "content")
      JSON.parse(raw)
    end

    # Chat completion with plain text response
    def chat(messages:, model: "gpt-4.1", temperature: 0.5, max_tokens: 1500)
      response = client.chat(
        parameters: {
          model: model,
          temperature: temperature,
          max_tokens: max_tokens,
          messages: messages
        }
      )
      response.dig("choices", 0, "message", "content")
    end
  end
end

### app/services/feedback/classifier.rb

module Feedback
  class Classifier
    MODEL = "gpt-4.1-mini".freeze

    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Classify a single feedback's sentiment and generate topic tags
    # Returns { sentiment: String, topics: Array<String> }
    def classify(text)
      @client.chat_json(
        model: MODEL,
        temperature: 0.1,
        max_tokens: 200,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: text.truncate(4000) }
        ]
      )
    end

    private

    def system_prompt
      <<~PROMPT
        You are a feedback classifier for a SaaS product. Analyze the user feedback and return ONLY valid JSON:

        {
          "sentiment": "positive" | "neutral" | "negative",
          "topics": ["topic1", "topic2", "topic3"]
        }

        Rules:
        - sentiment: classify the overall tone of the feedback
        - topics: 1-5 short lowercase tags (e.g., "onboarding", "billing", "performance", "ui", "mobile", "pricing", "support", "bugs", "feature-request")
        - Return ONLY the JSON object, nothing else
      PROMPT
    end
  end
end

### app/services/feedback/embedder.rb

module Feedback
  class Embedder
    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Generate embedding vector for a feedback's content
    # Returns Array<Float> of 1536 dimensions
    def embed(text)
      @client.embed(text)
    end
  end
end

### app/services/synthesis/weekly_builder.rb

module Synthesis
  class WeeklyBuilder
    MODEL = "gpt-4.1".freeze

    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Build a weekly synthesis for an account's recent feedback
    # Returns parsed JSON hash matching the WeeklySynthesis schema
    def build(feedbacks:, week_start:, week_end:)
      clustered_text = cluster_feedbacks(feedbacks)
      prompt = load_prompt(feedbacks.count, week_start, week_end)

      @client.chat_json(
        model: MODEL,
        temperature: 0.3,
        max_tokens: 2000,
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: clustered_text }
        ]
      )
    end

    private

    def cluster_feedbacks(feedbacks)
      grouped = feedbacks.group_by { |f| f.topics&.first || "uncategorized" }

      grouped.map do |topic, items|
        section = "## Topic: #{topic} (#{items.count} feedbacks)\n\n"
        items.each do |f|
          section += "- [#{f.sentiment}] [#{f.source.source_type}] [#{f.received_at&.strftime('%Y-%m-%d')}]: #{f.content.truncate(500)}\n"
        end
        section
      end.join("\n\n")
    end

    def load_prompt(count, week_start, week_end)
      template = File.read(Rails.root.join("app/prompts/weekly_synthesis.txt"))
      template
        .gsub("{{feedback_count}}", count.to_s)
        .gsub("{{week_start}}", week_start.strftime("%B %d, %Y"))
        .gsub("{{week_end}}", week_end.strftime("%B %d, %Y"))
    end
  end
end

### app/services/synthesis/rag_chat.rb

module Synthesis
  class RagChat
    MODEL = "gpt-4.1".freeze
    MAX_CONTEXT_FEEDBACKS = 20

    def initialize(client: Openai::Client.new)
      @client = client
    end

    # Answer a PM's question using RAG over the feedback history
    # Returns { answer: String, source_feedback_ids: Array<Integer> }
    def ask(account:, question:)
      # Step 1: Embed the question
      question_embedding = @client.embed(question)

      # Step 2: Find most relevant feedbacks via semantic search (HNSW cosine)
      relevant_feedbacks = account.feedbacks
                                  .processed
                                  .with_embedding
                                  .nearest_to(question_embedding, limit: MAX_CONTEXT_FEEDBACKS)

      # Step 3: Build context string from relevant feedbacks
      context = relevant_feedbacks.map(&:to_context_string).join("\n\n---\n\n")

      # Step 4: Generate answer with GPT-4.1
      prompt = load_prompt(account.name)
      answer = @client.chat(
        model: MODEL,
        temperature: 0.4,
        max_tokens: 1500,
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: "Relevant feedback context:\n\n#{context}\n\n---\n\nQuestion: #{question}" }
        ]
      )

      {
        answer: answer,
        source_feedback_ids: relevant_feedbacks.map(&:id)
      }
    end

    private

    def load_prompt(account_name)
      File.read(Rails.root.join("app/prompts/rag_chat.txt"))
          .gsub("{{account_name}}", account_name)
    end
  end
end

### app/prompts/weekly_synthesis.txt

Create this file with this exact content:

You are a senior Product Manager with 10 years of experience analyzing SaaS user feedback.

Below are {{feedback_count}} pieces of user feedback received between {{week_start}} and {{week_end}}, grouped by thematic similarity.

Analyze considering: topic frequency, predominant sentiment, business urgency, and quick improvement opportunities.

Return ONLY a valid JSON with this exact structure, no extra text, no backticks, no explanations:

{
  "top_themes": [
    {
      "title": "short string (max 5 words)",
      "description": "1-2 sentence string explaining the problem",
      "feedback_count": number,
      "urgency": "low|medium|high|critical",
      "sample_quotes": ["verbatim quote 1", "quote 2", "quote 3"],
      "suggested_action": "specific actionable string the team could take"
    }
  ],
  "executive_summary": "3-4 sentence string summarizing product health from the user perspective",
  "biggest_risk": {
    "theme": "string",
    "potential_impact": "string: retention or revenue impact if left unaddressed"
  },
  "quick_wins": ["action 1", "action 2", "action 3"]
}

Max 5 themes in top_themes, ordered by urgency descending.

### app/prompts/rag_chat.txt

Create this file with this exact content:

You are the product assistant for {{account_name}}. You have access to their users' feedback history.

When answering questions:
- Be direct, specific, and data-driven
- Cite real feedback when relevant — mention the source type and date
- If multiple users mention the same issue, note the frequency
- If there's not enough information in the context to answer well, say so clearly
- Never make up feedback that isn't in the context
- Quantify when possible ("3 out of 20 feedbacks mention...")

### app/prompts/feedback_classifier.txt

Create this file with this exact content:

You are a feedback classifier for a SaaS product. Analyze the user feedback and return ONLY valid JSON:

{
  "sentiment": "positive" | "neutral" | "negative",
  "topics": ["topic1", "topic2", "topic3"]
}

Rules:
- sentiment: classify the overall tone of the feedback
- topics: 1-5 short lowercase tags describing what the feedback is about
- Common topics include: onboarding, billing, performance, ui, mobile, pricing, support, bugs, feature-request, integrations, documentation, security, api, notifications, search, export, dashboard
- Return ONLY the JSON object, nothing else

### app/mailers/weekly_digest_mailer.rb

class WeeklyDigestMailer < ApplicationMailer
  def digest_email(synthesis)
    @synthesis = synthesis
    @account = synthesis.account
    @themes = synthesis.themes
    @risk = synthesis.risk

    mail(
      to: @account.users.pluck(:email),
      subject: "#{@account.name} — Weekly Feedback Digest (#{@synthesis.week_label})"
    )
  end
end

### app/mailers/application_mailer.rb

class ApplicationMailer < ActionMailer::Base
  default from: "FeedbackMind <digest@feedbackmind.com>"
  layout "mailer"
end

After creating all files, show me the output of:
- `find app/services -name "*.rb" | sort`
- `find app/prompts -name "*.txt" | sort`
- `find app/mailers -name "*.rb" | sort`
- `find app/jobs -name "*.rb" | sort`
```

---

## PROMPT 6 — RSpec Factories + Base Specs

```
In the feedbackmind Rails project, create the test factories and initial model specs to verify the data layer works correctly.

### spec/factories/accounts.rb

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    subdomain { Faker::Internet.slug(glue: "-") }
    plan { :starter }
    feedback_count_this_month { 0 }

    trait :growth do
      plan { :growth }
    end

    trait :scale do
      plan { :scale }
    end

    trait :with_stripe do
      stripe_customer_id { "cus_#{SecureRandom.hex(8)}" }
      stripe_subscription_id { "sub_#{SecureRandom.hex(8)}" }
    end
  end
end

### spec/factories/users.rb

FactoryBot.define do
  factory :user do
    account
    email { Faker::Internet.unique.email }
    password { "password123!" }
    role { :owner }

    trait :member do
      role { :member }
    end
  end
end

### spec/factories/sources.rb

FactoryBot.define do
  factory :source do
    account
    source_type { :intercom }
    active { true }
    config { { "api_key" => "test_key_123" } }

    trait :inactive do
      active { false }
    end

    Source.source_types.keys.each do |type|
      trait type.to_sym do
        source_type { type }
      end
    end
  end
end

### spec/factories/feedbacks.rb

FactoryBot.define do
  factory :feedback do
    account
    source
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    received_at { Faker::Time.between(from: 1.week.ago, to: Time.current) }

    trait :processed do
      sentiment { [:positive, :neutral, :negative].sample }
      topics { Faker::Lorem.words(number: 3).map(&:downcase) }
      processed_at { Time.current }
      # Note: embedding would need to be set manually or via a mock
    end

    trait :unprocessed do
      sentiment { nil }
      topics { [] }
      processed_at { nil }
      embedding { nil }
    end

    trait :positive do
      sentiment { :positive }
    end

    trait :negative do
      sentiment { :negative }
    end
  end
end

### spec/factories/weekly_syntheses.rb

FactoryBot.define do
  factory :weekly_synthesis do
    account
    week_start { Date.current.beginning_of_week(:monday) }
    feedback_count { 25 }
    executive_summary { "Product health is stable with growing feature requests around integrations." }
    top_themes { [{ "title" => "Integration Issues", "description" => "Users want more integrations", "feedback_count" => 8, "urgency" => "high", "sample_quotes" => ["Need Slack integration"], "suggested_action" => "Prioritize Slack integration" }] }
    biggest_risk { { "theme" => "Churn risk", "potential_impact" => "15% of users mentioned leaving" } }
    quick_wins { ["Fix onboarding flow", "Add CSV export"] }
  end
end

### spec/factories/chat_messages.rb

FactoryBot.define do
  factory :chat_message do
    account
    user
    role { :user }
    content { Faker::Lorem.question }

    trait :assistant do
      role { :assistant }
      source_feedback_ids { [1, 2, 3] }
    end
  end
end

### spec/support/factory_bot.rb

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

### spec/support/shoulda_matchers.rb

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

### spec/models/account_spec.rb

require "rails_helper"

RSpec.describe Account, type: :model do
  describe "validations" do
    subject { build(:account) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }
    it { should validate_presence_of(:plan) }
  end

  describe "associations" do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:sources).dependent(:destroy) }
    it { should have_many(:feedbacks).dependent(:destroy) }
    it { should have_many(:weekly_syntheses).dependent(:destroy) }
    it { should have_many(:chat_messages).dependent(:destroy) }
  end

  describe "#feedback_limit_reached?" do
    it "returns true when starter plan hits 500" do
      account = build(:account, plan: :starter, feedback_count_this_month: 500)
      expect(account.feedback_limit_reached?).to be true
    end

    it "returns false for scale plan regardless of count" do
      account = build(:account, :scale, feedback_count_this_month: 999_999)
      expect(account.feedback_limit_reached?).to be false
    end

    it "returns false when under limit" do
      account = build(:account, plan: :starter, feedback_count_this_month: 100)
      expect(account.feedback_limit_reached?).to be false
    end
  end

  describe "#plan_limits" do
    it "returns correct limits for growth plan" do
      account = build(:account, :growth)
      expect(account.plan_limits[:feedbacks_per_month]).to eq(2_000)
      expect(account.plan_limits[:chat_enabled]).to be true
    end
  end
end

### spec/models/feedback_spec.rb

require "rails_helper"

RSpec.describe Feedback, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
  end

  describe "associations" do
    it { should belong_to(:account) }
    it { should belong_to(:source) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:source) { create(:source, account: account) }

    before do
      ActsAsTenant.current_tenant = account
    end

    it ".unprocessed returns feedbacks without processed_at" do
      processed = create(:feedback, :processed, account: account, source: source)
      unprocessed = create(:feedback, :unprocessed, account: account, source: source)

      expect(Feedback.unprocessed).to include(unprocessed)
      expect(Feedback.unprocessed).not_to include(processed)
    end

    it ".by_topic finds feedbacks with matching topic" do
      fb = create(:feedback, account: account, source: source, topics: ["billing", "pricing"])
      other = create(:feedback, account: account, source: source, topics: ["onboarding"])

      expect(Feedback.by_topic("billing")).to include(fb)
      expect(Feedback.by_topic("billing")).not_to include(other)
    end
  end
end

After creating all files, run `bundle exec rspec --dry-run` to verify the test suite loads without errors. Show me the output.
```

---

## VERIFICATION CHECKLIST

After running all 6 prompts, verify:

1. `tree -I 'node_modules|tmp|log|vendor' --dirsfirst -L 3` — full project structure
2. `rails db:migrate:status` — all migrations ran in order
3. `rails runner "puts ApplicationRecord.descendants.map(&:name).sort"` — all 6 models loaded
4. `bundle exec rspec --dry-run` — test suite loads
5. `cat config/initializers/sidekiq_cron.rb` — 3 scheduled jobs configured
6. `find app/prompts -name "*.txt"` — 3 prompt templates exist
7. `find app/services -name "*.rb"` — 5 service objects exist
