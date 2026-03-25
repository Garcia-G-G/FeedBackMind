import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const button = event.currentTarget
    const isSelected = button.classList.contains("border-stone-900")

    if (isSelected) {
      button.classList.remove("border-stone-900", "shadow-sm")
      button.classList.add("border-stone-200")
      button.querySelector(".source-selected-label")?.classList.add("hidden")
      const check = button.querySelector(".source-check")
      check.classList.remove("bg-stone-900", "border-stone-900")
      check.classList.add("border-stone-300")
      check.innerHTML = ""
    } else {
      button.classList.remove("border-stone-200")
      button.classList.add("border-stone-900", "shadow-sm")
      button.querySelector(".source-selected-label")?.classList.remove("hidden")
      const check = button.querySelector(".source-check")
      check.classList.remove("border-stone-300")
      check.classList.add("bg-stone-900", "border-stone-900")
      check.innerHTML = '<svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>'
    }

    this.updateHiddenField()
  }

  skip() {
    document.getElementById("selected-sources").value = ""
    document.getElementById("sources-form").requestSubmit()
  }

  updateHiddenField() {
    const selected = Array.from(document.querySelectorAll(".source-card.border-stone-900"))
      .map(card => card.dataset.source)
    document.getElementById("selected-sources").value = selected.join(",")
  }
}
