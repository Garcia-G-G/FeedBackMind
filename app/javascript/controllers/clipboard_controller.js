import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
    const btn = this.element.querySelector("[data-action*='clipboard#copy']")
    const original = btn.textContent
    btn.textContent = "Copied!"
    btn.classList.add("text-green-600", "border-green-300")
    setTimeout(() => {
      btn.textContent = original
      btn.classList.remove("text-green-600", "border-green-300")
    }, 2000)
  }
}
