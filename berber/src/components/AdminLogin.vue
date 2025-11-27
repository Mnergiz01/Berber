<script setup>
import { ref } from 'vue'
import { supabase } from '../supabase'

const emit = defineEmits(['login-success'])

const showForgotPassword = ref(false)
const showChangePassword = ref(false)

// Login form
const loginForm = ref({
  email: '',
  password: ''
})

// Change password form
const changePasswordForm = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// Forgot password form
const forgotPasswordEmail = ref('')

const loading = ref(false)
const error = ref('')
const successMessage = ref('')

// Login işlemi
const handleLogin = async () => {
  if (!loginForm.value.email || !loginForm.value.password) {
    error.value = 'Lütfen tüm alanları doldurun!'
    return
  }

  try {
    loading.value = true
    error.value = ''

    const { data, error: signInError } = await supabase.auth.signInWithPassword({
      email: loginForm.value.email,
      password: loginForm.value.password
    })

    if (signInError) throw signInError

    // Admin kullanıcısı kontrolü
    const { data: adminUser, error: adminError } = await supabase
      .from('admin_users')
      .select('*')
      .eq('auth_id', data.user.id)
      .eq('is_active', true)
      .single()

    if (adminError || !adminUser) {
      await supabase.auth.signOut()
      throw new Error('Bu hesap yönetici yetkisine sahip değil!')
    }

    emit('login-success')
  } catch (err) {
    error.value = err.message
    loginForm.value.password = ''
  } finally {
    loading.value = false
  }
}

// Şifre değiştirme işlemi
const handleChangePassword = async () => {
  if (!changePasswordForm.value.currentPassword || !changePasswordForm.value.newPassword || !changePasswordForm.value.confirmPassword) {
    error.value = 'Lütfen tüm alanları doldurun!'
    return
  }

  if (changePasswordForm.value.newPassword !== changePasswordForm.value.confirmPassword) {
    error.value = 'Yeni şifreler eşleşmiyor!'
    return
  }

  if (changePasswordForm.value.newPassword.length < 6) {
    error.value = 'Yeni şifre en az 6 karakter olmalıdır!'
    return
  }

  try {
    loading.value = true
    error.value = ''

    // Önce mevcut şifre ile giriş yaparak doğrula
    const { data: session } = await supabase.auth.getSession()
    if (!session.session) {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: loginForm.value.email,
        password: changePasswordForm.value.currentPassword
      })
      if (signInError) {
        throw new Error('Mevcut şifre hatalı!')
      }
    }

    // Şifreyi değiştir
    const { error: updateError } = await supabase.auth.updateUser({
      password: changePasswordForm.value.newPassword
    })

    if (updateError) throw updateError

    successMessage.value = 'Şifreniz başarıyla değiştirildi!'
    changePasswordForm.value = {
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    }

    setTimeout(() => {
      showChangePassword.value = false
      successMessage.value = ''
    }, 2000)
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

// Şifre sıfırlama
const handleForgotPassword = async () => {
  if (!forgotPasswordEmail.value) {
    error.value = 'Lütfen e-posta adresinizi girin!'
    return
  }

  try {
    loading.value = true
    error.value = ''

    const { error: resetError } = await supabase.auth.resetPasswordForEmail(
      forgotPasswordEmail.value,
      {
        redirectTo: `${window.location.origin}/`
      }
    )

    if (resetError) throw resetError

    successMessage.value = 'Şifre sıfırlama bağlantısı e-postanıza gönderildi!'
    forgotPasswordEmail.value = ''

    setTimeout(() => {
      showForgotPassword.value = false
      successMessage.value = ''
    }, 3000)
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const toggleForgotPassword = () => {
  showForgotPassword.value = !showForgotPassword.value
  showChangePassword.value = false
  error.value = ''
  successMessage.value = ''
}

const toggleChangePassword = () => {
  showChangePassword.value = !showChangePassword.value
  showForgotPassword.value = false
  error.value = ''
  successMessage.value = ''
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md">
      <!-- Header -->
      <div class="text-center mb-8">
        <div class="bg-indigo-600 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        <h2 class="text-3xl font-bold text-gray-900">
          {{ showChangePassword ? 'Şifre Değiştir' : showForgotPassword ? 'Şifre Sıfırlama' : 'Yönetici Girişi' }}
        </h2>
        <p class="text-gray-600 mt-2">
          {{ showChangePassword ? 'Yeni şifrenizi belirleyin' : showForgotPassword ? 'Şifrenizi sıfırlayın' : 'Randevuları yönetmek için giriş yapın' }}
        </p>
      </div>

      <!-- Success Message -->
      <div v-if="successMessage" class="mb-6 bg-green-50 border border-green-200 rounded-lg p-4 text-green-800 text-sm">
        {{ successMessage }}
      </div>

      <!-- Error Message -->
      <div v-if="error" class="mb-6 bg-red-50 border border-red-200 rounded-lg p-4 text-red-800 text-sm">
        {{ error }}
      </div>

      <!-- Login Form -->
      <form v-if="!showForgotPassword && !showChangePassword" @submit.prevent="handleLogin" class="space-y-6">
        <div>
          <label for="email" class="block text-sm font-medium text-gray-700 mb-2">
            E-posta
          </label>
          <input
            id="email"
            v-model="loginForm.email"
            type="email"
            placeholder="admin@admin.com"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            autocomplete="email"
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
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            autocomplete="current-password"
          />
        </div>

        <div class="flex items-center justify-between">
          <button
            type="button"
            @click="toggleChangePassword"
            class="text-sm text-indigo-600 hover:text-indigo-700"
          >
            Şifre Değiştir
          </button>
          <button
            type="button"
            @click="toggleForgotPassword"
            class="text-sm text-indigo-600 hover:text-indigo-700"
          >
            Şifremi Unuttum
          </button>
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-indigo-600 text-white py-3 rounded-lg hover:bg-indigo-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="loading">Giriş Yapılıyor...</span>
          <span v-else>Giriş Yap</span>
        </button>
      </form>

      <!-- Change Password Form -->
      <form v-if="showChangePassword" @submit.prevent="handleChangePassword" class="space-y-6">
        <div>
          <label for="currentPassword" class="block text-sm font-medium text-gray-700 mb-2">
            Mevcut Şifre
          </label>
          <input
            id="currentPassword"
            v-model="changePasswordForm.currentPassword"
            type="password"
            placeholder="Mevcut şifreniz"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <div>
          <label for="newPassword" class="block text-sm font-medium text-gray-700 mb-2">
            Yeni Şifre
          </label>
          <input
            id="newPassword"
            v-model="changePasswordForm.newPassword"
            type="password"
            placeholder="En az 6 karakter"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <div>
          <label for="confirmNewPassword" class="block text-sm font-medium text-gray-700 mb-2">
            Yeni Şifre Tekrar
          </label>
          <input
            id="confirmNewPassword"
            v-model="changePasswordForm.confirmPassword"
            type="password"
            placeholder="Yeni şifrenizi tekrar girin"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-indigo-600 text-white py-3 rounded-lg hover:bg-indigo-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="loading">Değiştiriliyor...</span>
          <span v-else>Şifreyi Değiştir</span>
        </button>
      </form>

      <!-- Forgot Password Form -->
      <form v-if="showForgotPassword" @submit.prevent="handleForgotPassword" class="space-y-6">
        <div>
          <label for="forgotEmail" class="block text-sm font-medium text-gray-700 mb-2">
            E-posta
          </label>
          <input
            id="forgotEmail"
            v-model="forgotPasswordEmail"
            type="email"
            placeholder="admin@admin.com"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-indigo-600 text-white py-3 rounded-lg hover:bg-indigo-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span v-if="loading">Gönderiliyor...</span>
          <span v-else>Sıfırlama Linki Gönder</span>
        </button>
      </form>

      <!-- Toggle Links -->
      <div class="mt-6 text-center space-y-3">
        <button
          v-if="showChangePassword || showForgotPassword"
          @click="showChangePassword = false; showForgotPassword = false; error = ''; successMessage = ''"
          class="text-sm text-indigo-600 hover:text-indigo-700 font-medium"
        >
          ← Giriş sayfasına dön
        </button>

        <div class="pt-3 border-t">
          <p class="text-sm text-gray-600">
            Müşteri misiniz?
            <a href="/" class="text-indigo-600 hover:text-indigo-700 font-medium">Randevu almak için tıklayın</a>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
