<script setup>
import { ref, onMounted } from 'vue'
import AppointmentList from './components/AppointmentList.vue'
import AppointmentForm from './components/AppointmentForm.vue'
import AdminLogin from './components/AdminLogin.vue'
import CustomAlert from './components/CustomAlert.vue'
import NotificationToast from './components/NotificationToast.vue'
import { useAlert, useNotification } from './composables/useAlert'
import { supabase } from './supabase'

const isAdmin = ref(false)
const showAdminLogin = ref(false)
const adminUser = ref(null)
const loading = ref(true)

const { alertState, closeAlert, handleConfirm, handleCancel } = useAlert()
const { notificationState, closeNotification, showSuccessNotification } = useNotification()

// Real-time bildirim sistemi
let appointmentSubscription = null

onMounted(() => {
  // LocalStorage'dan kullanıcı durumunu kontrol et
  checkAdminStatus()
  loading.value = false

  // Admin için real-time bildirim sistemi
  if (isAdmin.value) {
    setupRealtimeNotifications()
  }
})

const setupRealtimeNotifications = () => {
  // Yeni randevular için real-time subscription
  appointmentSubscription = supabase
    .channel('appointments_channel')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'appointments'
      },
      async (payload) => {
        // Yeni randevu bildirimi
        const appointment = payload.new

        // Çalışan ve hizmet bilgilerini al
        const [employeeData, serviceData] = await Promise.all([
          supabase.from('employees').select('name').eq('id', appointment.employee_id).single(),
          supabase.from('services').select('name').eq('id', appointment.service_id).single()
        ])

        const employeeName = employeeData.data?.name || 'Bilinmeyen'
        const serviceName = serviceData.data?.name || 'Bilinmeyen'
        const date = new Date(appointment.appointment_date).toLocaleDateString('tr-TR')
        const time = appointment.appointment_time.substring(0, 5)

        showSuccessNotification(
          `${appointment.customer_name} - ${serviceName}\n${employeeName} | ${date} ${time}`,
          '🔔 Yeni Randevu!'
        )
      }
    )
    .subscribe()
}

const checkAdminStatus = () => {
  const adminStatus = localStorage.getItem('isAdmin')
  const adminUserData = localStorage.getItem('adminUser')

  if (adminStatus === 'true' && adminUserData) {
    isAdmin.value = true
    adminUser.value = JSON.parse(adminUserData)
  } else {
    isAdmin.value = false
    adminUser.value = null
  }
}

const handleAdminLogin = () => {
  checkAdminStatus()
  showAdminLogin.value = false
}

const logout = () => {
  localStorage.removeItem('isAdmin')
  localStorage.removeItem('adminUser')
  isAdmin.value = false
  adminUser.value = null
}

const openAdminLogin = () => {
  showAdminLogin.value = true
}
</script>

<template>
  <div>
    <!-- Yönetici Giriş Ekranı -->
    <AdminLogin v-if="showAdminLogin" @login-success="handleAdminLogin" />

    <!-- Ana Uygulama -->
    <div v-else class="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50">
    <!-- Header - Mobil Uyumlu -->
    <header class="bg-white shadow-lg sticky top-0 z-50 border-b-2 border-indigo-100">
      <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-3 sm:py-4">
        <div class="flex items-center justify-between">
          <!-- Logo ve Başlık -->
          <div class="flex items-center space-x-2 sm:space-x-3">
            <div class="bg-gradient-to-br from-indigo-600 to-purple-600 rounded-xl p-1.5 sm:p-2 shadow-lg">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 sm:h-8 sm:w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.121 14.121L19 19m-7-7l7-7m-7 7l-2.879 2.879M12 12L9.121 9.121m0 5.758a3 3 0 10-4.243 4.243 3 3 0 004.243-4.243zm0-5.758a3 3 0 10-4.243-4.243 3 3 0 004.243 4.243z" />
              </svg>
            </div>
            <div>
              <h1 class="text-lg sm:text-2xl lg:text-3xl font-bold text-gray-900 leading-tight">Berber Randevu</h1>
              <p class="text-xs sm:text-sm text-gray-600 hidden sm:block">Online randevu sistemi</p>
            </div>
          </div>

          <!-- Navigation - Mobil Uyumlu -->
          <nav class="flex items-center gap-2 sm:gap-3">
            <!-- Admin kullanıcı bilgisi - Desktop -->
            <div v-if="isAdmin && adminUser" class="hidden lg:flex items-center gap-2">
              <div class="flex items-center text-sm text-gray-600 bg-indigo-50 px-3 py-2 rounded-lg">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                <span class="font-semibold text-gray-900">{{ adminUser.full_name }}</span>
              </div>
              <div class="px-2 py-1 rounded text-xs font-semibold bg-purple-100 text-purple-800">
                Admin
              </div>
            </div>

            <!-- Kullanıcı bilgisi - Mobile (sadece ikon) -->
            <div v-if="isAdmin && adminUser" class="lg:hidden flex items-center bg-indigo-50 p-2 rounded-lg">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>

            <!-- Giriş Butonu - Giriş yapılmamışsa -->
            <div v-if="!isAdmin">
              <!-- Yönetici Girişi butonu -->
              <button
                @click="openAdminLogin"
                class="px-3 py-2 sm:px-4 sm:py-2 rounded-lg font-medium transition-all duration-200 bg-gradient-to-r from-indigo-600 to-purple-600 text-white hover:from-indigo-700 hover:to-purple-700 text-xs sm:text-sm shadow-md hover:shadow-lg flex items-center gap-1 sm:gap-2"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
                <span class="hidden sm:inline">Yönetici Girişi</span>
                <span class="sm:hidden">Giriş</span>
              </button>
            </div>

            <!-- Çıkış butonu -->
            <button
              v-if="isAdmin"
              @click="logout"
              class="px-3 py-2 sm:px-4 sm:py-2 rounded-lg font-medium transition-all duration-200 bg-red-50 text-red-700 hover:bg-red-100 text-xs sm:text-sm shadow-sm hover:shadow-md flex items-center gap-1 sm:gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
              <span class="hidden sm:inline">Çıkış</span>
            </button>
          </nav>
        </div>
      </div>
    </header>

    <!-- Main Content - Mobil Padding -->
    <main class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
      <!-- Yönetici ise tüm randevuları göster -->
      <AppointmentList v-if="isAdmin" :admin-user="adminUser" :is-admin="true" />

      <!-- Normal kullanıcı ise sadece randevu formunu göster -->
      <div v-else>
        <!-- Randevu Alma Formu (çalışan seçimi içinde) -->
        <AppointmentForm />
      </div>
    </main>

    <!-- Footer - Mobil Uyumlu -->
    <footer class="bg-white border-t-2 border-indigo-100 mt-8 sm:mt-12">
      <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-6">
        <div class="text-center">
          <p class="text-xs sm:text-sm text-gray-600">&copy; 2025 Berber Randevu Sistemi</p>
          <p class="text-xs sm:text-sm text-gray-500 mt-1">Muzaffer Nergiz</p>
          <p class="text-xs text-gray-500 mt-1">Tüm hakları saklıdır</p>
        </div>
      </div>
    </footer>
    </div>

    <!-- Global Alert Dialog -->
    <CustomAlert
      :show="alertState.show"
      :type="alertState.type"
      :title="alertState.title"
      :message="alertState.message"
      :confirm-text="alertState.confirmText"
      :cancel-text="alertState.cancelText"
      @close="closeAlert"
      @confirm="handleConfirm"
      @cancel="handleCancel"
    />

    <!-- Global Notification Toast -->
    <NotificationToast
      :show="notificationState.show"
      :type="notificationState.type"
      :title="notificationState.title"
      :message="notificationState.message"
      :duration="notificationState.duration"
      @close="closeNotification"
    />
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
