<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  type: {
    type: String,
    default: 'info', // success, error, warning, info
    validator: (value) => ['success', 'error', 'warning', 'info'].includes(value)
  },
  title: {
    type: String,
    default: ''
  },
  message: {
    type: String,
    required: true
  },
  duration: {
    type: Number,
    default: 5000
  }
})

const emit = defineEmits(['close'])

const getIcon = () => {
  const icons = {
    success: `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>`,
    error: `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>`,
    warning: `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
    </svg>`,
    info: `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>`
  }
  return icons[props.type] || icons.info
}

const getColorClasses = () => {
  const colors = {
    success: {
      bg: 'bg-green-50',
      border: 'border-green-500',
      icon: 'text-green-600',
      title: 'text-green-900',
      text: 'text-green-800'
    },
    error: {
      bg: 'bg-red-50',
      border: 'border-red-500',
      icon: 'text-red-600',
      title: 'text-red-900',
      text: 'text-red-800'
    },
    warning: {
      bg: 'bg-yellow-50',
      border: 'border-yellow-500',
      icon: 'text-yellow-600',
      title: 'text-yellow-900',
      text: 'text-yellow-800'
    },
    info: {
      bg: 'bg-blue-50',
      border: 'border-blue-500',
      icon: 'text-blue-600',
      title: 'text-blue-900',
      text: 'text-blue-800'
    }
  }
  return colors[props.type] || colors.info
}
</script>

<template>
  <Transition
    enter-active-class="transition ease-out duration-300 transform"
    enter-from-class="translate-x-full opacity-0"
    enter-to-class="translate-x-0 opacity-100"
    leave-active-class="transition ease-in duration-200 transform"
    leave-from-class="translate-x-0 opacity-100"
    leave-to-class="translate-x-full opacity-0"
  >
    <div
      v-if="show"
      :class="[
        'fixed top-20 right-4 z-50 max-w-sm w-full rounded-xl shadow-2xl border-l-4 overflow-hidden',
        getColorClasses().bg,
        getColorClasses().border
      ]"
    >
      <div class="p-4">
        <div class="flex items-start gap-3">
          <!-- Icon -->
          <div :class="['flex-shrink-0', getColorClasses().icon]">
            <div v-html="getIcon()"></div>
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <h4
              v-if="title"
              :class="['text-sm font-bold mb-1', getColorClasses().title]"
            >
              {{ title }}
            </h4>
            <p :class="['text-sm', getColorClasses().text]">
              {{ message }}
            </p>
          </div>

          <!-- Close button -->
          <button
            @click="emit('close')"
            class="flex-shrink-0 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>

      <!-- Progress bar -->
      <div class="h-1 bg-gray-200">
        <div
          :class="['h-full transition-all', getColorClasses().border.replace('border-', 'bg-')]"
          :style="{ animation: `shrink ${duration}ms linear` }"
        ></div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
@keyframes shrink {
  from {
    width: 100%;
  }
  to {
    width: 0%;
  }
}
</style>
