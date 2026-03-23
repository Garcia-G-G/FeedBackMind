import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "fab", "messages", "input"]

  connect() {
    window.addEventListener("open-chat", () => this.open())
  }

  disconnect() {
    window.removeEventListener("open-chat", () => this.open())
  }

  toggle() {
    const isHidden = this.panelTarget.classList.contains("hidden")

    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.panelTarget.classList.add("flex")
    this.inputTarget.focus()
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.panelTarget.classList.remove("flex")
  }

  send(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const message = this.inputTarget.value.trim()
    if (!message) return

    this.appendMessage(message, "user")
    this.inputTarget.value = ""
    this.inputTarget.focus()

    this.showLoading()

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken,
        "X-Requested-With": "XMLHttpRequest"
      },
      body: JSON.stringify({ message }),
      credentials: "same-origin"
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      return response.json()
    })
    .then(data => {
      this.hideLoading()
      if (data.assistant_message) {
        this.appendMessage(data.assistant_message.content, "ai")
      }
      this.scrollToBottom()
    })
    .catch(error => {
      console.error("Chat error:", error)
      this.hideLoading()
      this.appendMessage("Sorry, something went wrong. Please try again.", "ai")
      this.scrollToBottom()
    })
  }

  useSuggestion(event) {
    const text = event.target.textContent
    this.inputTarget.value = text
    this.send()
  }

  appendMessage(content, role) {
    const div = document.createElement("div")
    div.textContent = content

    if (role === "user") {
      div.className = "max-w-[85%] text-[13px] leading-relaxed px-3.5 py-2.5 rounded-xl rounded-br bg-stone-900 text-white self-end"
    } else if (role === "ai") {
      div.className = "max-w-[85%] text-[13px] leading-relaxed px-3.5 py-2.5 rounded-xl rounded-bl bg-stone-50 self-start"
    }

    this.messagesTarget.appendChild(div)
    this.scrollToBottom()
  }

  showLoading() {
    const loadingDiv = document.createElement("div")
    loadingDiv.id = "chat-loading"
    loadingDiv.className = "flex gap-1 self-start"
    loadingDiv.innerHTML = `
      <div class="w-2 h-2 bg-stone-400 rounded-full animate-bounce" style="animation-delay: 0s"></div>
      <div class="w-2 h-2 bg-stone-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
      <div class="w-2 h-2 bg-stone-400 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
    `
    this.messagesTarget.appendChild(loadingDiv)
    this.scrollToBottom()
  }

  hideLoading() {
    const loadingDiv = document.getElementById("chat-loading")
    if (loadingDiv) {
      loadingDiv.remove()
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
