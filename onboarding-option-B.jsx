import { useState } from "react";

// OPTION B: "Conversational" — Single page, all sections visible, scroll-through
// Inspired by Stripe, Cal.com — feels like filling out one clean form
const OnboardingOptionB = () => {
  const [selectedPlan, setSelectedPlan] = useState("growth");
  const [workspaceName, setWorkspaceName] = useState("");
  const [workspaceSlug, setWorkspaceSlug] = useState("");
  const [selectedSources, setSelectedSources] = useState([]);
  const [showSuccess, setShowSuccess] = useState(false);

  const plans = [
    { id: "starter", name: "Starter", price: 29, tagline: "Solo PM", limits: "1 user · 3 sources · 1K/mo" },
    { id: "growth", name: "Growth", price: 109, tagline: "Team", limits: "5 users · 10 sources · 10K/mo · AI Chat" },
    { id: "scale", name: "Scale", price: 209, tagline: "Enterprise", limits: "Unlimited everything · API" },
  ];

  const sources = [
    { id: "slack", name: "Slack", icon: "💬" },
    { id: "gmail", name: "Gmail", icon: "📧" },
    { id: "jira", name: "Jira", icon: "🔧" },
    { id: "typeform", name: "Typeform", icon: "📋" },
    { id: "appstore", name: "App Store", icon: "🍎" },
    { id: "csv", name: "CSV", icon: "📄" },
  ];

  const toggleSource = (id) => {
    setSelectedSources((prev) =>
      prev.includes(id) ? prev.filter((s) => s !== id) : [...prev, id]
    );
  };

  const handleNameChange = (val) => {
    setWorkspaceName(val);
    setWorkspaceSlug(val.toLowerCase().replace(/[^a-z0-9-]/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, ""));
  };

  if (showSuccess) {
    return (
      <div className="min-h-screen bg-stone-900 flex items-center justify-center" style={{ fontFamily: "'DM Sans', system-ui, sans-serif" }}>
        <div className="text-center">
          <div className="w-20 h-20 bg-emerald-500 rounded-full flex items-center justify-center mx-auto mb-6">
            <svg className="w-10 h-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-3xl font-bold text-white mb-3" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>
            Welcome to FeedbackMind
          </h1>
          <p className="text-stone-400 text-lg mb-2">
            Your workspace <span className="text-white font-medium">{workspaceName || "workspace"}</span> is ready.
          </p>
          <p className="text-stone-500 text-sm mb-8">
            Connect your sources from the Sources page to start receiving feedback.
          </p>
          <button className="px-8 py-3 bg-white text-stone-900 rounded-xl font-medium hover:bg-stone-100 transition-colors">
            Go to Dashboard →
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-stone-50" style={{ fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      {/* Fixed header */}
      <div className="sticky top-0 z-10 bg-white/80 backdrop-blur-lg border-b border-stone-200">
        <div className="max-w-2xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-stone-900 rounded-lg flex items-center justify-center text-white text-xs font-bold">FM</div>
            <span className="font-semibold text-stone-900" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>FeedbackMind</span>
          </div>
          <span className="text-sm text-stone-400">Create your workspace</span>
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-6 py-12 space-y-10">
        {/* Section 1: Plan */}
        <section>
          <div className="flex items-center gap-3 mb-6">
            <div className="w-7 h-7 bg-stone-900 rounded-full flex items-center justify-center text-white text-xs font-bold">1</div>
            <h2 className="text-xl font-bold text-stone-900" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>Pick your plan</h2>
            <span className="text-sm text-stone-400 ml-auto">14-day free trial on all plans</span>
          </div>

          <div className="grid grid-cols-3 gap-3">
            {plans.map((plan) => (
              <button
                key={plan.id}
                onClick={() => setSelectedPlan(plan.id)}
                className={`relative text-left p-4 rounded-xl border-2 transition-all ${
                  selectedPlan === plan.id
                    ? "border-stone-900 bg-stone-900 text-white"
                    : "border-stone-200 bg-white hover:border-stone-300"
                }`}
              >
                {plan.id === "growth" && selectedPlan !== "growth" && (
                  <div className="absolute -top-2 right-3 bg-emerald-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
                    POPULAR
                  </div>
                )}
                <div className="text-xs font-medium opacity-60 mb-1">{plan.tagline}</div>
                <div className="text-lg font-bold mb-1">{plan.name}</div>
                <div className="flex items-baseline gap-0.5 mb-2">
                  <span className="text-2xl font-bold">${plan.price}</span>
                  <span className="text-sm opacity-50">/mo</span>
                </div>
                <div className={`text-xs ${selectedPlan === plan.id ? "text-stone-300" : "text-stone-400"}`}>
                  {plan.limits}
                </div>
              </button>
            ))}
          </div>
        </section>

        {/* Divider */}
        <div className="border-t border-stone-200" />

        {/* Section 2: Workspace */}
        <section>
          <div className="flex items-center gap-3 mb-6">
            <div className="w-7 h-7 bg-stone-900 rounded-full flex items-center justify-center text-white text-xs font-bold">2</div>
            <h2 className="text-xl font-bold text-stone-900" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>Name your workspace</h2>
          </div>

          <div className="bg-white rounded-xl border border-stone-200 p-6">
            <div className="mb-5">
              <label className="block text-sm font-medium text-stone-600 mb-1.5">Workspace Name</label>
              <input
                type="text"
                value={workspaceName}
                onChange={(e) => handleNameChange(e.target.value)}
                placeholder="My Product Team"
                className="w-full px-4 py-2.5 rounded-lg border border-stone-300 text-stone-900 placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-stone-900/10 focus:border-stone-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-stone-600 mb-1.5">URL</label>
              <div className="flex items-center rounded-lg border border-stone-300 overflow-hidden focus-within:ring-2 focus-within:ring-stone-900/10 focus-within:border-stone-500">
                <span className="px-3 py-2.5 bg-stone-50 text-stone-400 text-sm border-r border-stone-300">https://</span>
                <input
                  type="text"
                  value={workspaceSlug}
                  onChange={(e) => setWorkspaceSlug(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ""))}
                  placeholder="my-team"
                  className="flex-1 px-3 py-2.5 text-stone-900 placeholder-stone-400 focus:outline-none"
                />
                <span className="px-3 py-2.5 bg-stone-50 text-stone-400 text-sm border-l border-stone-300">.feedbackmind.io</span>
              </div>
            </div>
          </div>
        </section>

        {/* Divider */}
        <div className="border-t border-stone-200" />

        {/* Section 3: Sources */}
        <section>
          <div className="flex items-center gap-3 mb-2">
            <div className="w-7 h-7 bg-stone-900 rounded-full flex items-center justify-center text-white text-xs font-bold">3</div>
            <h2 className="text-xl font-bold text-stone-900" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>Select your sources</h2>
            <span className="text-xs bg-stone-200 text-stone-500 px-2 py-0.5 rounded-full ml-2">Optional</span>
          </div>
          <p className="text-stone-400 text-sm ml-10 mb-5">Pick the tools you use. You'll securely connect them from your dashboard after setup.</p>

          <div className="grid grid-cols-6 gap-3">
            {sources.map((source) => (
              <button
                key={source.id}
                onClick={() => toggleSource(source.id)}
                className={`flex flex-col items-center p-3 rounded-xl border-2 transition-all ${
                  selectedSources.includes(source.id)
                    ? "border-stone-900 bg-stone-50"
                    : "border-stone-200 bg-white hover:border-stone-300"
                }`}
              >
                <span className="text-2xl mb-1">{source.icon}</span>
                <span className="text-xs font-medium text-stone-600">{source.name}</span>
                {selectedSources.includes(source.id) && (
                  <svg className="w-3.5 h-3.5 text-emerald-500 mt-1" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                )}
              </button>
            ))}
          </div>
        </section>

        {/* Submit */}
        <div className="border-t border-stone-200 pt-8 pb-4">
          <div className="flex items-center justify-between mb-6 bg-white rounded-xl border border-stone-200 p-4">
            <div>
              <div className="text-sm text-stone-400">Your plan</div>
              <div className="font-semibold text-stone-900">
                {plans.find((p) => p.id === selectedPlan)?.name} — ${plans.find((p) => p.id === selectedPlan)?.price}/mo
              </div>
            </div>
            <div className="text-right">
              <div className="text-sm text-stone-400">Sources selected</div>
              <div className="font-semibold text-stone-900">{selectedSources.length} of 6</div>
            </div>
          </div>

          <button
            onClick={() => workspaceName.trim() && setShowSuccess(true)}
            disabled={!workspaceName.trim()}
            className={`w-full py-3.5 rounded-xl text-base font-medium transition-all ${
              workspaceName.trim()
                ? "bg-stone-900 text-white hover:bg-stone-800 shadow-lg shadow-stone-900/20"
                : "bg-stone-200 text-stone-400 cursor-not-allowed"
            }`}
          >
            Create workspace →
          </button>
          <p className="text-center text-xs text-stone-400 mt-3">
            By continuing you agree to our Terms of Service and Privacy Policy
          </p>
        </div>
      </div>
    </div>
  );
};

export default OnboardingOptionB;
