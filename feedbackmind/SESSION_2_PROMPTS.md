# FeedbackMind — Session 2 Prompts (Backend API + Webhooks)

## Instructions

First, paste the content of `SESSION_2_CONTEXT.md` to Claude Code Max so it knows what was built in Session 1 and what we're building now. Then execute each prompt in order.

---

## PROMPT 7 — Routes + Base Controllers + API Authentication + Migration for API tokens

```
In the feedbackmind Rails project, set up the routing structure, base controllers, and API token authentication.

### Step 1: Create a migration to add api_token to accounts

rails generate migration AddApiTokenToAccounts api_token:string:uniq

Edit the migration file to be:

class AddApiTokenToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :api_token, :string
    add_index :accounts, :api_token, unique: true

    # Backfill existing accounts with tokens
    reversible do |dir|
      dir.up do
        Account.find_each do |account|
          account.update_column(:api_token, SecureRandom.hex(32))
        end
      end
    end
  end
end

Run: rails db:migrate

### Step 2: Update the Account model

Add this to app/models/account.rb, inside the class body:

  # Generate API token before creation
  before_create :generate_api_token

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end

### Step 3: Create config/routes.rb

Replace the entire config/routes.rb with:

Rails.application.routes.draw do
  # === Devise Authentication ===
  devise_for :users

  # === Sidekiq Web Dashboard (admin only) ===
  require "sidekiq/web"
  require "sidekiq/cron/web"
  authenticate :user, ->(user) { user.role_owner? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # === Health Check ===
  get "up" => "rails/health#show", as: :rails_health_check

  # === Webhook Receivers (no auth — verified by signature) ===
  namespace :webhooks, defaults: { format: :json } do
    post "intercom", to: "intercom#create"
    post "slack",    to: "slack#create"
    post "typeform", to: "typeform#create"
    post "jira",     to: "jira#create"
    post "gmail",    to: "gmail#create"
    post "stripe",   to: "stripe#create"
  end

  # === API v1 (token auth) ===
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Account
      resource :account, only: [:show, :update]

      # Sources CRUD
      resources :sources, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :activate
          post :deactivate
        end
      end

      # Feedbacks (read-only + CSV import)
      resources :feedbacks, only: [:index, :show] do
        collection do
          post :import_csv
        end
      end

      # Chat
      resources :chat_messages, only: [:index, :create], path: "chat"

      # Weekly Syntheses
      resources :syntheses, only: [:index, :show], controller: "syntheses"

      # Billing
      namespace :billing do
        post "checkout", to: "checkout#create"
        post "portal",   to: "portal#create"
      end
    end
  end

  # === Root (will be dashboard later) ===
  root "pages#home"
end

### Step 4: Create app/controllers/concerns/api_authenticatable.rb

module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_token!
    before_action :set_current_tenant
  end

  private

  # Authenticate via Bearer token in Authorization header
  # Example: Authorization: Bearer abc123def456...
  def authenticate_api_token!
    token = extract_bearer_token
    @current_account = Account.find_by(api_token: token)

    unless @current_account
      render json: { error: "Invalid or missing API token", code: "unauthorized" }, status: :unauthorized
    end
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")
    header.split(" ").last
  end

  def set_current_tenant
    ActsAsTenant.current_tenant = @current_account
  end

  def current_account
    @current_account
  end
end

### Step 5: Create app/controllers/concerns/paginatable.rb

module Paginatable
  extend ActiveSupport::Concern

  private

  def page
    [params.fetch(:page, 1).to_i, 1].max
  end

  def per_page
    [params.fetch(:per_page, 25).to_i, 100].min
  end

  def paginate(scope)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def pagination_meta(scope)
    total = scope.count
    {
      current_page: page,
      per_page: per_page,
      total_count: total,
      total_pages: (total.to_f / per_page).ceil
    }
  end
end

### Step 6: Create app/controllers/api/v1/base_controller.rb

class Api::V1::BaseController < ApplicationController
  include ApiAuthenticatable
  include Paginatable

  skip_before_action :verify_authenticity_token
  before_action :set_default_format

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: "Record not found", code: "not_found" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: e.message, code: "validation_error" }, status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message, code: "missing_parameter" }, status: :bad_request
  end

  private

  def set_default_format
    request.format = :json unless params[:format]
  end
end

### Step 7: Create app/controllers/webhooks/base_controller.rb

class Webhooks::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Store raw body for signature verification
  before_action :store_raw_body

  private

  def store_raw_body
    @raw_body = request.body.read
    request.body.rewind
  end

  def render_accepted
    render json: { status: "accepted" }, status: :ok
  end

  def render_unauthorized
    render json: { error: "Invalid signature", code: "unauthorized" }, status: :unauthorized
  end

  # Find account by a lookup key specific to each webhook source
  # Subclasses must implement their own account lookup
  def find_account!(identifier)
    account = Account.find_by!(id: identifier)
    ActsAsTenant.current_tenant = account
    account
  end
end

### Step 8: Create app/controllers/pages_controller.rb (placeholder for root route)

class PagesController < ApplicationController
  def home
    if user_signed_in?
      redirect_to api_v1_account_path(format: :json)
    else
      render plain: "FeedbackMind API — Visit /api/v1/ with a valid Bearer token."
    end
  end
end

### Step 9: Create app/controllers/application_controller.rb (update it)

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end

After completing all steps, run:
1. `rails db:migrate` to apply the api_token migration
2. `rails routes | head -50` to verify routes are configured
3. `rails runner "puts Account.column_names.include?('api_token')"` to verify the new column

Show me the full output.
```

---

## PROMPT 8 — Webhook Receivers + Payload Normalizers

```
In the feedbackmind Rails project, create the webhook receiver controllers and their corresponding payload normalizer services. Each webhook controller receives a POST from an external service, verifies the signature, normalizes the payload, and enqueues FeedbackIngestJob.

IMPORTANT: Each webhook URL includes the account_id as a query parameter for account identification. Example: POST /webhooks/intercom?account_id=123. The customer configures this URL in their Intercom/Slack/etc webhook settings.

### app/controllers/webhooks/intercom_controller.rb

class Webhooks::IntercomController < Webhooks::BaseController
  def create
    account = find_account_from_params!

    unless verify_intercom_signature(account)
      return render_unauthorized
    end

    payload = JSON.parse(@raw_body)
    normalized = Webhooks::IntercomNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :intercom), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def verify_intercom_signature(account)
    secret = account.sources.find_by(source_type: :intercom)&.config&.dig("webhook_secret")
    return true unless secret # Skip verification if no secret configured

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, @raw_body)
    signature = request.headers["X-Hub-Signature"]

    return false unless signature
    ActiveSupport::SecurityUtils.secure_compare("sha256=#{expected}", signature)
  end

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end

### app/controllers/webhooks/slack_controller.rb

class Webhooks::SlackController < Webhooks::BaseController
  def create
    payload = JSON.parse(@raw_body)

    # Handle Slack URL verification challenge
    if payload["type"] == "url_verification"
      return render json: { challenge: payload["challenge"] }
    end

    account = find_account_from_params!

    unless verify_slack_signature(account)
      return render_unauthorized
    end

    normalized = Webhooks::SlackNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :slack), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def verify_slack_signature(account)
    secret = account.sources.find_by(source_type: :slack)&.config&.dig("signing_secret")
    return true unless secret

    timestamp = request.headers["X-Slack-Request-Timestamp"]
    return false unless timestamp
    return false if (Time.now.to_i - timestamp.to_i).abs > 300 # 5 min tolerance

    sig_basestring = "v0:#{timestamp}:#{@raw_body}"
    expected = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", secret, sig_basestring)
    signature = request.headers["X-Slack-Signature"]

    ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
  end

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end

### app/controllers/webhooks/typeform_controller.rb

class Webhooks::TypeformController < Webhooks::BaseController
  def create
    account = find_account_from_params!

    unless verify_typeform_signature(account)
      return render_unauthorized
    end

    payload = JSON.parse(@raw_body)
    normalized = Webhooks::TypeformNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :typeform), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def verify_typeform_signature(account)
    secret = account.sources.find_by(source_type: :typeform)&.config&.dig("webhook_secret")
    return true unless secret

    expected = OpenSSL::HMAC.digest("SHA256", secret, @raw_body)
    signature = Base64.decode64(request.headers["Typeform-Signature"].to_s.sub("sha256=", ""))

    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end

### app/controllers/webhooks/jira_controller.rb

class Webhooks::JiraController < Webhooks::BaseController
  def create
    account = find_account_from_params!
    payload = JSON.parse(@raw_body)

    # Jira webhooks don't have a standard signature — we rely on account_id + source being active
    normalized = Webhooks::JiraNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :jira), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end

### app/controllers/webhooks/gmail_controller.rb

class Webhooks::GmailController < Webhooks::BaseController
  def create
    account = find_account_from_params!
    payload = JSON.parse(@raw_body)

    normalized = Webhooks::GmailNormalizer.new(payload).normalize

    if normalized
      FeedbackIngestJob.perform_async(account.id, find_source_id(account, :gmail), normalized)
    end

    render_accepted
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  def find_account_from_params!
    Account.find(params.require(:account_id))
  end

  def find_source_id(account, type)
    account.sources.find_by!(source_type: type, active: true).id
  end
end

### app/controllers/webhooks/stripe_controller.rb

class Webhooks::StripeController < Webhooks::BaseController
  def create
    event = construct_stripe_event
    return render_unauthorized unless event

    Billing::HandleWebhookEvent.new(event).call

    render_accepted
  end

  private

  def construct_stripe_event
    Stripe::Webhook.construct_event(
      @raw_body,
      request.headers["Stripe-Signature"],
      Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV.fetch("STRIPE_WEBHOOK_SECRET")
    )
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.warn("[Stripe Webhook] Signature verification failed: #{e.message}")
    nil
  rescue JSON::ParserError
    Rails.logger.warn("[Stripe Webhook] Invalid JSON payload")
    nil
  end
end

Now create the normalizer services. Each normalizer takes a raw webhook payload and returns a hash compatible with FeedbackIngestJob (or nil to skip).

### app/services/webhooks/intercom_normalizer.rb

module Webhooks
  class IntercomNormalizer
    def initialize(payload)
      @payload = payload
    end

    # Normalizes Intercom conversation/note webhook payloads
    # Returns hash compatible with FeedbackIngestJob or nil
    def normalize
      return nil unless relevant_event?

      data = @payload.dig("data", "item") || {}
      conversation_parts = data.dig("conversation_parts", "conversation_parts") || []

      # Get the user's message (first part or body)
      content = extract_content(data, conversation_parts)
      return nil if content.blank?

      user = data.dig("user") || data.dig("contacts", "contacts", 0) || {}

      {
        "external_id" => data["id"]&.to_s,
        "content" => content,
        "author_email" => user["email"],
        "author_name" => user["name"],
        "metadata" => {
          "intercom_conversation_id" => data["id"],
          "tags" => extract_tags(data),
          "url" => data["url"]
        },
        "received_at" => Time.at(data["created_at"].to_i).iso8601
      }
    end

    private

    def relevant_event?
      topic = @payload["topic"]
      %w[
        conversation.user.created
        conversation.user.replied
        conversation/user/created
        conversation/user/replied
      ].include?(topic)
    end

    def extract_content(data, parts)
      # Try conversation body first, then first user part
      body = data.dig("source", "body")
      return ActionController::Base.helpers.strip_tags(body) if body.present?

      user_part = parts.find { |p| p["part_type"] == "comment" && p.dig("author", "type") == "user" }
      user_part ? ActionController::Base.helpers.strip_tags(user_part["body"]) : nil
    end

    def extract_tags(data)
      (data.dig("tags", "tags") || []).map { |t| t["name"] }
    end
  end
end

### app/services/webhooks/slack_normalizer.rb

module Webhooks
  class SlackNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      event = @payload["event"]
      return nil unless event
      return nil unless event["type"] == "message"
      return nil if event["subtype"].present? # Skip bot messages, edits, etc.

      {
        "external_id" => "slack_#{event['channel']}_#{event['ts']}",
        "content" => event["text"],
        "author_name" => event["user"], # Slack user ID — could resolve via API later
        "metadata" => {
          "slack_channel" => event["channel"],
          "slack_ts" => event["ts"],
          "slack_thread_ts" => event["thread_ts"]
        },
        "received_at" => Time.at(event["ts"].to_f).iso8601
      }
    end
  end
end

### app/services/webhooks/typeform_normalizer.rb

module Webhooks
  class TypeformNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      form_response = @payload["form_response"]
      return nil unless form_response

      answers = form_response["answers"] || []
      # Concatenate all text-based answers into a single feedback string
      content = answers.map { |a| extract_answer_text(a) }.compact.join("\n\n")
      return nil if content.blank?

      hidden = form_response.dig("hidden") || {}

      {
        "external_id" => "typeform_#{form_response['token']}",
        "content" => content,
        "author_email" => find_email(answers, hidden),
        "author_name" => hidden["name"],
        "metadata" => {
          "typeform_form_id" => @payload.dig("form_response", "form_id"),
          "typeform_response_id" => form_response["token"],
          "submitted_at" => form_response["submitted_at"]
        },
        "received_at" => form_response["submitted_at"] || Time.current.iso8601
      }
    end

    private

    def extract_answer_text(answer)
      case answer["type"]
      when "text", "long_text", "short_text", "email", "url"
        answer[answer["type"]]
      when "choice"
        answer.dig("choice", "label")
      when "choices"
        answer.dig("choices", "labels")&.join(", ")
      when "number", "rating", "opinion_scale"
        "Rating: #{answer[answer['type']]}"
      else
        nil
      end
    end

    def find_email(answers, hidden)
      email_answer = answers.find { |a| a["type"] == "email" }
      email_answer&.dig("email") || hidden["email"]
    end
  end
end

### app/services/webhooks/jira_normalizer.rb

module Webhooks
  class JiraNormalizer
    def initialize(payload)
      @payload = payload
    end

    def normalize
      return nil unless relevant_event?

      issue = @payload["issue"] || {}
      fields = issue["fields"] || {}
      comment = @payload.dig("comment")

      content = if comment
                  comment["body"]
                else
                  [fields["summary"], fields["description"]].compact.join("\n\n")
                end

      return nil if content.blank?

      reporter = fields.dig("reporter") || {}

      {
        "external_id" => "jira_#{issue['key']}_#{comment&.dig('id') || 'issue'}",
        "content" => content,
        "author_email" => reporter["emailAddress"] || comment&.dig("author", "emailAddress"),
        "author_name" => reporter["displayName"] || comment&.dig("author", "displayName"),
        "metadata" => {
          "jira_key" => issue["key"],
          "jira_type" => fields.dig("issuetype", "name"),
          "jira_priority" => fields.dig("priority", "name"),
          "jira_status" => fields.dig("status", "name"),
          "jira_url" => issue["self"]
        },
        "received_at" => (fields["created"] || Time.current).to_s
      }
    end

    private

    def relevant_event?
      event = @payload["webhookEvent"]
      %w[jira:issue_created jira:issue_updated comment_created].include?(event)
    end
  end
end

### app/services/webhooks/gmail_normalizer.rb

module Webhooks
  class GmailNormalizer
    def initialize(payload)
      @payload = payload
    end

    # Expects a normalized email payload (from Cloudflare Email Routing or Google Pub/Sub)
    # Format: { from, subject, body, message_id, date }
    def normalize
      return nil if @payload["body"].blank?

      {
        "external_id" => "gmail_#{@payload['message_id']}",
        "content" => "Subject: #{@payload['subject']}\n\n#{@payload['body']}",
        "author_email" => @payload["from"],
        "author_name" => extract_name(@payload["from"]),
        "metadata" => {
          "gmail_message_id" => @payload["message_id"],
          "subject" => @payload["subject"]
        },
        "received_at" => (@payload["date"] || Time.current).to_s
      }
    end

    private

    def extract_name(from)
      return nil unless from
      # "John Doe <john@example.com>" => "John Doe"
      match = from.match(/^(.+?)\s*</)
      match ? match[1].strip : nil
    end
  end
end

After creating all files, run:
1. `find app/controllers/webhooks -name "*.rb" | sort`
2. `find app/services/webhooks -name "*.rb" | sort`
3. `rails routes | grep webhook`

Show me the full output.
```

---

## PROMPT 9 — API Controllers (Feedbacks, Chat, Sources, Syntheses, Account)

```
In the feedbackmind Rails project, create the API v1 controllers. All controllers inherit from Api::V1::BaseController which provides API token auth, tenant scoping, pagination, and error handling.

### app/controllers/api/v1/accounts_controller.rb

class Api::V1::AccountsController < Api::V1::BaseController
  def show
    render json: {
      account: {
        id: current_account.id,
        name: current_account.name,
        subdomain: current_account.subdomain,
        plan: current_account.plan,
        feedback_count_this_month: current_account.feedback_count_this_month,
        plan_limits: current_account.plan_limits,
        feedback_limit_reached: current_account.feedback_limit_reached?,
        sources_count: current_account.sources.active.count,
        users_count: current_account.users.count,
        created_at: current_account.created_at
      }
    }
  end

  def update
    if current_account.update(account_params)
      render json: { account: current_account.slice(:id, :name, :subdomain) }, status: :ok
    else
      render json: { error: current_account.errors.full_messages.join(", "), code: "validation_error" }, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end
end

### app/controllers/api/v1/sources_controller.rb

class Api::V1::SourcesController < Api::V1::BaseController
  before_action :find_source, only: [:show, :update, :destroy, :activate, :deactivate]

  def index
    sources = current_account.sources.order(created_at: :desc)
    sources = sources.where(active: true) if params[:active] == "true"
    sources = sources.where(source_type: params[:type]) if params[:type].present?

    render json: {
      sources: sources.map { |s| source_json(s) }
    }
  end

  def show
    render json: { source: source_json(@source) }
  end

  def create
    source = current_account.sources.build(source_params)

    if source.save
      render json: { source: source_json(source) }, status: :created
    else
      render json: { error: source.errors.full_messages.join(", "), code: "validation_error" }, status: :unprocessable_entity
    end
  end

  def update
    if @source.update(source_params)
      render json: { source: source_json(@source) }
    else
      render json: { error: @source.errors.full_messages.join(", "), code: "validation_error" }, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy!
    head :no_content
  end

  def activate
    @source.update!(active: true)
    render json: { source: source_json(@source) }
  end

  def deactivate
    @source.update!(active: false)
    render json: { source: source_json(@source) }
  end

  private

  def find_source
    @source = current_account.sources.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:source_type, config: {})
  end

  def source_json(source)
    {
      id: source.id,
      source_type: source.source_type,
      active: source.active,
      last_synced_at: source.last_synced_at,
      feedbacks_count: source.feedbacks.count,
      webhook_url: webhooks_url_for(source),
      created_at: source.created_at
    }
  end

  def webhooks_url_for(source)
    type = source.source_type
    return nil if %w[csv appstore playstore].include?(type)
    "/webhooks/#{type}?account_id=#{current_account.id}"
  end
end

### app/controllers/api/v1/feedbacks_controller.rb

class Api::V1::FeedbacksController < Api::V1::BaseController
  def index
    feedbacks = current_account.feedbacks.includes(:source).recent

    # Filters
    feedbacks = feedbacks.by_sentiment(params[:sentiment]) if params[:sentiment].present?
    feedbacks = feedbacks.by_topic(params[:topic]) if params[:topic].present?
    feedbacks = feedbacks.from_source_type(params[:source_type]) if params[:source_type].present?
    feedbacks = feedbacks.where(source_id: params[:source_id]) if params[:source_id].present?
    feedbacks = feedbacks.unprocessed if params[:unprocessed] == "true"
    feedbacks = feedbacks.processed if params[:processed] == "true"

    # Date range filter
    if params[:since].present?
      feedbacks = feedbacks.where("received_at >= ?", Time.parse(params[:since]))
    end
    if params[:until].present?
      feedbacks = feedbacks.where("received_at <= ?", Time.parse(params[:until]))
    end

    total_scope = feedbacks
    feedbacks = paginate(feedbacks)

    render json: {
      feedbacks: feedbacks.map { |f| feedback_json(f) },
      meta: pagination_meta(total_scope)
    }
  end

  def show
    feedback = current_account.feedbacks.find(params[:id])
    render json: { feedback: feedback_json(feedback, detailed: true) }
  end

  def import_csv
    file = params[:file]

    unless file.present? && file.content_type.in?(%w[text/csv application/csv text/plain])
      return render json: { error: "Please upload a valid CSV file", code: "invalid_file" }, status: :unprocessable_entity
    end

    source = current_account.sources.find_or_create_by!(source_type: :csv) do |s|
      s.active = true
    end

    result = Feedback::CsvImporter.new(
      account: current_account,
      source: source,
      file: file
    ).import

    render json: {
      message: "CSV import started",
      rows_enqueued: result[:enqueued],
      rows_skipped: result[:skipped],
      errors: result[:errors]
    }, status: :accepted
  end

  private

  def feedback_json(feedback, detailed: false)
    json = {
      id: feedback.id,
      source_type: feedback.source.source_type,
      content: feedback.content.truncate(300),
      sentiment: feedback.sentiment,
      topics: feedback.topics,
      author_name: feedback.author_name,
      received_at: feedback.received_at,
      processed: feedback.processed?
    }

    if detailed
      json[:content] = feedback.content # Full content
      json[:author_email] = feedback.author_email
      json[:metadata] = feedback.metadata
      json[:source_id] = feedback.source_id
      json[:external_id] = feedback.external_id
      json[:processed_at] = feedback.processed_at
    end

    json
  end
end

### app/controllers/api/v1/chat_controller.rb

Note: This controller is mapped to path "chat" in routes but uses ChatMessagesController.

class Api::V1::ChatMessagesController < Api::V1::BaseController
  def index
    messages = current_account.chat_messages
                              .includes(:user)
                              .chronological

    messages = messages.by_user(User.find(params[:user_id])) if params[:user_id].present?
    messages = paginate(messages)

    render json: {
      messages: messages.map { |m| message_json(m) }
    }
  end

  def create
    # Verify chat is enabled for this plan
    unless current_account.chat_enabled?
      return render json: {
        error: "RAG chat is not available on your current plan. Please upgrade to Growth or Scale.",
        code: "plan_limit"
      }, status: :forbidden
    end

    question = params.require(:message)
    user = current_account.users.find(params.require(:user_id))

    # Save the user's question
    user_message = ChatMessage.create!(
      account: current_account,
      user: user,
      role: :user,
      content: question
    )

    # Call RAG chat service
    result = Synthesis::RagChat.new.ask(
      account: current_account,
      question: question
    )

    # Save the assistant's response
    assistant_message = ChatMessage.create!(
      account: current_account,
      user: user,
      role: :assistant,
      content: result[:answer],
      source_feedback_ids: result[:source_feedback_ids]
    )

    render json: {
      question: message_json(user_message),
      answer: message_json(assistant_message),
      sources: result[:source_feedback_ids].length
    }, status: :created
  end

  private

  def message_json(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      source_feedback_ids: message.source_feedback_ids,
      created_at: message.created_at
    }
  end
end

### app/controllers/api/v1/syntheses_controller.rb

class Api::V1::SynthesesController < Api::V1::BaseController
  def index
    syntheses = current_account.weekly_syntheses.recent
    syntheses = paginate(syntheses)

    render json: {
      syntheses: syntheses.map { |s| synthesis_json(s) }
    }
  end

  def show
    synthesis = current_account.weekly_syntheses.find(params[:id])

    render json: {
      synthesis: synthesis_json(synthesis, detailed: true)
    }
  end

  private

  def synthesis_json(synthesis, detailed: false)
    json = {
      id: synthesis.id,
      week_label: synthesis.week_label,
      week_start: synthesis.week_start,
      feedback_count: synthesis.feedback_count,
      sent: synthesis.sent?,
      created_at: synthesis.created_at
    }

    if detailed
      json[:top_themes] = synthesis.top_themes
      json[:executive_summary] = synthesis.executive_summary
      json[:biggest_risk] = synthesis.biggest_risk
      json[:quick_wins] = synthesis.quick_wins
      json[:sent_at] = synthesis.sent_at
    end

    json
  end
end

After creating all files, run:
1. `find app/controllers/api -name "*.rb" | sort`
2. `rails routes | grep "api/v1"`
3. `rails runner "puts 'Controllers loaded OK'"` to verify no load errors

Show me the full output.
```

---

## PROMPT 10 — Stripe Billing Services + CSV Importer

```
In the feedbackmind Rails project, create the Stripe billing service objects and the CSV importer.

### app/services/billing/create_checkout.rb

module Billing
  class CreateCheckout
    PRICE_IDS = {
      "starter" => ENV.fetch("STRIPE_STARTER_PRICE_ID", "price_starter_placeholder"),
      "growth"  => ENV.fetch("STRIPE_GROWTH_PRICE_ID", "price_growth_placeholder"),
      "scale"   => ENV.fetch("STRIPE_SCALE_PRICE_ID", "price_scale_placeholder")
    }.freeze

    def initialize(account:, plan:, success_url:, cancel_url:)
      @account = account
      @plan = plan
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      # Create or find Stripe customer
      customer_id = find_or_create_stripe_customer

      session = Stripe::Checkout::Session.create(
        customer: customer_id,
        mode: "subscription",
        line_items: [{
          price: PRICE_IDS[@plan],
          quantity: 1
        }],
        success_url: @success_url,
        cancel_url: @cancel_url,
        metadata: {
          account_id: @account.id,
          plan: @plan
        }
      )

      { checkout_url: session.url, session_id: session.id }
    end

    private

    def find_or_create_stripe_customer
      if @account.stripe_customer_id.present?
        @account.stripe_customer_id
      else
        customer = Stripe::Customer.create(
          name: @account.name,
          email: @account.users.find_by(role: :owner)&.email,
          metadata: { account_id: @account.id }
        )
        @account.update!(stripe_customer_id: customer.id)
        customer.id
      end
    end
  end
end

### app/services/billing/create_portal_session.rb

module Billing
  class CreatePortalSession
    def initialize(account:, return_url:)
      @account = account
      @return_url = return_url
    end

    def call
      unless @account.stripe_customer_id.present?
        raise "Account does not have a Stripe customer. Complete checkout first."
      end

      session = Stripe::BillingPortal::Session.create(
        customer: @account.stripe_customer_id,
        return_url: @return_url
      )

      { portal_url: session.url }
    end
  end
end

### app/services/billing/handle_webhook_event.rb

module Billing
  class HandleWebhookEvent
    PLAN_MAP = {
      ENV.fetch("STRIPE_STARTER_PRICE_ID", "price_starter_placeholder") => "starter",
      ENV.fetch("STRIPE_GROWTH_PRICE_ID", "price_growth_placeholder") => "growth",
      ENV.fetch("STRIPE_SCALE_PRICE_ID", "price_scale_placeholder") => "scale"
    }.freeze

    def initialize(event)
      @event = event
      @type = event.type
      @object = event.data.object
    end

    def call
      case @type
      when "checkout.session.completed"
        handle_checkout_completed
      when "customer.subscription.updated"
        handle_subscription_updated
      when "customer.subscription.deleted"
        handle_subscription_deleted
      when "invoice.payment_failed"
        handle_payment_failed
      else
        Rails.logger.info("[Stripe Webhook] Unhandled event type: #{@type}")
      end
    end

    private

    def handle_checkout_completed
      account_id = @object.metadata["account_id"]
      return unless account_id

      account = Account.find_by(id: account_id)
      return unless account

      subscription = Stripe::Subscription.retrieve(@object.subscription)
      price_id = subscription.items.data.first.price.id
      plan = PLAN_MAP[price_id] || "starter"

      account.update!(
        stripe_customer_id: @object.customer,
        stripe_subscription_id: @object.subscription,
        plan: plan
      )

      Rails.logger.info("[Stripe] Account #{account_id} subscribed to #{plan}")
    end

    def handle_subscription_updated
      account = Account.find_by(stripe_subscription_id: @object.id)
      return unless account

      price_id = @object.items.data.first.price.id
      plan = PLAN_MAP[price_id]

      if plan && account.plan != plan
        account.update!(plan: plan)
        Rails.logger.info("[Stripe] Account #{account.id} plan changed to #{plan}")
      end
    end

    def handle_subscription_deleted
      account = Account.find_by(stripe_subscription_id: @object.id)
      return unless account

      account.update!(
        plan: :starter,
        stripe_subscription_id: nil
      )

      Rails.logger.info("[Stripe] Account #{account.id} subscription canceled, downgraded to starter")
    end

    def handle_payment_failed
      account = Account.find_by(stripe_customer_id: @object.customer)
      return unless account

      # TODO: Send payment failure notification email
      Rails.logger.warn("[Stripe] Payment failed for account #{account.id}")
    end
  end
end

### app/controllers/api/v1/billing/checkout_controller.rb

class Api::V1::Billing::CheckoutController < Api::V1::BaseController
  def create
    plan = params.require(:plan)

    unless %w[starter growth scale].include?(plan)
      return render json: { error: "Invalid plan: #{plan}", code: "invalid_plan" }, status: :unprocessable_entity
    end

    result = Billing::CreateCheckout.new(
      account: current_account,
      plan: plan,
      success_url: params[:success_url] || root_url,
      cancel_url: params[:cancel_url] || root_url
    ).call

    render json: result, status: :created
  end
end

### app/controllers/api/v1/billing/portal_controller.rb

class Api::V1::Billing::PortalController < Api::V1::BaseController
  def create
    result = Billing::CreatePortalSession.new(
      account: current_account,
      return_url: params[:return_url] || root_url
    ).call

    render json: result, status: :created
  rescue => e
    render json: { error: e.message, code: "billing_error" }, status: :unprocessable_entity
  end
end

### app/services/feedback/csv_importer.rb

require "csv"

module Feedback
  class CsvImporter
    REQUIRED_HEADERS = %w[content].freeze
    OPTIONAL_HEADERS = %w[author_email author_name external_id received_at].freeze
    MAX_ROWS = 5_000

    def initialize(account:, source:, file:)
      @account = account
      @source = source
      @file = file
    end

    # Parses CSV and enqueues FeedbackIngestJob for each valid row
    # Returns { enqueued: Integer, skipped: Integer, errors: Array<String> }
    def import
      result = { enqueued: 0, skipped: 0, errors: [] }

      begin
        csv = CSV.parse(@file.read, headers: true, liberal_parsing: true)
      rescue CSV::MalformedCSVError => e
        result[:errors] << "CSV parsing error: #{e.message}"
        return result
      end

      # Validate headers
      unless (REQUIRED_HEADERS - csv.headers).empty?
        result[:errors] << "Missing required column: content. Found headers: #{csv.headers.join(', ')}"
        return result
      end

      csv.each_with_index do |row, index|
        if index >= MAX_ROWS
          result[:errors] << "CSV exceeds maximum of #{MAX_ROWS} rows. Remaining rows skipped."
          break
        end

        content = row["content"]&.strip
        if content.blank?
          result[:skipped] += 1
          next
        end

        # Check plan limits
        if @account.feedback_limit_reached?
          result[:errors] << "Feedback limit reached at row #{index + 1}. Upgrade your plan for more."
          break
        end

        FeedbackIngestJob.perform_async(
          @account.id,
          @source.id,
          {
            "external_id" => row["external_id"]&.strip.presence || "csv_#{SecureRandom.hex(8)}",
            "content" => content,
            "author_email" => row["author_email"]&.strip,
            "author_name" => row["author_name"]&.strip,
            "metadata" => row.to_h.except(*REQUIRED_HEADERS, *OPTIONAL_HEADERS).compact,
            "received_at" => parse_date(row["received_at"]) || Time.current.iso8601
          }
        )

        result[:enqueued] += 1
      end

      result
    end

    private

    def parse_date(value)
      return nil unless value.present?
      Time.parse(value).iso8601
    rescue ArgumentError
      nil
    end
  end
end

### Update .env.example — Add these Stripe price ID lines:

STRIPE_STARTER_PRICE_ID=price_starter_placeholder
STRIPE_GROWTH_PRICE_ID=price_growth_placeholder
STRIPE_SCALE_PRICE_ID=price_scale_placeholder

After creating all files, run:
1. `find app/services/billing -name "*.rb" | sort`
2. `find app/controllers/api/v1/billing -name "*.rb" | sort`
3. `cat app/services/feedback/csv_importer.rb | head -5`
4. `rails runner "puts 'All services loaded OK'"` to verify no load errors

Show me the full output.
```

---

## PROMPT 11 — Request Specs for Webhooks + API

```
In the feedbackmind Rails project, create request specs for the webhook endpoints and API controllers. These verify the full request cycle including authentication, signature verification, and response format.

### spec/support/api_helpers.rb

module ApiHelpers
  def api_headers(account)
    {
      "Authorization" => "Bearer #{account.api_token}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end

### spec/requests/api/v1/accounts_spec.rb

require "rails_helper"

RSpec.describe "Api::V1::Accounts", type: :request do
  let(:account) { create(:account, :with_stripe, plan: :growth) }
  let!(:user) { create(:user, account: account) }

  describe "GET /api/v1/account" do
    it "returns account details with valid token" do
      get "/api/v1/account", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["account"]["name"]).to eq(account.name)
      expect(json_response["account"]["plan"]).to eq("growth")
      expect(json_response["account"]["plan_limits"]).to be_present
    end

    it "returns 401 with invalid token" do
      get "/api/v1/account", headers: {
        "Authorization" => "Bearer invalid_token",
        "Content-Type" => "application/json"
      }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]).to include("Invalid")
    end

    it "returns 401 with no token" do
      get "/api/v1/account", headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/account" do
    it "updates account name" do
      patch "/api/v1/account",
            params: { account: { name: "New Name" } }.to_json,
            headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(account.reload.name).to eq("New Name")
    end
  end
end

### spec/requests/api/v1/sources_spec.rb

require "rails_helper"

RSpec.describe "Api::V1::Sources", type: :request do
  let(:account) { create(:account) }
  let!(:source) { create(:source, account: account, source_type: :intercom, active: true) }

  describe "GET /api/v1/sources" do
    it "returns all sources for the account" do
      get "/api/v1/sources", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["sources"].length).to eq(1)
      expect(json_response["sources"][0]["source_type"]).to eq("intercom")
    end
  end

  describe "POST /api/v1/sources" do
    it "creates a new source" do
      post "/api/v1/sources",
           params: { source: { source_type: "slack", config: { "signing_secret" => "test" } } }.to_json,
           headers: api_headers(account)

      expect(response).to have_http_status(:created)
      expect(json_response["source"]["source_type"]).to eq("slack")
    end
  end

  describe "POST /api/v1/sources/:id/activate" do
    let(:inactive_source) { create(:source, :inactive, account: account) }

    it "activates a source" do
      post "/api/v1/sources/#{inactive_source.id}/activate", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(inactive_source.reload.active).to be true
    end
  end

  describe "DELETE /api/v1/sources/:id" do
    it "deletes a source" do
      delete "/api/v1/sources/#{source.id}", headers: api_headers(account)
      expect(response).to have_http_status(:no_content)
      expect(Source.find_by(id: source.id)).to be_nil
    end
  end
end

### spec/requests/api/v1/feedbacks_spec.rb

require "rails_helper"

RSpec.describe "Api::V1::Feedbacks", type: :request do
  let(:account) { create(:account) }
  let(:source) { create(:source, account: account) }
  let!(:feedbacks) do
    create_list(:feedback, 5, :processed, account: account, source: source)
  end

  describe "GET /api/v1/feedbacks" do
    it "returns paginated feedbacks" do
      get "/api/v1/feedbacks", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["feedbacks"].length).to eq(5)
      expect(json_response["meta"]["total_count"]).to eq(5)
    end

    it "filters by sentiment" do
      create(:feedback, :positive, account: account, source: source, processed_at: Time.current)

      get "/api/v1/feedbacks?sentiment=positive", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      json_response["feedbacks"].each do |f|
        expect(f["sentiment"]).to eq("positive")
      end
    end

    it "filters by topic" do
      create(:feedback, account: account, source: source, topics: ["billing"], processed_at: Time.current)

      get "/api/v1/feedbacks?topic=billing", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["feedbacks"]).to be_present
    end
  end

  describe "GET /api/v1/feedbacks/:id" do
    it "returns detailed feedback" do
      get "/api/v1/feedbacks/#{feedbacks.first.id}", headers: api_headers(account)

      expect(response).to have_http_status(:ok)
      expect(json_response["feedback"]["metadata"]).to be_present
    end
  end
end

### spec/requests/api/v1/chat_spec.rb

require "rails_helper"

RSpec.describe "Api::V1::Chat", type: :request do
  let(:account) { create(:account, :growth) }
  let(:user) { create(:user, account: account) }

  describe "POST /api/v1/chat" do
    it "rejects chat on starter plan" do
      starter_account = create(:account, plan: :starter)
      starter_user = create(:user, account: starter_account)

      post "/api/v1/chat",
           params: { message: "What features did users request?", user_id: starter_user.id }.to_json,
           headers: api_headers(starter_account)

      expect(response).to have_http_status(:forbidden)
      expect(json_response["code"]).to eq("plan_limit")
    end
  end
end

### spec/requests/webhooks/intercom_spec.rb

require "rails_helper"

RSpec.describe "Webhooks::Intercom", type: :request do
  let(:account) { create(:account) }
  let!(:source) { create(:source, account: account, source_type: :intercom, active: true, config: {}) }

  let(:valid_payload) do
    {
      topic: "conversation.user.created",
      data: {
        item: {
          id: "conv_123",
          source: { body: "<p>Your onboarding is confusing</p>" },
          user: { email: "user@example.com", name: "Jane Doe" },
          tags: { tags: [{ name: "feedback" }] },
          created_at: Time.current.to_i
        }
      }
    }.to_json
  end

  it "accepts valid webhook and enqueues job" do
    expect {
      post "/webhooks/intercom?account_id=#{account.id}",
           params: valid_payload,
           headers: { "Content-Type" => "application/json" }
    }.to change(FeedbackIngestJob.jobs, :size).by(1)

    expect(response).to have_http_status(:ok)
  end

  it "returns 400 for invalid JSON" do
    post "/webhooks/intercom?account_id=#{account.id}",
         params: "not json",
         headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end
end

### spec/requests/webhooks/slack_spec.rb

require "rails_helper"

RSpec.describe "Webhooks::Slack", type: :request do
  let(:account) { create(:account) }
  let!(:source) { create(:source, account: account, source_type: :slack, active: true, config: {}) }

  it "responds to Slack URL verification challenge" do
    post "/webhooks/slack?account_id=#{account.id}",
         params: { type: "url_verification", challenge: "test_challenge_token" }.to_json,
         headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["challenge"]).to eq("test_challenge_token")
  end

  it "processes message events" do
    payload = {
      type: "event_callback",
      event: {
        type: "message",
        text: "The dashboard is really slow today",
        user: "U12345",
        channel: "C67890",
        ts: Time.current.to_f.to_s
      }
    }.to_json

    expect {
      post "/webhooks/slack?account_id=#{account.id}",
           params: payload,
           headers: { "Content-Type" => "application/json" }
    }.to change(FeedbackIngestJob.jobs, :size).by(1)

    expect(response).to have_http_status(:ok)
  end
end

### spec/requests/webhooks/stripe_spec.rb

require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  it "returns unauthorized with invalid signature" do
    post "/webhooks/stripe",
         params: { type: "checkout.session.completed" }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Stripe-Signature" => "invalid_signature"
         }

    expect(response).to have_http_status(:unauthorized)
  end
end

### Update spec/rails_helper.rb

Make sure the support files are loaded. Add this line inside the RSpec.configure block if not already present:

  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

Also add Sidekiq testing mode:

  require "sidekiq/testing"
  Sidekiq::Testing.fake!

After creating all files, run:
1. `bundle exec rspec --dry-run 2>&1 | tail -10` to verify all specs load
2. `bundle exec rspec spec/requests/ --dry-run 2>&1 | tail -10` to verify request specs specifically

Show me the full output.
```

---

## SESSION 2 VERIFICATION CHECKLIST

After running all 5 prompts (7-11), verify with these commands:

```bash
# 1. Full controller structure
find app/controllers -name "*.rb" | sort

# 2. Full service structure
find app/services -name "*.rb" | sort

# 3. Routes
rails routes | wc -l
rails routes | grep -c "webhook"
rails routes | grep -c "api/v1"

# 4. Migration status
rails db:migrate:status

# 5. All specs load
bundle exec rspec --dry-run 2>&1 | tail -5

# 6. No load errors
rails runner "puts 'All OK: ' + ApplicationRecord.descendants.map(&:name).sort.join(', ')"
```

Expected results:
- ~15 controller files
- ~12 service files
- 6 webhook routes
- ~15 API routes
- 9 migrations (8 from session 1 + api_token)
- All specs load without errors
