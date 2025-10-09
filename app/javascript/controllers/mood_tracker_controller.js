import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "saveButton"]
  static values = {
    type: String
  }

  connect() {
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.style.display = 'none'
    }
  }

  select(event) {
    const clickedOption = event.currentTarget
    const wasSelected = clickedOption.classList.contains('bg-success')

    // Primero removemos la selección de todos
    this.optionTargets.forEach(option => {
      option.classList.remove('bg-success', 'bg-opacity-10')
    })

    // Si el elemento clickeado no estaba seleccionado, lo seleccionamos
    if (!wasSelected) {
      clickedOption.classList.add('bg-success', 'bg-opacity-10')
      if (this.hasSaveButtonTarget) {
        this.saveButtonTarget.style.display = 'block'
      }
    } else {
      // Si estaba seleccionado, ocultamos el botón de guardar
      if (this.hasSaveButtonTarget) {
        this.saveButtonTarget.style.display = 'none'
      }
    }
  }

  save() {
    const selectedOption = this.optionTargets.find(option => 
      option.classList.contains('bg-success')
    )
    
    if (!selectedOption) return

    const value = selectedOption.dataset.value
    const type = this.typeValue

    fetch('/pats/update_status', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        type: type,
        value: value
      })
    }).then(response => {
      if (response.ok) {
        this.saveButtonTarget.style.display = 'none'
        // Mostrar un mensaje de éxito temporal
        this.showSuccessMessage()
      }
    })
  }

  showSuccessMessage() {
    const message = document.createElement('div')
    message.className = 'alert alert-success py-2 mt-2 mb-0 text-center'
    message.textContent = '¡Registro guardado!'
    this.saveButtonTarget.insertAdjacentElement('afterend', message)

    setTimeout(() => {
      message.remove()
    }, 2000)
  }

  cancel() {
    // Remover todas las selecciones
    this.optionTargets.forEach(option => {
      option.classList.remove('bg-success', 'bg-opacity-10')
    })
    
    // Ocultar el botón de guardar
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.style.display = 'none'
    }
  }
}