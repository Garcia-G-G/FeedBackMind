import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const button = event.currentTarget
    const plan = button.dataset.plan

    document.getElementById("selected-plan").value = plan

    document.querySelectorAll(".plan-card").forEach(card => {
      card.classList.remove("border-stone-900", "shadow-md")
      card.classList.add("border-stone-200")
      card.querySelector(".plan-check")?.classList.add("hidden")
    })

    button.classList.remove("border-stone-200")
    button.classList.add("border-stone-900", "shadow-md")
    button.querySelector(".plan-check")?.classList.remove("hidden")

    const btn = document.getElementById("plan-continue-btn")
    btn.disabled = false
    btn.classList.remove("bg-stone-200", "text-stone-400", "cursor-not-allowed")
    btn.classList.add("bg-stone-900", "text-white", "hover:bg-stone-800", "shadow-lg", "shadow-stone-900/20")
  }
}
