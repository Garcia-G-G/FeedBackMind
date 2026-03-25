import { useState } from "react";

// OPTION C: "Split screen" — Left info panel + right form, step-by-step
// Inspired by Clerk, Supabase, Resend onboarding
const OnboardingOptionC = () => {
  const [step, setStep] = useState(1);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [workspaceName, setWorkspaceName] = useState("");
  const [workspaceSlug, setWorkspaceSlug] = useState("");
  const [selectedSources, setSelectedSources] = useState([]);

  const plans = [
    {
      id: "starter",
      name: "Starter",
      price: 29,
      features: ["1 team member", "3 sources", "1,000 feedbacks/mo", "Weekly synthesis"],
    },
    {
      id: "growth",
      name: "Growth",
      price: 109,
      badge: "Popular",
      features: ["5 team members", "10 sources", "10,000 feedbacks/mo", "AI Chat", "Priority support"],
    },
    {
      id: "scale",
      name: "Scale",
      price: 209,
      features: ["Unlimited members", "Unlimited sources", "Unlimited feedbacks", "API access", "Custom integrations"],
    },
  ];

  const sources = [
    { id: "slack", name: "Slack", icon: "💬", color: "#E8D5B7" },
    { id: "gmail", name: "Gmail", icon: "📧", color: "#D5E8D4" },
    { id: "jira", name: "Jira", icon: "🔧", color: "#D4D5E8" },
    { id: "typeform", name: "Typeform", icon: "📋", color: "#E8D4D4" },
    { id: "appstore", name: "App Store", icon: "🍎", color: "#D4E8E8" },
    { id: "csv", name: "CSV Upload", icon: "📄", color: "#E8E8D4" },
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

  const currentPlan = plans.find((p) => p.id === selectedPlan);

  const stepInfo = {
    1: {
      title: "Choose your plan",
      subtitle: "Start with a 14-day free trial",
      description: "Every plan gives you full access to feedback collection, sentiment analysis, and weekly AI syntheses. Upgrade or downgrade anytime.",
      visual: currentPlan ? (
        <div>
          <div className="bg-white/5 rounded-xl p-5 border border-white/10 mb-4">
            <div className="flex items-center justify-between mb-4">
              <span className="text-white font-semibold text-lg">{currentPlan.name}</span>
              <div className="flex items-baseline gap-0.5">
                <span className="text-2xl font-bold text-white">${currentPlan.price}</span>
                <span className="text-stone-400 text-sm">/mo</span>
              </div>
            </div>
            <div className="space-y-2.5">
              {currentPlan.features.map((f, i) => (
                <div key={i} className="flex items-center gap-2.5">
                  <svg className="w-4 h-4 text-emerald-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-stone-300 text-sm">{f}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="flex items-center gap-2 text-emerald-400 text-xs font-medium">
            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
            No credit card required for trial
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          {["Centralize all feedback", "AI-powered insights", "Track what you ship"].map((item, i) => (
            <div key={i} className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center text-emerald-400">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <span className="text-stone-300 text-sm">{item}</span>
            </div>
          ))}
        </div>
      ),
    },
    2: {
      title: "Create workspace",
      subtitle: "Your team's feedback hub",
      description: "Choose a name and URL for your workspace. This is where your team will access FeedbackMind.",
      visual: (
        <div className="bg-white/5 rounded-xl p-4 border border-white/10">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-6 h-6 bg-emerald-500/20 rounded flex items-center justify-center text-emerald-400 text-xs">FM</div>
            <span className="text-stone-300 text-sm font-medium">{workspaceName || "Your Workspace"}</span>
          </div>
          <div className="h-2 bg-white/5 rounded w-3/4 mb-2" />
          <div className="h-2 bg-white/5 rounded w-1/2" />
        </div>
      ),
    },
    3: {
      title: "Pick sources",
      subtitle: "Where does feedback come from?",
      description: "Select the tools your team uses. You'll authenticate and connect each one securely from your Sources dashboard after setup.",
      visual: (
        <div className="space-y-2">
          {selectedSources.length > 0 ? (
            selectedSources.map((id) => {
              const s = sources.find((src) => src.id === id);
              return (
                <div key={id} className="flex items-center gap-3 bg-white/5 rounded-lg px-3 py-2 border border-white/10">
                  <span>{s?.icon}</span>
                  <span className="text-stone-300 text-sm">{s?.name}</span>
                  <svg className="w-4 h-4 text-emerald-400 ml-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              );
            })
          ) : (
            <div className="text-stone-500 text-sm italic">No sources selected yet</div>
          )}
        </div>
      ),
    },
  };

  const info = stepInfo[step];

  return (
    <div className="min-h-screen flex" style={{ fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      {/* Left panel — dark info */}
      <div className="w-[420px] bg-stone-900 p-10 flex flex-col justify-between flex-shrink-0">
        <div>
          <div className="flex items-center gap-3 mb-16">
            <div className="w-9 h-9 bg-white rounded-xl flex items-center justify-center text-stone-900 text-xs font-bold">FM</div>
            <span className="text-lg font-semibold text-white" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>FeedbackMind</span>
          </div>

          <div className="mb-8">
            <div className="text-xs font-medium text-stone-500 uppercase tracking-wider mb-3">Step {step} of 3</div>
            <h1 className="text-2xl font-bold text-white mb-2" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>
              {info.title}
            </h1>
            <p className="text-emerald-400 text-sm font-medium mb-4">{info.subtitle}</p>
            <p className="text-stone-400 text-sm leading-relaxed">{info.description}</p>
          </div>

          <div className="mt-8">{info.visual}</div>
        </div>

        {/* Progress */}
        <div className="flex gap-2">
          {[1, 2, 3].map((s) => (
            <div
              key={s}
              className={`h-1 rounded-full flex-1 transition-all ${
                s <= step ? "bg-emerald-500" : "bg-white/10"
              }`}
            />
          ))}
        </div>
      </div>

      {/* Right panel — form */}
      <div className="flex-1 bg-stone-50 flex items-center justify-center p-10">
        <div className="w-full max-w-md">
          {/* Step 1: Plan Selection */}
          {step === 1 && (
            <div>
              <div className="space-y-3 mb-8">
                {plans.map((plan) => (
                  <button
                    key={plan.id}
                    onClick={() => setSelectedPlan(plan.id)}
                    className={`w-full text-left p-5 rounded-xl border-2 transition-all ${
                      selectedPlan === plan.id
                        ? "border-stone-900 bg-white shadow-md"
                        : "border-stone-200 bg-white hover:border-stone-300"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-stone-900">{plan.name}</span>
                        {plan.badge && (
                          <span className="text-[10px] font-bold bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full">
                            {plan.badge}
                          </span>
                        )}
                      </div>
                      <div className="flex items-baseline gap-0.5">
                        <span className="text-xl font-bold text-stone-900">${plan.price}</span>
                        <span className="text-stone-400 text-sm">/mo</span>
                      </div>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {plan.features.map((f, i) => (
                        <span key={i} className="text-xs bg-stone-100 text-stone-500 px-2 py-1 rounded-md">
                          {f}
                        </span>
                      ))}
                    </div>
                    {selectedPlan === plan.id && (
                      <div className="flex items-center gap-1.5 mt-3 text-sm text-emerald-600 font-medium">
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                        14-day free trial included
                      </div>
                    )}
                  </button>
                ))}
              </div>

              <button
                onClick={() => selectedPlan && setStep(2)}
                disabled={!selectedPlan}
                className={`w-full py-3 rounded-xl font-medium transition-all ${
                  selectedPlan
                    ? "bg-stone-900 text-white hover:bg-stone-800 shadow-lg"
                    : "bg-stone-200 text-stone-400 cursor-not-allowed"
                }`}
              >
                Continue →
              </button>
            </div>
          )}

          {/* Step 2: Workspace */}
          {step === 2 && (
            <div>
              <div className="bg-white rounded-xl border border-stone-200 p-6 mb-6 shadow-sm">
                <div className="mb-5">
                  <label className="block text-sm font-medium text-stone-700 mb-2">Workspace Name</label>
                  <input
                    type="text"
                    value={workspaceName}
                    onChange={(e) => handleNameChange(e.target.value)}
                    placeholder="Acme Product Team"
                    className="w-full px-4 py-3 rounded-xl border border-stone-300 text-stone-900 placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-stone-900/10 focus:border-stone-500"
                    autoFocus
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-stone-700 mb-2">Workspace URL</label>
                  <div className="flex items-center rounded-xl border border-stone-300 overflow-hidden focus-within:ring-2 focus-within:ring-stone-900/10">
                    <span className="px-3 py-3 bg-stone-50 text-stone-400 text-sm border-r border-stone-300">https://</span>
                    <input
                      type="text"
                      value={workspaceSlug}
                      onChange={(e) => setWorkspaceSlug(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ""))}
                      placeholder="acme"
                      className="flex-1 px-3 py-3 text-stone-900 placeholder-stone-400 focus:outline-none"
                    />
                    <span className="px-3 py-3 bg-stone-50 text-stone-400 text-sm border-l border-stone-300">.feedbackmind.io</span>
                  </div>
                </div>
              </div>

              <div className="flex gap-3">
                <button onClick={() => setStep(1)} className="px-5 py-3 rounded-xl border border-stone-300 text-stone-600 hover:bg-stone-100 font-medium">
                  ←
                </button>
                <button
                  onClick={() => workspaceName.trim() && setStep(3)}
                  disabled={!workspaceName.trim()}
                  className={`flex-1 py-3 rounded-xl font-medium transition-all ${
                    workspaceName.trim()
                      ? "bg-stone-900 text-white hover:bg-stone-800 shadow-lg"
                      : "bg-stone-200 text-stone-400 cursor-not-allowed"
                  }`}
                >
                  Continue →
                </button>
              </div>
            </div>
          )}

          {/* Step 3: Sources */}
          {step === 3 && (
            <div>
              <div className="grid grid-cols-2 gap-3 mb-6">
                {sources.map((source) => (
                  <button
                    key={source.id}
                    onClick={() => toggleSource(source.id)}
                    className={`flex items-center gap-3 p-4 rounded-xl border-2 transition-all text-left ${
                      selectedSources.includes(source.id)
                        ? "border-stone-900 bg-white shadow-sm"
                        : "border-stone-200 bg-white hover:border-stone-300"
                    }`}
                  >
                    <div
                      className="w-10 h-10 rounded-lg flex items-center justify-center text-xl flex-shrink-0"
                      style={{ backgroundColor: source.color }}
                    >
                      {source.icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-stone-900 text-sm">{source.name}</div>
                      {selectedSources.includes(source.id) && (
                        <div className="text-emerald-600 text-xs font-medium mt-0.5">Selected</div>
                      )}
                    </div>
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 ${
                      selectedSources.includes(source.id)
                        ? "bg-stone-900 border-stone-900"
                        : "border-stone-300"
                    }`}>
                      {selectedSources.includes(source.id) && (
                        <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                      )}
                    </div>
                  </button>
                ))}
              </div>

              <div className="bg-stone-100 rounded-xl p-3 mb-6 text-center">
                <p className="text-stone-500 text-xs">
                  Connections are made securely from your <strong>Sources</strong> dashboard. No popups during setup.
                </p>
              </div>

              <div className="flex gap-3">
                <button onClick={() => setStep(2)} className="px-5 py-3 rounded-xl border border-stone-300 text-stone-600 hover:bg-stone-100 font-medium">
                  ←
                </button>
                <button
                  className="flex-1 py-3 rounded-xl bg-stone-900 text-white hover:bg-stone-800 font-medium transition-all shadow-lg"
                >
                  Launch workspace →
                </button>
              </div>

              <button className="w-full text-center text-sm text-stone-400 mt-4 hover:text-stone-600">
                Skip — I'll add sources later
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default OnboardingOptionC;
