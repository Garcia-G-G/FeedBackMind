import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const currentPath = window.location.pathname
    const navItems = this.element.querySelectorAll("a")

    navItems.forEach(item => {
      const href = item.getAttribute("href")
      if (href === currentPath || currentPath.startsWith(href + "/")) {
        item.classList.add("active")
        item.setAttribute("aria-current", "page")
      }
    })
  }
}
