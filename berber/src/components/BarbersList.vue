<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase'

const barbers = ref([])
const loading = ref(true)
const error = ref(null)
const selectedBarber = ref(null)
const barberAppointments = ref([])
const appointmentsLoading = ref(false)
const servicesMap = ref({})

onMounted(async () => {
  await fetchBarbers()
  await fetchAllServices()
})

// Tüm hizmetleri yükle (randevularda göstermek için)
const fetchAllServices = async () => {
  try {
    const { data, error: servicesError } = await supabase
      .from('services')
      .select('*')

    if (servicesError) throw servicesError

    // Hizmetleri ID'ye göre map'e çevir
    servicesMap.value = (data || []).reduce((acc, service) => {
      acc[service.id] = service
      return acc
    }, {})
  } catch (err) {
    console.error('Hizmetler yüklenirken hata:', err)
  }
}

const fetchBarbers = async () => {
  try {
    loading.value = true
    error.value = null

    // Berberleri ve hizmetlerini çek
    const { data: employeesData, error: employeesError } = await supabase
      .from('employees')
      .select('*')
      .eq('is_active', true)

    if (employeesError) throw employeesError

    // Her berber için hizmetlerini çek
    const barbersWithServices = await Promise.all(
      (employeesData || []).map(async (employee) => {
        const { data: servicesData } = await supabase
          .from('employee_services')
          .select(`
            service_id,
            services (
              id,
              name,
              price,
              duration,
              description
            )
          `)
          .eq('employee_id', employee.id)

        return {
          ...employee,
          services: servicesData?.map(s => s.services) || []
        }
      })
    )

    barbers.value = barbersWithServices
  } catch (err) {
    error.value = err.message
    console.error('Berberler yüklenirken hata:', err)
  } finally {
    loading.value = false
  }
}

// Berbere tıklandığında randevularını yükle
const viewBarber = async (barber) => {
  selectedBarber.value = barber
  await fetchBarberAppointments(barber.id)
}

// Seçilen berberin randevularını getir
const fetchBarberAppointments = async (barberId) => {
  try {
    appointmentsLoading.value = true

    const { data, error: appointmentsError } = await supabase
      .from('appointments')
      .select('*')
      .eq('employee_id', barberId)
      .order('appointment_date', { ascending: true })
      .order('appointment_time', { ascending: true })

    if (appointmentsError) throw appointmentsError

    barberAppointments.value = data || []
  } catch (err) {
    console.error('Randevular yüklenirken hata:', err)
    barberAppointments.value = []
  } finally {
    appointmentsLoading.value = false
  }
}

const closeDetails = () => {
  selectedBarber.value = null
  barberAppointments.value = []
}

const formatTime = (time) => {
  if (!time) return ''
  return time.substring(0, 5) // HH:MM formatında
}

const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleDateString('tr-TR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const getStatusColor = (status) => {
  const colors = {
    pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
    confirmed: 'bg-green-100 text-green-800 border-green-200',
    completed: 'bg-blue-100 text-blue-800 border-blue-200',
    cancelled: 'bg-red-100 text-red-800 border-red-200'
  }
  return colors[status] || 'bg-gray-100 text-gray-800 border-gray-200'
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

// Gelecek randevular
const upcomingAppointments = computed(() => {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  return barberAppointments.value.filter(apt => {
    const aptDate = new Date(apt.appointment_date)
    return aptDate >= today && apt.status !== 'cancelled' && apt.status !== 'completed'
  })
})

// Geçmiş randevular
const pastAppointments = computed(() => {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  return barberAppointments.value.filter(apt => {
    const aptDate = new Date(apt.appointment_date)
    return aptDate < today || apt.status === 'completed' || apt.status === 'cancelled'
  })
})
</script>

<template>
  <div class="space-y-6">
    <!-- Başlık -->
    <div class="bg-gradient-to-r from-indigo-600 to-purple-600 rounded-xl shadow-lg p-6 text-white">
      <h2 class="text-3xl font-bold mb-2">Berberlerimiz</h2>
      <p class="text-indigo-100">Uzman ekibimizle tanışın</p>
    </div>

    <!-- Yükleniyor -->
    <div v-if="loading" class="bg-white rounded-lg shadow-md p-12 text-center">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Berberler yükleniyor...</p>
    </div>

    <!-- Hata -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
      <p class="text-red-800">Hata: {{ error }}</p>
    </div>

    <!-- Berber Kartları -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="barber in barbers"
        :key="barber.id"
        class="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden cursor-pointer group"
        @click="viewBarber(barber)"
      >
        <!-- Berber Avatar/Başlık -->
        <div class="bg-gradient-to-br from-indigo-500 to-purple-600 p-6 text-white">
          <div class="flex items-center space-x-4">
            <div class="bg-white/20 backdrop-blur-sm rounded-full p-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>
            <div>
              <h3 class="text-xl font-bold">{{ barber.name }}</h3>
              <p class="text-indigo-100 text-sm">{{ barber.specialty }}</p>
            </div>
          </div>
        </div>

        <!-- Berber Bilgileri -->
        <div class="p-6">
          <!-- Çalışma Saatleri -->
          <div v-if="barber.work_start_time && barber.work_end_time" class="mb-4 flex items-center text-sm text-gray-600">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>{{ formatTime(barber.work_start_time) }} - {{ formatTime(barber.work_end_time) }}</span>
          </div>

          <!-- İletişim -->
          <div class="space-y-2 mb-4">
            <div v-if="barber.phone" class="flex items-center text-sm text-gray-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
              </svg>
              <span>{{ barber.phone }}</span>
            </div>
            <div v-if="barber.email" class="flex items-center text-sm text-gray-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              <span>{{ barber.email }}</span>
            </div>
          </div>

          <!-- Hizmetler Özeti -->
          <div v-if="barber.services && barber.services.length > 0" class="border-t pt-4">
            <p class="text-sm font-semibold text-gray-700 mb-2">Hizmetler:</p>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="service in barber.services.slice(0, 3)"
                :key="service.id"
                class="px-2 py-1 bg-indigo-50 text-indigo-700 text-xs rounded-full"
              >
                {{ service.name }}
              </span>
              <span
                v-if="barber.services.length > 3"
                class="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded-full"
              >
                +{{ barber.services.length - 3 }} daha
              </span>
            </div>
          </div>

          <!-- Detayları Gör Butonu -->
          <button
            class="mt-4 w-full bg-indigo-600 text-white py-2 rounded-lg hover:bg-indigo-700 transition-colors font-medium group-hover:bg-indigo-700"
          >
            Detayları Gör
          </button>
        </div>
      </div>
    </div>

    <!-- Berber Detay Modal -->
    <div
      v-if="selectedBarber"
      class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-50"
      @click.self="closeDetails"
    >
      <div class="bg-white rounded-2xl shadow-2xl max-w-6xl w-full max-h-[90vh] overflow-y-auto">
        <!-- Modal Header -->
        <div class="bg-gradient-to-br from-indigo-500 to-purple-600 p-6 text-white sticky top-0 z-10">
          <button
            @click="closeDetails"
            class="absolute top-4 right-4 bg-white/20 hover:bg-white/30 rounded-full p-2 transition-colors"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>

          <div class="flex items-center space-x-4">
            <div class="bg-white/20 backdrop-blur-sm rounded-full p-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>
            <div>
              <h3 class="text-2xl font-bold">{{ selectedBarber.name }}</h3>
              <p class="text-indigo-100">{{ selectedBarber.specialty }}</p>
            </div>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="p-6">
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Sol Kolon: Berber Bilgileri -->
            <div class="space-y-6">
              <!-- Tanıtım -->
              <div v-if="selectedBarber.bio" class="bg-gray-50 p-4 rounded-lg">
                <h4 class="font-semibold text-gray-900 mb-2 flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Hakkında
                </h4>
                <p class="text-gray-600 text-sm leading-relaxed">{{ selectedBarber.bio }}</p>
              </div>

              <!-- İletişim Bilgileri -->
              <div class="bg-gray-50 p-4 rounded-lg">
                <h4 class="font-semibold text-gray-900 mb-3">İletişim Bilgileri</h4>
                <div class="space-y-2">
                  <div v-if="selectedBarber.phone" class="flex items-center text-gray-600">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-3 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                    <span>{{ selectedBarber.phone }}</span>
                  </div>
                  <div v-if="selectedBarber.email" class="flex items-center text-gray-600">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-3 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    <span>{{ selectedBarber.email }}</span>
                  </div>
                  <div v-if="selectedBarber.work_start_time && selectedBarber.work_end_time" class="flex items-center text-gray-600">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-3 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span>{{ formatTime(selectedBarber.work_start_time) }} - {{ formatTime(selectedBarber.work_end_time) }}</span>
                  </div>
                </div>
              </div>

              <!-- Hizmetler -->
              <div v-if="selectedBarber.services && selectedBarber.services.length > 0">
                <h4 class="font-semibold text-gray-900 mb-3">Yaptığı Hizmetler</h4>
                <div class="grid grid-cols-1 gap-3">
                  <div
                    v-for="service in selectedBarber.services"
                    :key="service.id"
                    class="border border-gray-200 rounded-lg p-4 hover:border-indigo-300 hover:bg-indigo-50 transition-all"
                  >
                    <div class="flex justify-between items-start mb-2">
                      <h5 class="font-semibold text-gray-900">{{ service.name }}</h5>
                      <span class="text-indigo-600 font-bold">{{ service.price }}₺</span>
                    </div>
                    <p class="text-xs text-gray-500">{{ service.duration }} dakika</p>
                    <p v-if="service.description" class="text-sm text-gray-600 mt-2">{{ service.description }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Sağ Kolon: Randevular -->
            <div class="space-y-6">
              <h4 class="font-semibold text-gray-900 text-lg flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Randevular
              </h4>

              <!-- Yükleniyor -->
              <div v-if="appointmentsLoading" class="text-center py-8">
                <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
                <p class="mt-2 text-gray-600 text-sm">Randevular yükleniyor...</p>
              </div>

              <!-- Gelecek Randevular -->
              <div v-else-if="upcomingAppointments.length > 0">
                <h5 class="text-sm font-semibold text-green-700 mb-3">Gelecek Randevular ({{ upcomingAppointments.length }})</h5>
                <div class="space-y-3 max-h-64 overflow-y-auto">
                  <div
                    v-for="apt in upcomingAppointments"
                    :key="apt.id"
                    class="border rounded-lg p-4 hover:shadow-md transition-all"
                    :class="'border-' + getStatusColor(apt.status).split(' ')[0].replace('bg-', '')"
                  >
                    <div class="flex justify-between items-start mb-2">
                      <div class="flex-1">
                        <p class="font-semibold text-gray-900">{{ apt.customer_name }}</p>
                        <p class="text-sm text-gray-600">{{ apt.customer_phone }}</p>
                      </div>
                      <span :class="['px-2 py-1 rounded-full text-xs font-semibold border', getStatusColor(apt.status)]">
                        {{ getStatusText(apt.status) }}
                      </span>
                    </div>
                    <div class="text-sm text-gray-600 space-y-1">
                      <p class="flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        {{ formatDate(apt.appointment_date) }}
                      </p>
                      <p class="flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        {{ formatTime(apt.appointment_time) }}
                      </p>
                      <p class="flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                        </svg>
                        {{ servicesMap[apt.service_id]?.name || 'Hizmet' }}
                      </p>
                    </div>
                    <p v-if="apt.notes" class="mt-2 text-xs text-gray-500 bg-gray-50 p-2 rounded">
                      <span class="font-semibold">Not:</span> {{ apt.notes }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Geçmiş Randevular -->
              <div v-if="pastAppointments.length > 0" class="mt-6">
                <h5 class="text-sm font-semibold text-gray-700 mb-3">Geçmiş Randevular ({{ pastAppointments.length }})</h5>
                <div class="space-y-3 max-h-48 overflow-y-auto">
                  <div
                    v-for="apt in pastAppointments.slice(0, 5)"
                    :key="apt.id"
                    class="border border-gray-200 rounded-lg p-3 bg-gray-50 text-sm"
                  >
                    <div class="flex justify-between items-start mb-1">
                      <p class="font-semibold text-gray-700">{{ apt.customer_name }}</p>
                      <span :class="['px-2 py-1 rounded-full text-xs font-semibold border', getStatusColor(apt.status)]">
                        {{ getStatusText(apt.status) }}
                      </span>
                    </div>
                    <p class="text-xs text-gray-600">
                      {{ formatDate(apt.appointment_date) }} - {{ formatTime(apt.appointment_time) }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Randevu Yoksa -->
              <div v-if="!appointmentsLoading && upcomingAppointments.length === 0 && pastAppointments.length === 0" class="text-center py-8 bg-gray-50 rounded-lg">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-gray-400 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <p class="text-gray-600">Henüz randevu bulunmuyor</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
