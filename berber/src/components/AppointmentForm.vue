<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabase'
import { useAlert } from '../composables/useAlert'

const { showWarning, showSuccess, showError } = useAlert()

// Adım takibi
const currentStep = ref(1)
const totalSteps = 4

// Veri
const employees = ref([])
const services = ref([])
const employeeServices = ref([])
const workingDays = ref([])
const timeOffs = ref([])

// Seçimler
const selectedEmployeeId = ref(null)
const selectedServices = ref([]) // Birden fazla hizmet için array
const selectedDate = ref('')
const selectedTime = ref('')

// Form verileri
const customerName = ref('')
const customerPhone = ref('')
const customerNotes = ref('')

// Durum
const loading = ref(false)
const error = ref(null)
const availableTimes = ref([])

onMounted(async () => {
  await fetchEmployees()
  await fetchServices()
})

// Seçili çalışan bilgisi
const selectedEmployeeData = computed(() => {
  return employees.value.find(e => e.id === selectedEmployeeId.value)
})

// Toplam süre (dakika)
const totalDuration = computed(() => {
  return selectedServices.value.reduce((total, service) => total + (service.duration || 0), 0)
})

// Toplam fiyat
const totalPrice = computed(() => {
  return selectedServices.value.reduce((total, service) => total + (service.price || 0), 0)
})

// Minimum tarih (bugün)
const minDate = computed(() => {
  return new Date().toISOString().split('T')[0]
})

// Maksimum tarih (60 gün sonra)
const maxDate = computed(() => {
  const date = new Date()
  date.setDate(date.getDate() + 60)
  return date.toISOString().split('T')[0]
})

// Çalışanları yükle
const fetchEmployees = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('employees')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true })

    if (fetchError) throw fetchError
    employees.value = data || []
  } catch (err) {
    console.error('Çalışanlar yüklenirken hata:', err)
  }
}

// Hizmetleri yükle
const fetchServices = async () => {
  try {
    const { data, error: fetchError } = await supabase
      .from('services')
      .select('*')
      .order('name', { ascending: true })

    if (fetchError) throw fetchError
    services.value = data || []
  } catch (err) {
    console.error('Hizmetler yüklenirken hata:', err)
  }
}

// Çalışanın hizmetlerini yükle
const fetchEmployeeServices = async (employeeId) => {
  try {
    const { data, error: fetchError } = await supabase
      .from('employee_services')
      .select(`
        service_id,
        services (id, name, price, duration, description)
      `)
      .eq('employee_id', employeeId)

    if (fetchError) throw fetchError
    employeeServices.value = data?.map(s => s.services) || []
  } catch (err) {
    console.error('Çalışan hizmetleri yüklenirken hata:', err)
  }
}

// Çalışanın çalışma günlerini yükle
const fetchWorkingDays = async (employeeId) => {
  try {
    const { data, error: fetchError } = await supabase
      .from('employee_working_days')
      .select('*')
      .eq('employee_id', employeeId)
      .eq('is_active', true)

    if (fetchError) throw fetchError
    workingDays.value = data || []
  } catch (err) {
    console.error('Çalışma günleri yüklenirken hata:', err)
    // Eğer tablo yoksa, varsayılan değerler kullan
    workingDays.value = []
  }
}

// Çalışanın tatil günlerini yükle
const fetchTimeOffs = async (employeeId) => {
  try {
    const { data, error: fetchError } = await supabase
      .from('employee_time_off')
      .select('*')
      .eq('employee_id', employeeId)

    if (fetchError) throw fetchError
    timeOffs.value = data || []
  } catch (err) {
    console.error('Tatil günleri yüklenirken hata:', err)
    timeOffs.value = []
  }
}

// Çalışan seçildiğinde
const selectEmployee = async (employeeId) => {
  selectedEmployeeId.value = employeeId
  await fetchEmployeeServices(employeeId)
  nextStep()
}

// Hizmet seçimi/seçimi kaldırma (toggle) - Birden fazla hizmet için
const toggleService = (service) => {
  const index = selectedServices.value.findIndex(s => s.id === service.id)
  if (index > -1) {
    // Hizmet zaten seçili, kaldır
    selectedServices.value.splice(index, 1)
  } else {
    // Hizmeti ekle
    selectedServices.value.push(service)
  }
}

// Hizmet seçimini tamamla ve sonraki adıma geç
const confirmServices = async () => {
  if (selectedServices.value.length === 0) {
    await showWarning('Devam etmek için en az bir hizmet seçmeniz gerekmektedir.', 'Hizmet Seçimi')
    return
  }
  await fetchWorkingDays(selectedEmployeeId.value)
  await fetchTimeOffs(selectedEmployeeId.value)
  nextStep()
}

// Hizmet seçili mi kontrol et
const isServiceSelected = (serviceId) => {
  return selectedServices.value.some(s => s.id === serviceId)
}

// Tarih seçildiğinde
const onDateSelect = async () => {
  if (!selectedDate.value) return
  await calculateAvailableTimes()
}

// Müsait saatleri hesapla
const calculateAvailableTimes = async () => {
  if (!selectedDate.value || !selectedEmployeeId.value || selectedServices.value.length === 0) return

  try {
    loading.value = true

    // Seçilen tarihin gün indexini al
    const date = new Date(selectedDate.value + 'T00:00:00')
    const dayOfWeek = date.getDay()

    // Bu günde çalışıyor mu?
    const workingDay = workingDays.value.find(wd => wd.day_of_week === dayOfWeek)

    // Eğer çalışma günü bulunamadıysa, varsayılan saatler kullan
    let startTime = '09:00'
    let endTime = '19:00'

    if (workingDay) {
      startTime = workingDay.start_time
      endTime = workingDay.end_time
    } else if (dayOfWeek === 0) {
      // Pazar günü çalışmıyor
      availableTimes.value = []
      loading.value = false
      return
    }

    // Tatilde mi?
    const isTimeOff = timeOffs.value.some(to => to.date === selectedDate.value && to.is_full_day)
    if (isTimeOff) {
      availableTimes.value = []
      loading.value = false
      return
    }

    // Mevcut randevuları çek
    const { data: existingAppointments, error: aptError } = await supabase
      .from('appointments')
      .select('appointment_time, service_id, services(duration)')
      .eq('employee_id', selectedEmployeeId.value)
      .eq('appointment_date', selectedDate.value)
      .in('status', ['pending', 'confirmed'])

    if (aptError) throw aptError

    // Çalışma saatlerini parse et
    const [startHour, startMinute] = startTime.split(':').map(Number)
    const [endHour, endMinute] = endTime.split(':').map(Number)

    // Tüm olası saatleri oluştur (30 dakika aralıklar)
    const times = []
    let currentHour = startHour
    let currentMinute = startMinute

    while (currentHour < endHour || (currentHour === endHour && currentMinute < endMinute)) {
      const timeStr = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`

      // Bu saat müsait mi kontrol et - toplam süreyi kullan
      const isAvailable = !existingAppointments?.some(apt => {
        const aptTime = apt.appointment_time.substring(0, 5)
        const aptDuration = apt.services?.duration || 30

        const [aptHour, aptMinute] = aptTime.split(':').map(Number)
        const aptStart = aptHour * 60 + aptMinute
        const aptEnd = aptStart + aptDuration

        const checkTime = currentHour * 60 + currentMinute
        const checkEnd = checkTime + totalDuration.value

        return (checkTime < aptEnd && checkEnd > aptStart)
      })

      if (isAvailable) {
        times.push(timeStr)
      }

      // 30 dakika ekle
      currentMinute += 30
      if (currentMinute >= 60) {
        currentHour++
        currentMinute = 0
      }
    }

    availableTimes.value = times
  } catch (err) {
    console.error('Müsait saatler hesaplanırken hata:', err)
    error.value = err.message
  } finally {
    loading.value = false
  }
}

// Saat seçildiğinde
const selectTime = (time) => {
  selectedTime.value = time
  nextStep()
}

// Sonraki adım
const nextStep = () => {
  if (currentStep.value < totalSteps) {
    currentStep.value++
  }
}

// Önceki adım
const prevStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

// Formu sıfırla
const resetForm = () => {
  currentStep.value = 1
  selectedEmployeeId.value = null
  selectedServices.value = []
  selectedDate.value = ''
  selectedTime.value = ''
  customerName.value = ''
  customerPhone.value = ''
  customerNotes.value = ''
  error.value = null
}

// Randevuyu kaydet - Birden fazla hizmet için ard arda saatlerde randevular oluştur
const submitAppointment = async () => {
  if (!customerName.value || !customerPhone.value) {
    await showWarning('Randevu oluşturmak için lütfen adınızı ve telefon numaranızı girin.', 'Eksik Bilgi')
    return
  }

  try {
    loading.value = true
    error.value = null

    // Her hizmet için ard arda saatlerde randevu oluştur
    const appointments = []
    let currentTime = selectedTime.value

    for (const service of selectedServices.value) {
      // Saat ve dakikayı parse et
      const [hours, minutes] = currentTime.split(':').map(Number)

      appointments.push({
        employee_id: selectedEmployeeId.value,
        service_id: service.id,
        appointment_date: selectedDate.value,
        appointment_time: `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:00`,
        customer_name: customerName.value,
        customer_phone: customerPhone.value,
        notes: customerNotes.value,
        status: 'pending'
      })

      // Bir sonraki hizmet için saati hesapla (hizmet süresi kadar ilerlet)
      const totalMinutes = hours * 60 + minutes + service.duration
      const nextHours = Math.floor(totalMinutes / 60)
      const nextMinutes = totalMinutes % 60
      currentTime = `${nextHours.toString().padStart(2, '0')}:${nextMinutes.toString().padStart(2, '0')}`
    }

    const { error: insertError } = await supabase
      .from('appointments')
      .insert(appointments)

    if (insertError) throw insertError

    await showSuccess(
      `${selectedServices.value.length} hizmet için randevunuz başarıyla oluşturuldu!\n\nRandevunuz en kısa sürede onaylanacak ve size bilgi verilecektir.`,
      '✅ Randevu Oluşturuldu'
    )
    resetForm()
  } catch (err) {
    console.error('Randevu kaydedilirken hata:', err)
    await showError(
      `Randevu oluşturulurken bir hata meydana geldi.\n\nHata: ${err.message}\n\nLütfen tekrar deneyin veya bizimle iletişime geçin.`,
      'Randevu Hatası'
    )
  } finally {
    loading.value = false
  }
}

// Tarih formatla
const formatDate = (dateStr) => {
  const date = new Date(dateStr + 'T00:00:00')
  return date.toLocaleDateString('tr-TR', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}
</script>

<template>
  <div id="appointment-form" class="bg-white rounded-xl shadow-lg p-6 md:p-8">
    <!-- İlerleme Çubuğu -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <div
          v-for="step in totalSteps"
          :key="step"
          class="flex items-center"
          :class="{ 'flex-1': step < totalSteps }"
        >
          <div
            class="flex items-center justify-center w-10 h-10 rounded-full font-bold transition-all"
            :class="
              currentStep >= step
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-200 text-gray-600'
            "
          >
            {{ step }}
          </div>
          <div
            v-if="step < totalSteps"
            class="flex-1 h-1 mx-2 transition-all"
            :class="currentStep > step ? 'bg-indigo-600' : 'bg-gray-200'"
          ></div>
        </div>
      </div>
      <div class="text-center">
        <h2 class="text-2xl font-bold text-gray-900">
          <span v-if="currentStep === 1">Çalışan Seçimi</span>
          <span v-else-if="currentStep === 2">Hizmet Seçimi</span>
          <span v-else-if="currentStep === 3">Tarih ve Saat Seçimi</span>
          <span v-else-if="currentStep === 4">İletişim Bilgileri</span>
        </h2>
        <p class="text-gray-600 mt-1">Adım {{ currentStep }} / {{ totalSteps }}</p>
      </div>
    </div>

    <!-- Adım 1: Çalışan Seçimi -->
    <div v-if="currentStep === 1" class="space-y-6">
      <!-- Başlık -->
      <div class="text-center">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">Çalışanlarımız</h2>
        <p class="text-gray-600">Randevu almak istediğiniz çalışanı seçin</p>
      </div>

      <!-- Çalışanlar Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="employee in employees"
          :key="employee.id"
          @click="selectEmployee(employee.id)"
          class="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 cursor-pointer transform hover:-translate-y-1 overflow-hidden border-2 border-transparent hover:border-indigo-500"
        >
          <!-- Fotoğraf Alanı -->
          <div class="h-48 bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center relative overflow-hidden">
            <!-- Gerçek fotoğraf varsa göster -->
            <img
              v-if="employee.photo_url"
              :src="employee.photo_url"
              :alt="employee.name"
              class="w-full h-full object-cover"
              @error="(e) => e.target.style.display = 'none'"
            />
            <!-- Fotoğraf yoksa veya yüklenemezse placeholder -->
            <div
              v-if="!employee.photo_url"
              class="w-32 h-32 rounded-full bg-white flex items-center justify-center shadow-lg z-10"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>
          </div>

          <!-- Bilgiler -->
          <div class="p-6 text-center">
            <h3 class="text-xl font-bold text-gray-900 mb-2">{{ employee.name }}</h3>
            <p class="text-indigo-600 font-medium mb-3">{{ employee.specialty || 'Uzman' }}</p>

            <!-- Çalışma Saatleri -->
            <div v-if="employee.work_start_time && employee.work_end_time" class="text-sm text-gray-600">
              <p class="flex items-center justify-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {{ employee.work_start_time.substring(0, 5) }} - {{ employee.work_end_time.substring(0, 5) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Boş Durum -->
      <div v-if="employees.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <p class="mt-4 text-lg text-gray-600">Şu anda aktif çalışan bulunmamaktadır</p>
      </div>
    </div>

    <!-- Adım 2: Hizmet Seçimi (Birden fazla seçilebilir) -->
    <div v-if="currentStep === 2" class="space-y-4">
      <p class="text-gray-600 text-center mb-2">
        <span class="font-semibold">{{ selectedEmployeeData?.name }}</span> için hizmet seçin
      </p>
      <p class="text-sm text-indigo-600 text-center mb-6">
        Birden fazla hizmet seçebilirsiniz
      </p>

      <!-- Seçili hizmetler özeti -->
      <div v-if="selectedServices.length > 0" class="bg-indigo-50 p-4 rounded-lg mb-4">
        <p class="text-sm font-semibold text-gray-900 mb-2">Seçili Hizmetler:</p>
        <div class="flex flex-wrap gap-2 mb-2">
          <span
            v-for="service in selectedServices"
            :key="service.id"
            class="px-3 py-1 bg-indigo-600 text-white rounded-full text-sm font-medium"
          >
            {{ service.name }}
          </span>
        </div>
        <div class="flex justify-between text-sm mt-3 pt-3 border-t border-indigo-200">
          <span class="text-gray-700">Toplam Süre: <strong>{{ totalDuration }} dakika</strong></span>
          <span class="text-indigo-700 font-bold">Toplam: {{ totalPrice }} TL</span>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="service in employeeServices"
          :key="service.id"
          @click="toggleService(service)"
          class="p-4 border-2 rounded-lg cursor-pointer transition-all text-left"
          :class="isServiceSelected(service.id)
            ? 'border-indigo-600 bg-indigo-50'
            : 'border-gray-200 hover:border-indigo-300 hover:bg-gray-50'"
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <h3 class="font-bold text-lg text-gray-900">{{ service.name }}</h3>
              <div class="flex items-center justify-between mt-2 text-sm">
                <span class="text-gray-600">{{ service.duration }} dakika</span>
                <span class="text-indigo-600 font-semibold">{{ service.price }} TL</span>
              </div>
              <p v-if="service.description" class="text-gray-500 text-sm mt-2">{{ service.description }}</p>
            </div>
            <div class="ml-3">
              <div
                class="w-6 h-6 rounded border-2 flex items-center justify-center transition-all"
                :class="isServiceSelected(service.id)
                  ? 'bg-indigo-600 border-indigo-600'
                  : 'border-gray-300'"
              >
                <svg
                  v-if="isServiceSelected(service.id)"
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-between mt-6">
        <button
          @click="prevStep"
          class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
        >
          Geri
        </button>
        <button
          @click="confirmServices"
          :disabled="selectedServices.length === 0"
          class="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Devam Et ({{ selectedServices.length }} hizmet)
        </button>
      </div>
    </div>

    <!-- Adım 3: Tarih ve Saat Seçimi -->
    <div v-if="currentStep === 3" class="space-y-6">
      <div class="bg-indigo-50 p-4 rounded-lg">
        <p class="text-sm text-gray-700 mb-2">
          <span class="font-semibold">Çalışan:</span> {{ selectedEmployeeData?.name }}
        </p>
        <p class="text-sm text-gray-700 mb-2">
          <span class="font-semibold">Hizmetler:</span>
          <span v-for="(service, index) in selectedServices" :key="service.id">
            {{ service.name }}<span v-if="index < selectedServices.length - 1">, </span>
          </span>
        </p>
        <div class="flex justify-between text-sm mt-3 pt-3 border-t border-indigo-200">
          <span class="text-gray-700">Toplam Süre: <strong>{{ totalDuration }} dakika</strong></span>
          <span class="text-indigo-700 font-bold">Toplam: {{ totalPrice }} TL</span>
        </div>
      </div>

      <!-- Tarih Seçimi -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Tarih Seçin</label>
        <input
          v-model="selectedDate"
          @change="onDateSelect"
          type="date"
          :min="minDate"
          :max="maxDate"
          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
        />
        <p v-if="selectedDate" class="text-sm text-gray-600 mt-2">
          {{ formatDate(selectedDate) }}
        </p>
      </div>

      <!-- Saat Seçimi -->
      <div v-if="selectedDate">
        <label class="block text-sm font-medium text-gray-700 mb-2">Saat Seçin</label>
        <div v-if="loading" class="text-center py-8">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
          <p class="text-gray-600 mt-2">Müsait saatler yükleniyor...</p>
        </div>
        <div v-else-if="availableTimes.length === 0" class="text-center py-8 bg-red-50 rounded-lg">
          <p class="text-red-800">Bu tarihte müsait saat bulunmamaktadır.</p>
          <p class="text-red-600 text-sm mt-2">Lütfen başka bir tarih seçin.</p>
        </div>
        <div v-else class="grid grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
          <button
            v-for="time in availableTimes"
            :key="time"
            @click="selectTime(time)"
            class="px-4 py-3 border-2 border-gray-200 rounded-lg hover:border-indigo-500 hover:bg-indigo-50 transition-all font-semibold text-gray-900"
          >
            {{ time }}
          </button>
        </div>
      </div>

      <div class="flex justify-between mt-6">
        <button
          @click="prevStep"
          class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
        >
          Geri
        </button>
      </div>
    </div>

    <!-- Adım 4: İletişim Bilgileri -->
    <div v-if="currentStep === 4" class="space-y-6">
      <!-- Özet -->
      <div class="bg-indigo-50 p-6 rounded-lg space-y-2">
        <h3 class="font-bold text-lg text-gray-900 mb-3">Randevu Özeti</h3>
        <p class="text-sm text-gray-700">
          <span class="font-semibold">Çalışan:</span> {{ selectedEmployeeData?.name }}
        </p>
        <div class="text-sm text-gray-700">
          <span class="font-semibold">Hizmetler:</span>
          <ul class="ml-5 mt-2 space-y-1">
            <li v-for="service in selectedServices" :key="service.id" class="flex justify-between">
              <span>• {{ service.name }}</span>
              <span class="text-indigo-600 font-medium">{{ service.price }} TL</span>
            </li>
          </ul>
        </div>
        <p class="text-sm text-gray-700">
          <span class="font-semibold">Tarih:</span> {{ formatDate(selectedDate) }}
        </p>
        <p class="text-sm text-gray-700">
          <span class="font-semibold">Saat:</span> {{ selectedTime }}
        </p>
        <p class="text-sm text-gray-700">
          <span class="font-semibold">Toplam Süre:</span> {{ totalDuration }} dakika
        </p>
        <p class="text-lg font-bold text-indigo-600 mt-3 pt-3 border-t border-indigo-200">
          Toplam Tutar: {{ totalPrice }} TL
        </p>
      </div>

      <!-- İletişim Formu -->
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Ad Soyad *</label>
          <input
            v-model="customerName"
            type="text"
            placeholder="Adınız ve soyadınız"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Telefon *</label>
          <input
            v-model="customerPhone"
            type="tel"
            placeholder="0555 555 55 55"
            required
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Not (Opsiyonel)</label>
          <textarea
            v-model="customerNotes"
            rows="3"
            placeholder="Randevunuz hakkında eklemek istediğiniz notlar..."
            class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          ></textarea>
        </div>
      </div>

      <!-- Butonlar -->
      <div class="flex justify-between mt-6">
        <button
          @click="prevStep"
          class="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
        >
          Geri
        </button>
        <button
          @click="submitAppointment"
          :disabled="loading"
          class="px-8 py-3 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-lg hover:from-indigo-700 hover:to-purple-700 transition-all shadow-md hover:shadow-lg disabled:opacity-50 font-semibold"
        >
          <span v-if="loading">Kaydediliyor...</span>
          <span v-else>Randevuyu Onayla</span>
        </button>
      </div>
    </div>
  </div>
</template>
