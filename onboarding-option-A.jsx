import { useState } from "react";

// OPTION A: "Premium SaaS" — Single-page vertical flow with plan selection first
// Inspired by Linear, Notion, Vercel onboarding
const OnboardingOptionA = () => {
  const [step, setStep] = useState(1);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [workspaceName, setWorkspaceName] = useState("");
  const [workspaceSlug, setWorkspaceSlug] = useState("");
  const [selectedSources, setSelectedSources] = useState([]);

  const plans = [
    {
      id: "starter",
      name: "Starter",
      price: "$29",
      period: "/mo",
      description: "For small teams getting started",
      features: ["1 team member", "3 sources", "1,000 feedbacks/mo", "Weekly synthesis"],
      cta: "Start Free Trial",
      popular: false,
    },
    {
      id: "growth",
      name: "Growth",
      price: "$109",
      period: "/mo",
      description: "For growing product teams",
      features: ["5 team members", "10 sources", "10,000 feedbacks/mo", "AI Chat", "Priority support"],
      cta: "Start Free Trial",
      popular: true,
    },
    {
      id: "scale",
      name: "Scale",
      price: "$209",
      period: "/mo",
      description: "For teams that need everything",
      features: ["Unlimited members", "Unlimited sources", "Unlimited feedbacks", "API access", "Custom integrations"],
      cta: "Start Free Trial",
      popular: false,
    },
  ];

  const sources = [
    { id: "slack", name: "Slack", icon: "💬", desc: "Import from channels" },
    { id: "gmail", name: "Gmail", icon: "📧", desc: "Parse support emails" },
    { id: "jira", name: "Jira", icon: "🔧", desc: "Sync issue feedback" },
    { id: "typeform", name: "Typeform", icon: "📋", desc: "Survey responses" },
    { id: "appstore", name: "App Store", icon: "🍎", desc: "App reviews" },
    { id: "csv", name: "CSV Upload", icon: "📄", desc: "Import from file" },
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

  return (
    <div className="min-h-screen bg-stone-50" style={{ fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      {/* Top bar */}
      <div className="border-b border-stone-200 bg-white">
        <div className="max-w-5xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-stone-900 rounded-lg flex items-center justify-center text-white text-xs font-bold">FM</div>
            <span className="text-lg font-semibold text-stone-900" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>FeedbackMind</span>
          </div>
          <div className="flex items-center gap-1">
            {[1, 2, 3].map((s) => (
              <div key={s} className="flex items-center">
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium transition-all ${
                    s < step ? "bg-emerald-500 text-white" : s === step ? "bg-stone-900 text-white" : "bg-stone-200 text-stone-400"
                  }`}
                >
                  {s < step ? "✓" : s}
                </div>
                {s < 3 && <div className={`w-12 h-0.5 ${s < step ? "bg-emerald-500" : "bg-stone-200"}`} />}
              </div>
            ))}
          </div>
          <div className="text-sm text-stone-400">Step {step} of 3</div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-6 py-12">
        {/* STEP 1: Choose Plan */}
        {step === 1 && (
          <div className="animate-in">
            <div className="text-center mb-10">
              <h1 className="text-3xl font-bold text-stone-900 mb-2" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>
                Choose your plan
              </h1>
              <p className="text-stone-500 text-lg">All plans include a 14-day free trial. No credit card required.</p>
            </div>

            <div className="grid grid-cols-3 gap-6 mb-10">
              {plans.map((plan) => (
                <div
                  key={plan.id}
                  onClick={() => setSelectedPlan(plan.id)}
                  className={`relative bg-white rounded-2xl p-6 cursor-pointer transition-all border-2 ${
                    selectedPlan === plan.id
                      ? "border-stone-900 shadow-lg scale-[1.02]"
                      : "border-stone-200 hover:border-stone-300 hover:shadow-md"
                  }`}
                >
                  {plan.popular && (
                    <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-stone-900 text-white text-xs font-medium px-3 py-1 rounded-full">
                      Most Popular
                    </div>
                  )}
                  <div className="mb-4">
                    <h3 className="text-lg font-semibold text-stone-900">{plan.name}</h3>
                    <p className="text-stone-500 text-sm mt-1">{plan.description}</p>
                  </div>
                  <div className="mb-6">
                    <span className="text-4xl font-bold text-stone-900">{plan.price}</span>
                    <span className="text-stone-400">{plan.period}</span>
                  </div>
                  <ul className="space-y-2.5 mb-6">
                    {plan.features.map((f, i) => (
                      <li key={i} className="flex items-center gap-2 text-sm text-stone-600">
                        <svg className="w-4 h-4 text-emerald-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                        {f}
                      </li>
                    ))}
                  </ul>
                  <div
                    className={`w-full py-2.5 rounded-lg text-center text-sm font-medium transition-colors ${
                      selectedPlan === plan.id ? "bg-stone-900 text-white" : "bg-stone-100 text-stone-600"
                    }`}
                  >
                    {selectedPlan === plan.id ? "Selected" : plan.cta}
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-center">
              <button
                onClick={() => step === 1 && selectedPlan && setStep(2)}
                disabled={!selectedPlan}
                className={`px-8 py-3 rounded-xl text-base font-medium transition-all ${
                  selectedPlan
                    ? "bg-stone-900 text-white hover:bg-stone-800 shadow-lg shadow-stone-900/20"
                    : "bg-stone-200 text-stone-400 cursor-not-allowed"
                }`}
              >
                Continue with {selectedPlan ? plans.find((p) => p.id === selectedPlan)?.name : "..."} →
              </button>
            </div>
          </div>
        )}

        {/* STEP 2: Workspace Setup */}
        {step === 2 && (
          <div className="max-w-lg mx-auto">
            <div className="text-center mb-10">
              <h1 className="text-3xl font-bold text-stone-900 mb-2" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>
                Set up your workspace
              </h1>
              <p className="text-stone-500 text-lg">This is where your team will centralize feedback.</p>
            </div>

            <div className="bg-white rounded-2xl border border-stone-200 p-8 shadow-sm">
              <div className="mb-6">
                <label className="block text-sm font-medium text-stone-700 mb-2">Workspace Name</label>
                <input
                  type="text"
                  value={workspaceName}
                  onChange={(e) => handleNameChange(e.target.value)}
                  placeholder="Acme Inc."
                  className="w-full px-4 py-3 rounded-xl border border-stone-300 text-stone-900 placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-stone-900/10 focus:border-stone-500 text-base"
                />
              </div>

              <div className="mb-8">
                <label className="block text-sm font-medium text-stone-700 mb-2">Workspace URL</label>
                <div className="flex items-center">
                  <div className="px-4 py-3 bg-stone-50 border border-r-0 border-stone-300 rounded-l-xl text-stone-400 text-base">
                    https://
                  </div>
                  <input
                    type="text"
                    value={workspaceSlug}
                    onChange={(e) => setWorkspaceSlug(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ""))}
                    placeholder="acme"
                    className="flex-1 px-4 py-3 border border-stone-300 text-stone-900 placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-stone-900/10 focus:border-stone-500 text-base"
                  />
                  <div className="px-4 py-3 bg-stone-50 border border-l-0 border-stone-300 rounded-r-xl text-stone-400 text-base">
                    .feedbackmind.io
                  </div>
                </div>
              </div>

              <div className="flex gap-3">
                <button onClick={() => setStep(1)} className="px-6 py-3 rounded-xl border border-stone-300 text-stone-600 hover:bg-stone-50 font-medium">
                  ← Back
                </button>
                <button
                  onClick={() => workspaceName.trim() && setStep(3)}
                  disabled={!workspaceName.trim()}
                  className={`flex-1 py-3 rounded-xl font-medium transition-all ${
                    workspaceName.trim()
                      ? "bg-stone-900 text-white hover:bg-stone-800"
                      : "bg-stone-200 text-stone-400 cursor-not-allowed"
                  }`}
                >
                  Continue →
                </button>
              </div>
            </div>
          </div>
        )}

        {/* STEP 3: Pick Sources (connect later) */}
        {step === 3 && (
          <div className="max-w-2xl mx-auto">
            <div className="text-center mb-10">
              <h1 className="text-3xl font-bold text-stone-900 mb-2" style={{ fontFamily: "'DM Serif Display', Georgia, serif" }}>
                Where does your feedback live?
              </h1>
              <p className="text-stone-500 text-lg">Select the sources you'd like to connect. You'll set them up from your dashboard.</p>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-8">
              {sources.map((source) => (
                <div
                  key={source.id}
                  onClick={() => toggleSource(source.id)}
                  className={`bg-white rounded-xl p-5 cursor-pointer transition-all border-2 text-center ${
                    selectedSources.includes(source.id)
                      ? "border-stone-900 shadow-md"
                      : "border-stone-200 hover:border-stone-300"
                  }`}
                >
                  <div className="text-3xl mb-2">{source.icon}</div>
                  <div className="font-medium text-stone-900 text-sm">{source.name}</div>
                  <div className="text-xs text-stone-400 mt-1">{source.desc}</div>
                  {selectedSources.includes(source.id) && (
                    <div className="mt-2 inline-flex items-center gap-1 text-xs text-emerald-600 font-medium">
                      <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                      Selected
                    </div>
                  )}
                </div>
              ))}
            </div>

            <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-8 text-center">
              <p className="text-amber-800 text-sm">
                You'll connect your accounts securely from the <strong>Sources</strong> page after setup. No OAuth popups here.
              </p>
            </div>

            <div className="flex gap-3">
              <button onClick={() => setStep(2)} className="px-6 py-3 rounded-xl border border-stone-300 text-stone-600 hover:bg-stone-50 font-medium">
                ← Back
              </button>
              <button
                className="flex-1 py-3 rounded-xl bg-stone-900 text-white hover:bg-stone-800 font-medium transition-all shadow-lg shadow-stone-900/20"
              >
                Launch my workspace →
              </button>
            </div>

            <p className="text-center text-sm text-stone-400 mt-4">
              You can skip source selection and add them later
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default OnboardingOptionA;
