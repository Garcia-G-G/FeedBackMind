import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btn"]

  switch(event) {
    const clickedButton = event.currentTarget

    this.btnTargets.forEach(button => {
      button.classList.remove("bg-white", "text-gray-900", "shadow-sm")
      button.classList.add("text-gray-400")
    })

    clickedButton.classList.remove("text-gray-400")
    clickedButton.classList.add("bg-white", "text-gray-900", "shadow-sm")

    const role = clickedButton.getAttribute("data-role")
    window.dispatchEvent(new CustomEvent("role-changed", { detail: { role } }))
  }
}
