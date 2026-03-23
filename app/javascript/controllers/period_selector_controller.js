import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btn"]

  select(event) {
    const clickedButton = event.currentTarget

    this.btnTargets.forEach(button => {
      button.classList.remove("bg-white", "text-stone-900", "shadow-sm")
      button.classList.add("text-stone-400")
    })

    clickedButton.classList.remove("text-stone-400")
    clickedButton.classList.add("bg-white", "text-stone-900", "shadow-sm")

    const period = clickedButton.getAttribute("data-period")
    const url = new URL(window.location)
    url.searchParams.set("period", period)
    Turbo.visit(url.toString())
  }
}
