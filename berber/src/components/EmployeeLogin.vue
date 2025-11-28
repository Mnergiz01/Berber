<script setup>
import { ref } from 'vue'
import { supabase } from '../supabase'

const emit = defineEmits(['login-success'])

// Login form
const loginForm = ref({
  username: '',
  password: ''
})

const loading = ref(false)
const error = ref('')

// Çalışan girişi
const handleLogin = async () => {
  if (!loginForm.value.username || !loginForm.value.password) {
    error.value = 'Lütfen tüm alanları doldurun!'
    return
  }

  try {
    loading.value = true
    error.value = ''

    // Çalışan bilgilerini kontrol et
    const { data: employee, error: dbError } = await supabase
      .from('employees')
      .select('*')
      .eq('username', loginForm.value.username)
      .eq('password', loginForm.value.password)
      .eq('is_active', true)
      .single()

    if (dbError || !employee) {
      throw new Error('Kullanıcı adı veya şifre hatalı!')
    }

    // Çalışan bilgilerini localStorage'a kaydet
    localStorage.setItem('isEmployee', 'true')
    localStorage.setItem('employeeUser', JSON.stringify(employee))

    emit('login-success')
  } catch (err) {
    error.value = err.message
    loginForm.value.password = ''
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-purple-50 to-pink-100 p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md">
      <!-- Header -->
      <div class="text-center mb-8">
        <div class="bg-gradient-to-r from-purple-600 to-pink-600 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </div>
        <h2 class="text-3xl font-bold text-gray-900">Çalışan Girişi</h2>
        <p class="text-gray-600 mt-2">Randevularınızı yönetmek için giriş yapın</p>
      </div>

      <!-- Error Message -->
      <div v-if="error" class="mb-6 bg-red-50 border border-red-200 rounded-lg p-4 text-red-800 text-sm">
        {{ error }}
      </div>

      <!-- Login Form -->
      <form @submit.prevent="handleLogin" class="space-y-6">
        <div>
          <label for="username" class="block text-sm font-medium text-gray-700 mb-2">
            Kullanıcı Adı
          </label>
          <input
            id="username"
            v-model="loginForm.username"
            type="text"
            placeholder="kullanıcı adınız"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            autocomplete="username"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-gray-700 mb-2">
            Şifre
          </label>
          <input
            id="password"
            v-model="loginForm.password"
            type="password"
            placeholder="••••••••"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            autocomplete="current-password"
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-gradient-to-r from-purple-600 to-pink-600 text-white py-3 rounded-lg hover:from-purple-700 hover:to-pink-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="loading">Giriş Yapılıyor...</span>
          <span v-else>Giriş Yap</span>
        </button>
      </form>

      <!-- Info -->
      <div class="mt-6 text-center">
        <div class="pt-3 border-t">
          <p class="text-sm text-gray-600">
            Müşteri misiniz?
            <a href="/" class="text-purple-600 hover:text-purple-700 font-medium">Randevu almak için tıklayın</a>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
