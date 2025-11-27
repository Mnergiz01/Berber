<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '../supabase'

const emit = defineEmits(['appointment-created', 'cancel'])

// Form verileri
const formData = ref({
  employee_id: '',
  service_id: '',
  appointment_date: new Date().toISOString().split('T')[0],
  appointment_time: '',
  customer_name: '',
  customer_phone: '',
  customer_email: '',
  notes: ''
})

// Yardımcı state'ler
const employees = ref([])
const services = ref([])
const availableTimeSlots = ref([])
const loading = ref(false)
const loadingSlots = ref(false)
const error = ref(null)
const existingAppointments = ref([])

onMounted(async () => {
  await fetchInitialData()
})

// Tarih veya çalışan değiştiğinde saat dilimlerini yeniden yükle
watch(
  () => [formData.value.appointment_date, formData.value.employee_id],
  async ([date, employeeId]) => {
    if (date && employeeId) {
      await fetchAvailableTimeSlots()
    }
  }
)

const fetchInitialData = async () => {
  try {
    loading.value = true
    error.value = null

    const [
      { data: employeesData, error: employeesError },
      { data: servicesData, error: servicesError }
    ] = await Promise.all([
      supabase.from('employees').select('*').eq('is_active', true),
      supabase.from('services').select('*')
    ])

    if (employeesError) throw employeesError
    if (servicesError) throw servicesError

    employees.value = employeesData || []
    services.value = servicesData || []
  } catch (err) {
    error.value = err.message
    console.error('Veri yükleme hatası:', err)
  } finally {
    loading.value = false
  }
}

const fetchAvailableTimeSlots = async () => {
  try {
    loadingSlots.value = true

    // Seçilen çalışan ve tarihe ait randevuları al
    const { data, error: appointmentsError } = await supabase
      .from('appointments')
      .select('appointment_time')
      .eq('employee_id', formData.value.employee_id)
      .eq('appointment_date', formData.value.appointment_date)
      .neq('status', 'cancelled')

    if (appointmentsError) throw appointmentsError

    existingAppointments.value = data || []

    // Saat dilimlerini oluştur (09:00 - 19:00 arası, 30'ar dakika)
    const slots = []
    const startHour = 9
    const endHour = 19

    for (let hour = startHour; hour < endHour; hour++) {
      for (let minute of [0, 30]) {
        const timeStr = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}:00`
        const isBooked = existingAppointments.value.some(
          apt => apt.appointment_time === timeStr
        )

        slots.push({
          time: timeStr,
          display: timeStr.substring(0, 5), // HH:MM formatı
          available: !isBooked
        })
      }
    }

    availableTimeSlots.value = slots
  } catch (err) {
    console.error('Saat dilimleri yükleme hatası:', err)
  } finally {
    loadingSlots.value = false
  }
}

const selectedService = computed(() => {
  return services.value.find(s => s.id === formData.value.service_id)
})

const isFormValid = computed(() => {
  return (
    formData.value.employee_id &&
    formData.value.service_id &&
    formData.value.appointment_date &&
    formData.value.appointment_time &&
    formData.value.customer_name.trim() &&
    formData.value.customer_phone.trim()
  )
})

const submitForm = async () => {
  if (!isFormValid.value) {
    alert('Lütfen tüm gerekli alanları doldurun!')
    return
  }

  try {
    loading.value = true
    error.value = null

    // Randevu oluştur (müşteri bilgileri direkt kaydediliyor)
    const { data: appointment, error: appointmentError } = await supabase
      .from('appointments')
      .insert({
        employee_id: formData.value.employee_id,
        service_id: formData.value.service_id,
        appointment_date: formData.value.appointment_date,
        appointment_time: formData.value.appointment_time,
        customer_name: formData.value.customer_name,
        customer_phone: formData.value.customer_phone,
        customer_email: formData.value.customer_email || null,
        notes: formData.value.notes || null,
        status: 'pending'
      })
      .select()
      .single()

    if (appointmentError) {
      // Çakışma hatası kontrolü
      if (appointmentError.code === '23505') {
        throw new Error('Bu saat dilimi dolu! Lütfen başka bir saat seçin.')
      }
      throw appointmentError
    }

    alert('Randevunuz başarıyla oluşturuldu!')
    emit('appointment-created', appointment)
  } catch (err) {
    error.value = err.message
    alert('Randevu oluşturulurken bir hata oluştu: ' + err.message)
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  formData.value = {
    employee_id: '',
    service_id: '',
    appointment_date: new Date().toISOString().split('T')[0],
    appointment_time: '',
    customer_name: '',
    customer_phone: '',
    customer_email: '',
    notes: ''
  }
  availableTimeSlots.value = []
}
</script>

<template>
  <div class="bg-white rounded-xl shadow-2xl p-4 sm:p-6 lg:p-8 border border-indigo-100">
    <!-- Başlık -->
    <div class="mb-6 sm:mb-8 text-center sm:text-left">
      <div class="flex items-center justify-center sm:justify-start gap-3 mb-3">
        <div class="bg-gradient-to-br from-indigo-500 to-purple-600 p-2 sm:p-3 rounded-xl shadow-lg">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 sm:h-7 sm:w-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
        </div>
        <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
          Randevu Al
        </h2>
      </div>
      <p class="text-sm sm:text-base text-gray-600">Lütfen aşağıdaki formu doldurun</p>
    </div>

    <form @submit.prevent="submitForm" class="space-y-5 sm:space-y-6">
      <!-- Çalışan Seçimi -->
      <div class="bg-gradient-to-br from-indigo-50 to-purple-50 p-4 sm:p-5 rounded-xl border border-indigo-100">
        <label class="flex items-center gap-2 text-sm sm:text-base font-semibold text-gray-800 mb-3 sm:mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          Berber Seçin <span class="text-red-500">*</span>
        </label>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2 sm:gap-3">
          <div
            v-for="employee in employees"
            :key="employee.id"
            @click="formData.employee_id = employee.id"
            :class="[
              'p-3 sm:p-4 border-2 rounded-xl cursor-pointer transition-all duration-200 hover:scale-105',
              formData.employee_id === employee.id
                ? 'border-indigo-600 bg-white shadow-lg ring-2 ring-indigo-200'
                : 'border-gray-200 bg-white hover:border-indigo-300 shadow-sm hover:shadow-md'
            ]"
          >
            <div class="flex items-center gap-2 mb-1">
              <div :class="[
                'w-2 h-2 rounded-full',
                formData.employee_id === employee.id ? 'bg-indigo-600' : 'bg-gray-300'
              ]"></div>
              <p class="font-semibold text-sm sm:text-base text-gray-900">{{ employee.name }}</p>
            </div>
            <p class="text-xs sm:text-sm text-gray-600 ml-4">{{ employee.specialty }}</p>
          </div>
        </div>
      </div>

      <!-- Hizmet Seçimi -->
      <div class="bg-gradient-to-br from-purple-50 to-pink-50 p-4 sm:p-5 rounded-xl border border-purple-100">
        <label class="flex items-center gap-2 text-sm sm:text-base font-semibold text-gray-800 mb-3 sm:mb-4">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.121 14.121L19 19m-7-7l7-7m-7 7l-2.879 2.879M12 12L9.121 9.121m0 5.758a3 3 0 10-4.243 4.243 3 3 0 004.243-4.243zm0-5.758a3 3 0 10-4.243-4.243 3 3 0 004.243 4.243z" />
          </svg>
          Hizmet Seçin <span class="text-red-500">*</span>
        </label>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3">
          <div
            v-for="service in services"
            :key="service.id"
            @click="formData.service_id = service.id"
            :class="[
              'p-3 sm:p-4 border-2 rounded-xl cursor-pointer transition-all duration-200 hover:scale-105',
              formData.service_id === service.id
                ? 'border-purple-600 bg-white shadow-lg ring-2 ring-purple-200'
                : 'border-gray-200 bg-white hover:border-purple-300 shadow-sm hover:shadow-md'
            ]"
          >
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <div :class="[
                  'w-2 h-2 rounded-full',
                  formData.service_id === service.id ? 'bg-purple-600' : 'bg-gray-300'
                ]"></div>
                <p class="font-semibold text-sm sm:text-base text-gray-900">{{ service.name }}</p>
              </div>
              <div class="flex items-center gap-1 bg-gradient-to-r from-purple-600 to-pink-600 text-white px-2 sm:px-3 py-1 rounded-full">
                <span class="text-sm sm:text-lg font-bold">{{ service.price }}</span>
                <span class="text-xs">₺</span>
              </div>
            </div>
            <div class="flex items-center gap-2 text-xs sm:text-sm text-gray-600 ml-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {{ service.duration }} dakika
            </div>
            <p v-if="service.description" class="text-xs sm:text-sm text-gray-500 mt-2 ml-4 line-clamp-2">
              {{ service.description }}
            </p>
          </div>
        </div>
      </div>

      <!-- Tarih Seçimi -->
      <div class="bg-gradient-to-br from-blue-50 to-indigo-50 p-4 sm:p-5 rounded-xl border border-blue-100">
        <label class="flex items-center gap-2 text-sm sm:text-base font-semibold text-gray-800 mb-3">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          Tarih Seçin <span class="text-red-500">*</span>
        </label>
        <input
          v-model="formData.appointment_date"
          type="date"
          required
          :min="new Date().toISOString().split('T')[0]"
          class="w-full px-3 sm:px-4 py-2 sm:py-3 text-sm sm:text-base border-2 border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all bg-white shadow-sm"
        />
      </div>

      <!-- Saat Seçimi -->
      <div v-if="formData.appointment_date && formData.employee_id" class="bg-gradient-to-br from-green-50 to-emerald-50 p-4 sm:p-5 rounded-xl border border-green-100">
        <label class="flex items-center gap-2 text-sm sm:text-base font-semibold text-gray-800 mb-3">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Saat Seçin <span class="text-red-500">*</span>
        </label>

        <div v-if="loadingSlots" class="text-center py-8 sm:py-12">
          <div class="inline-block animate-spin rounded-full h-10 w-10 sm:h-12 sm:w-12 border-4 border-green-200 border-t-green-600"></div>
          <p class="mt-3 sm:mt-4 text-sm sm:text-base text-gray-600 font-medium">Müsait saatler yükleniyor...</p>
        </div>

        <div v-else class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-2">
          <button
            v-for="slot in availableTimeSlots"
            :key="slot.time"
            type="button"
            @click="formData.appointment_time = slot.time"
            :disabled="!slot.available"
            :class="[
              'py-2 sm:py-3 px-2 rounded-lg font-semibold transition-all duration-200 text-xs sm:text-sm relative overflow-hidden',
              !slot.available
                ? 'bg-gray-100 text-gray-400 cursor-not-allowed opacity-50'
                : formData.appointment_time === slot.time
                ? 'bg-gradient-to-br from-green-500 to-emerald-600 text-white shadow-lg scale-105 ring-2 ring-green-300'
                : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-green-400 hover:shadow-md hover:scale-105'
            ]"
          >
            <span class="relative z-10">{{ slot.display }}</span>
            <span v-if="!slot.available" class="block text-[10px] sm:text-xs mt-0.5 font-normal">Dolu</span>
            <svg v-if="formData.appointment_time === slot.time" xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 sm:h-4 sm:w-4 absolute top-1 right-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
            </svg>
          </button>
        </div>

        <div class="mt-4 flex flex-wrap items-center gap-3 sm:gap-4 text-xs sm:text-sm">
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 sm:w-4 sm:h-4 bg-gray-100 rounded border border-gray-300"></span>
            <span class="text-gray-600">Dolu</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 sm:w-4 sm:w-4 bg-white rounded border-2 border-gray-200"></span>
            <span class="text-gray-600">Müsait</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 sm:w-4 sm:h-4 bg-gradient-to-br from-green-500 to-emerald-600 rounded"></span>
            <span class="text-gray-600">Seçili</span>
          </div>
        </div>
      </div>

      <!-- Müşteri Bilgileri -->
      <div class="border-t pt-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">İletişim Bilgileri</h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Adınız Soyadınız <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.customer_name"
              type="text"
              required
              placeholder="Örn: Ahmet Yılmaz"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Telefon Numarası <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.customer_phone"
              type="tel"
              required
              placeholder="Örn: 0532 123 4567"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>
        </div>

        <div class="mt-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">
            E-posta (İsteğe bağlı)
          </label>
          <input
            v-model="formData.customer_email"
            type="email"
            placeholder="Örn: ornek@email.com"
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <div class="mt-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Notlar (İsteğe bağlı)
          </label>
          <textarea
            v-model="formData.notes"
            rows="3"
            placeholder="Randevunuzla ilgili özel bir notunuz varsa yazabilirsiniz..."
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          ></textarea>
        </div>
      </div>

      <!-- Özet -->
      <div v-if="isFormValid" class="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
        <h4 class="font-semibold text-gray-900 mb-2">Randevu Özeti</h4>
        <div class="space-y-1 text-sm">
          <p><span class="font-medium">Hizmet:</span> {{ selectedService?.name }} ({{ selectedService?.price }} ₺)</p>
          <p><span class="font-medium">Tarih:</span> {{ new Date(formData.appointment_date).toLocaleDateString('tr-TR') }}</p>
          <p><span class="font-medium">Saat:</span> {{ formData.appointment_time.substring(0, 5) }}</p>
        </div>
      </div>

      <!-- Hata Mesajı -->
      <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg p-4 text-red-800">
        {{ error }}
      </div>

      <!-- Butonlar -->
      <div>
        <button
          type="submit"
          :disabled="!isFormValid || loading"
          :class="[
            'w-full py-3 px-6 rounded-lg font-medium transition-all',
            isFormValid && !loading
              ? 'bg-indigo-600 text-white hover:bg-indigo-700'
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          ]"
        >
          <span v-if="loading">Oluşturuluyor...</span>
          <span v-else>Randevu Oluştur</span>
        </button>
      </div>
    </form>
  </div>
</template>
