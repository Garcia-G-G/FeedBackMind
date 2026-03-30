# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :https
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline # Stimulus/Turbo inline handlers
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com" # Tailwind + Google Fonts
    policy.connect_src :self
    policy.frame_src   :none
  end

  # Report violations without enforcing — enable enforcement after verifying no breakage
  config.content_security_policy_report_only = true
end
