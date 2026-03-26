module Sources
  class JiraSync
    LIMIT = 50

    def initialize(source)
      @source = source
      @token = source.config["access_token"]
      @account = source.account
    end

    def sync
      return if @token.blank?

      sites = fetch_accessible_resources
      return if sites.empty?

      cloud_id = sites.first["id"]

      issues = fetch_issues(cloud_id)
      issues.each do |issue|
        content = [
          issue.dig("fields", "summary"),
          issue.dig("fields", "description")
        ].compact.join("\n\n")
        next if content.blank?

        raw_data = {
          "external_id" => "jira_#{issue['key']}",
          "content" => content.truncate(2000),
          "author_name" => issue.dig("fields", "creator", "displayName") || "Unknown",
          "author_email" => issue.dig("fields", "creator", "emailAddress"),
          "metadata" => {
            "issue_key" => issue["key"],
            "type" => issue.dig("fields", "issuetype", "name"),
            "priority" => issue.dig("fields", "priority", "name"),
            "status" => issue.dig("fields", "status", "name"),
            "url" => "https://#{sites.first['name']}.atlassian.net/browse/#{issue['key']}"
          },
          "received_at" => issue.dig("fields", "created") || Time.current.iso8601
        }

        FeedbackIngestJob.perform_async(@account.id, @source.id, raw_data)
      end
    end

    private

    def fetch_accessible_resources
      uri = URI("https://api.atlassian.com/oauth/token/accessible-resources")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"
      req["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(req)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error("[JiraSync] Failed to fetch sites: #{e.message}")
      []
    end

    def fetch_issues(cloud_id)
      uri = URI("https://api.atlassian.com/ex/jira/#{cloud_id}/rest/api/3/search")
      uri.query = URI.encode_www_form(
        jql: "ORDER BY created DESC",
        maxResults: LIMIT,
        fields: "summary,description,creator,issuetype,priority,status,created"
      )
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"
      req["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(req)
      data = JSON.parse(response.body)
      data["issues"] || []
    rescue => e
      Rails.logger.error("[JiraSync] Failed to fetch issues: #{e.message}")
      []
    end
  end
end
