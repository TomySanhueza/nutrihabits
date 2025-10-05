import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["add_item", "template"]

  add_association(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/TEMPLATE_RECORD/g, new Date().getTime())
    const insertionNode = event.target.dataset.associationInsertionNode
    const insertionMethod = event.target.dataset.associationInsertionMethod || 'append'

    const container = document.querySelector(insertionNode)

    if (insertionMethod === 'append') {
      container.insertAdjacentHTML('beforeend', content)
    } else if (insertionMethod === 'prepend') {
      container.insertAdjacentHTML('afterbegin', content)
    }
  }

  remove_association(event) {
    event.preventDefault()

    const item = event.target.closest('.nested-fields')
    const destroyInput = item.querySelector("input[name*='_destroy']")

    if (destroyInput) {
      destroyInput.value = 1
      item.style.display = 'none'
    } else {
      item.remove()
    }
  }
}
