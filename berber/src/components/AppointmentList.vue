<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase'
import ServicesManagement from './ServicesManagement.vue'
import EmployeesManagement from './EmployeesManagement.vue'

const props = defineProps({
  adminUser: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['create-appointment'])

const appointments = ref([])
const employees = ref([])
const services = ref([])
const loading = ref(true)
const error = ref(null)
const selectedDate = ref(new Date().toISOString().split('T')[0])
const activeTab = ref('appointments')

onMounted(async () => {
  await fetchData()
})

const fetchData = async () => {
  try {
    loading.value = true
    error.value = null

    // Randevular için sorguyu oluştur
    let appointmentsQuery = supabase
      .from('appointments')
      .select('*')
      .order('appointment_date', { ascending: true })
      .order('appointment_time', { ascending: true })

    // Admin tüm randevuları görebilir

    // Tüm verileri paralel olarak çek
    const [
      { data: appointmentsData, error: appointmentsError },
      { data: employeesData, error: employeesError },
      { data: servicesData, error: servicesError }
    ] = await Promise.all([
      appointmentsQuery,
      supabase.from('employees').select('*'),
      supabase.from('services').select('*')
    ])

    if (appointmentsError) throw appointmentsError
    if (employeesError) throw employeesError
    if (servicesError) throw servicesError

    appointments.value = appointmentsData || []
    employees.value = employeesData || []
    services.value = servicesData || []
  } catch (err) {
    error.value = err.message
    console.error('Veri yükleme hatası:', err)
  } finally {
    loading.value = false
  }
}

// Filtrelenmiş randevular
const filteredAppointments = computed(() => {
  let filtered = appointments.value

  // Tarihe göre filtrele
  if (selectedDate.value) {
    filtered = filtered.filter(
      apt => apt.appointment_date === selectedDate.value
    )
  }

  return filtered
})

// Yardımcı fonksiyonlar
const getEmployeeName = (employeeId) => {
  const employee = employees.value.find(e => e.id === employeeId)
  return employee ? employee.name : 'Bilinmiyor'
}

const getServiceName = (serviceId) => {
  const service = services.value.find(s => s.id === serviceId)
  return service ? service.name : 'Bilinmiyor'
}

const getStatusColor = (status) => {
  const colors = {
    pending: 'bg-yellow-100 text-yellow-800',
    confirmed: 'bg-green-100 text-green-800',
    completed: 'bg-blue-100 text-blue-800',
    cancelled: 'bg-red-100 text-red-800'
  }
  return colors[status] || 'bg-gray-100 text-gray-800'
}

const getStatusText = (status) => {
  const texts = {
    pending: 'Beklemede',
    confirmed: 'Onaylandı',
    completed: 'Tamamlandı',
    cancelled: 'İptal Edildi'
  }
  return texts[status] || status
}

const formatTime = (time) => {
  return time.substring(0, 5) // HH:MM formatında
}

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('tr-TR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const cancelAppointment = async (appointmentId) => {
  if (!confirm('Bu randevuyu iptal etmek istediğinizden emin misiniz?')) {
    return
  }

  try {
    const { error } = await supabase
      .from('appointments')
      .update({ status: 'cancelled' })
      .eq('id', appointmentId)

    if (error) throw error

    await fetchData()
    alert('Randevu başarıyla iptal edildi!')
  } catch (err) {
    alert('Randevu iptal edilirken bir hata oluştu: ' + err.message)
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Tab Menüsü -->
    <div class="bg-white rounded-lg shadow-md overflow-hidden">
      <div class="border-b border-gray-200">
        <nav class="flex -mb-px">
          <button
            @click="activeTab = 'appointments'"
            :class="[
              'flex-1 py-4 px-6 text-center font-medium text-sm transition-colors',
              activeTab === 'appointments'
                ? 'border-b-2 border-indigo-600 text-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
            ]"
          >
            <div class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span>Randevular</span>
            </div>
          </button>

          <button
            @click="activeTab = 'services'"
            :class="[
              'flex-1 py-4 px-6 text-center font-medium text-sm transition-colors',
              activeTab === 'services'
                ? 'border-b-2 border-indigo-600 text-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
            ]"
          >
            <div class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <span>Hizmetler</span>
            </div>
          </button>
          <button
            @click="activeTab = 'employees'"
            :class="[
              'flex-1 py-4 px-6 text-center font-medium text-sm transition-colors',
              activeTab === 'employees'
                ? 'border-b-2 border-indigo-600 text-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
            ]"
          >
            <div class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <span>Çalışanlar</span>
            </div>
          </button>
        </nav>
      </div>
    </div>

    <!-- Randevular Sekmesi -->
    <div v-if="activeTab === 'appointments'" class="space-y-6">
      <!-- Başlık ve Filtreler -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900">Randevu Yönetimi</h2>
          <p class="text-gray-600 mt-1">Tüm randevuları görüntüleyin ve yönetin</p>
        </div>

        <!-- Filtreler -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Tarih Seç
          </label>
          <input
            v-model="selectedDate"
            type="date"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>
      </div>

      <!-- Yükleniyor -->
      <div v-if="loading" class="bg-white rounded-lg shadow-md p-12 text-center">
        <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
        <p class="mt-4 text-gray-600">Randevular yükleniyor...</p>
      </div>

      <!-- Hata -->
      <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <p class="text-red-800">Hata: {{ error }}</p>
        <button
          @click="fetchData"
          class="mt-4 bg-red-600 text-white px-6 py-2 rounded-lg hover:bg-red-700 transition-colors"
        >
          Tekrar Dene
        </button>
      </div>

      <!-- Randevu Listesi -->
      <div v-else-if="filteredAppointments.length === 0" class="bg-white rounded-lg shadow-md p-12 text-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <p class="mt-4 text-xl text-gray-600">Seçilen kriterlere uygun randevu bulunamadı</p>
        <p class="mt-2 text-gray-500">Farklı bir tarih veya berber seçerek tekrar deneyin</p>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="appointment in filteredAppointments"
          :key="appointment.id"
          class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <div class="flex items-center space-x-3 mb-3">
                <span :class="['px-3 py-1 rounded-full text-xs font-semibold', getStatusColor(appointment.status)]">
                  {{ getStatusText(appointment.status) }}
                </span>
                <span class="text-gray-600 text-sm">
                  {{ formatDate(appointment.appointment_date) }}
                </span>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                  <p class="text-gray-600">Saat</p>
                  <p class="font-semibold text-lg text-gray-900">{{ formatTime(appointment.appointment_time) }}</p>
                </div>
                <div>
                  <p class="text-gray-600">Berber</p>
                  <p class="font-semibold text-gray-900">{{ getEmployeeName(appointment.employee_id) }}</p>
                </div>
                <div>
                  <p class="text-gray-600">Hizmet</p>
                  <p class="font-semibold text-gray-900">{{ getServiceName(appointment.service_id) }}</p>
                </div>
                <div>
                  <p class="text-gray-600">Müşteri Adı</p>
                  <p class="font-semibold text-gray-900">{{ appointment.customer_name }}</p>
                </div>
                <div>
                  <p class="text-gray-600">Telefon</p>
                  <p class="font-semibold text-gray-900">{{ appointment.customer_phone }}</p>
                </div>
              </div>

              <p v-if="appointment.notes" class="mt-4 text-sm text-gray-600 bg-gray-50 p-3 rounded">
                <span class="font-semibold">Not:</span> {{ appointment.notes }}
              </p>
            </div>

            <div v-if="appointment.status !== 'cancelled' && appointment.status !== 'completed'" class="ml-4">
              <button
                @click="cancelAppointment(appointment.id)"
                class="text-red-600 hover:text-red-800 hover:bg-red-50 px-4 py-2 rounded-lg transition-colors"
              >
                İptal Et
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Hizmetler Sekmesi -->
    <div v-if="activeTab === 'services'" class="bg-white rounded-lg shadow-md p-6">
      <ServicesManagement />
    </div>

    <!-- Çalışanlar Sekmesi -->
    <div v-if="activeTab === 'employees'" class="bg-white rounded-lg shadow-md p-6">
      <EmployeesManagement />
    </div>
  </div>
</template>
