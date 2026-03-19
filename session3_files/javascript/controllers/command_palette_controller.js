import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "box", "input", "results", "result"]
  static values = { selectedIndex: Number }

  selectedIndexValue = 0

  connect() {
    this.selectedIndexValue = 0
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.value = ""
    this.filter()
  }

  close() {
    this.overlayTarget.classList.add("hidden")
  }

  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    const isOpen = !this.overlayTarget.classList.contains("hidden")

    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      if (isOpen) {
        this.close()
      } else {
        this.open()
      }
      return
    }

    if (!isOpen) return

    switch (event.key) {
      case "Escape":
        event.preventDefault()
        this.close()
        break
      case "ArrowDown":
        event.preventDefault()
        this.moveSelection(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveSelection(-1)
        break
      case "Enter":
        event.preventDefault()
        this.selectCurrent()
        break
    }
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    const visibleResults = []

    this.resultTargets.forEach((result, index) => {
      const text = result.textContent.toLowerCase()
      const matches = text.includes(query)

      if (matches) {
        result.classList.remove("hidden")
        visibleResults.push(index)
      } else {
        result.classList.add("hidden")
      }
    })

    this.selectedIndexValue = 0
    this.updateSelection()
  }

  moveSelection(direction) {
    const visibleResults = this.resultTargets.filter(r => !r.classList.contains("hidden"))

    if (visibleResults.length === 0) return

    const currentElement = this.resultTargets[this.selectedIndexValue]
    let nextIndex = this.resultTargets.indexOf(visibleResults[0])

    if (currentElement && visibleResults.includes(currentElement)) {
      const currentVisibleIndex = visibleResults.indexOf(currentElement)
      const newVisibleIndex = Math.max(0, Math.min(visibleResults.length - 1, currentVisibleIndex + direction))
      nextIndex = this.resultTargets.indexOf(visibleResults[newVisibleIndex])
    }

    this.selectedIndexValue = nextIndex
    this.updateSelection()
  }

  updateSelection() {
    this.resultTargets.forEach((result, index) => {
      if (index === this.selectedIndexValue && !result.classList.contains("hidden")) {
        result.classList.add("bg-indigo-50")
        result.scrollIntoView({ block: "nearest" })
      } else {
        result.classList.remove("bg-indigo-50")
      }
    })
  }

  selectCurrent() {
    const selectedResult = this.resultTargets[this.selectedIndexValue]
    if (selectedResult && !selectedResult.classList.contains("hidden")) {
      selectedResult.click()
    }
  }

  openChat() {
    this.close()
    window.dispatchEvent(new CustomEvent("open-chat"))
  }
}
