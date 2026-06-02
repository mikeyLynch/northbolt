import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "backdrop", "search", "article", "articlesView", "contactView", "drawerTitle", "backButton"]

  open() {
    this.drawerTarget.classList.remove("translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.drawerTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.showArticles()
  }

  showContact() {
    this.articlesViewTarget.classList.add("hidden")
    this.articlesViewTarget.classList.remove("flex")
    this.contactViewTarget.classList.remove("hidden")
    this.contactViewTarget.classList.add("flex")
    this.drawerTitleTarget.textContent = "Contact support"
    this.backButtonTarget.classList.remove("hidden")
  }

  showArticles() {
    this.contactViewTarget.classList.add("hidden")
    this.contactViewTarget.classList.remove("flex")
    this.articlesViewTarget.classList.remove("hidden")
    this.articlesViewTarget.classList.add("flex")
    this.drawerTitleTarget.textContent = "Help & support"
    this.backButtonTarget.classList.add("hidden")
  }

  search() {
    const query = this.searchTarget.value.toLowerCase().trim()
    this.articleTargets.forEach(article => {
      const title = article.dataset.title.toLowerCase()
      article.classList.toggle("hidden", query.length > 0 && !title.includes(query))
    })
  }
}
