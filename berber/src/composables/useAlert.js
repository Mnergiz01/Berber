import { ref } from 'vue'

const alertState = ref({
  show: false,
  type: 'info',
  title: '',
  message: '',
  confirmText: 'Tamam',
  cancelText: 'İptal',
  onConfirm: null,
  onCancel: null
})

const notificationState = ref({
  show: false,
  type: 'info',
  title: '',
  message: '',
  duration: 5000
})

export function useAlert() {
  const showAlert = ({ type = 'info', title = '', message, confirmText = 'Tamam' }) => {
    return new Promise((resolve) => {
      alertState.value = {
        show: true,
        type,
        title,
        message,
        confirmText,
        cancelText: 'İptal',
        onConfirm: () => resolve(true),
        onCancel: () => resolve(false)
      }
    })
  }

  const showConfirm = ({
    type = 'confirm',
    title = 'Onay',
    message,
    confirmText = 'Evet',
    cancelText = 'Hayır'
  }) => {
    return new Promise((resolve) => {
      alertState.value = {
        show: true,
        type,
        title,
        message,
        confirmText,
        cancelText,
        onConfirm: () => resolve(true),
        onCancel: () => resolve(false)
      }
    })
  }

  const showSuccess = (message, title = 'Başarılı') => {
    return showAlert({ type: 'success', title, message })
  }

  const showError = (message, title = 'Hata') => {
    return showAlert({ type: 'error', title, message })
  }

  const showWarning = (message, title = 'Uyarı') => {
    return showAlert({ type: 'warning', title, message })
  }

  const showInfo = (message, title = 'Bilgi') => {
    return showAlert({ type: 'info', title, message })
  }

  const closeAlert = () => {
    alertState.value.show = false
  }

  const handleConfirm = () => {
    if (alertState.value.onConfirm) {
      alertState.value.onConfirm()
    }
    closeAlert()
  }

  const handleCancel = () => {
    if (alertState.value.onCancel) {
      alertState.value.onCancel()
    }
    closeAlert()
  }

  return {
    alertState,
    showAlert,
    showConfirm,
    showSuccess,
    showError,
    showWarning,
    showInfo,
    closeAlert,
    handleConfirm,
    handleCancel
  }
}

export function useNotification() {
  let timeoutId = null

  const showNotification = ({
    type = 'info',
    title = '',
    message,
    duration = 5000
  }) => {
    notificationState.value = {
      show: true,
      type,
      title,
      message,
      duration
    }

    if (timeoutId) {
      clearTimeout(timeoutId)
    }

    timeoutId = setTimeout(() => {
      closeNotification()
    }, duration)
  }

  const showSuccessNotification = (message, title = 'Başarılı') => {
    showNotification({ type: 'success', title, message })
  }

  const showErrorNotification = (message, title = 'Hata') => {
    showNotification({ type: 'error', title, message })
  }

  const showWarningNotification = (message, title = 'Uyarı') => {
    showNotification({ type: 'warning', title, message })
  }

  const showInfoNotification = (message, title = 'Bilgi') => {
    showNotification({ type: 'info', title, message })
  }

  const closeNotification = () => {
    notificationState.value.show = false
    if (timeoutId) {
      clearTimeout(timeoutId)
      timeoutId = null
    }
  }

  return {
    notificationState,
    showNotification,
    showSuccessNotification,
    showErrorNotification,
    showWarningNotification,
    showInfoNotification,
    closeNotification
  }
}
