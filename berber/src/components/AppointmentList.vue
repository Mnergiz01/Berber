<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase'
import ServicesManagement from './ServicesManagement.vue'
import EmployeesManagement from './EmployeesManagement.vue'
import WorkingHoursManagement from './WorkingHoursManagement.vue'
import { useAlert, useNotification } from '../composables/useAlert'

const { showSuccess, showError, showWarning, showConfirm } = useAlert()
const { showSuccessNotification, showErrorNotification } = useNotification()

const props = defineProps({
  adminUser: {
    type: Object,
    default: null
  },
  employeeUser: {
    type: Object,
    default: null
  },
  isAdmin: {
    type: Boolean,
    default: false
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
const selectedEmployeeFilter = ref('')
const selectedStatusFilter = ref('')

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

    // Çalışan ise sadece kendi randevularını göster
    if (!props.isAdmin && props.employeeUser) {
      appointmentsQuery = appointmentsQuery.eq('employee_id', props.employeeUser.id)
    }
    // Admin tüm randevuları görebilir (filtre yok)

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

  // Çalışana göre filtrele (sadece admin için)
  if (props.isAdmin && selectedEmployeeFilter.value) {
    filtered = filtered.filter(
      apt => apt.employee_id === selectedEmployeeFilter.value
    )
  }

  // Duruma göre filtrele
  if (selectedStatusFilter.value) {
    filtered = filtered.filter(
      apt => apt.status === selectedStatusFilter.value
    )
  }

  return filtered
})

// İstatistikler (Admin için)
const stats = computed(() => {
  if (!props.isAdmin) return null

  const today = new Date().toISOString().split('T')[0]
  const todayAppointments = appointments.value.filter(apt => apt.appointment_date === today)

  return {
    total: appointments.value.length,
    today: todayAppointments.length,
    pending: appointments.value.filter(apt => apt.status === 'pending').length,
    confirmed: appointments.value.filter(apt => apt.status === 'confirmed').length,
    completed: appointments.value.filter(apt => apt.status === 'completed').length,
    cancelled: appointments.value.filter(apt => apt.status === 'cancelled').length
  }
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
  const confirmed = await showConfirm({
    message: 'Bu randevuyu iptal etmek istediğinizden emin misiniz?\n\nİptal edilen randevular "İptal Edildi" durumuna geçecektir.',
    confirmText: 'İptal Et',
    cancelText: 'Vazgeç'
  })

  if (!confirmed) return

  try {
    const { error } = await supabase
      .from('appointments')
      .update({ status: 'cancelled' })
      .eq('id', appointmentId)

    if (error) throw error

    await fetchData()
    showSuccessNotification('Randevu başarıyla iptal edildi.')
  } catch (err) {
    await showError(`Randevu iptal edilirken bir hata oluştu:\n\n${err.message}`)
  }
}

const updateAppointmentStatus = async (appointmentId, newStatus) => {
  try {
    const { error } = await supabase
      .from('appointments')
      .update({ status: newStatus })
      .eq('id', appointmentId)

    if (error) throw error

    await fetchData()
    showSuccessNotification('Randevu durumu başarıyla güncellendi.')
  } catch (err) {
    await showError(`Randevu durumu güncellenirken hata oluştu:\n\n${err.message}`)
  }
}

const deleteAppointment = async (appointmentId) => {
  const confirmed = await showConfirm({
    type: 'warning',
    title: 'Randevuyu Sil',
    message: 'Bu randevuyu kalıcı olarak silmek istediğinizden emin misiniz?\n\n⚠️ Bu işlem geri alınamaz!',
    confirmText: 'Sil',
    cancelText: 'İptal'
  })

  if (!confirmed) return

  try {
    const { error } = await supabase
      .from('appointments')
      .delete()
      .eq('id', appointmentId)

    if (error) throw error

    await fetchData()
    showSuccessNotification('Randevu başarıyla silindi.')
  } catch (err) {
    await showError(`Randevu silinirken hata oluştu:\n\n${err.message}`)
  }
}

// Randevu düzenleme
const editingAppointment = ref(null)
const appointmentForm = ref({
  employee_id: '',
  service_id: '',
  appointment_date: '',
  appointment_time: '',
  customer_name: '',
  customer_phone: '',
  notes: '',
  status: 'pending'
})

// Randevu erteleme
const rescheduleAppointment = ref(null)
const newDate = ref('')
const newTime = ref('')
const availableTimesForReschedule = ref([])
const loadingReschedule = ref(false)

// Toplu işlemler
const selectedAppointments = ref([])
const selectAll = ref(false)

const minDateForReschedule = computed(() => {
  return new Date().toISOString().split('T')[0]
})

const maxDateForReschedule = computed(() => {
  const date = new Date()
  date.setDate(date.getDate() + 60)
  return date.toISOString().split('T')[0]
})

const startReschedule = (appointment) => {
  rescheduleAppointment.value = appointment
  newDate.value = appointment.appointment_date
  newTime.value = ''
  availableTimesForReschedule.value = []
}

const cancelReschedule = () => {
  rescheduleAppointment.value = null
  newDate.value = ''
  newTime.value = ''
  availableTimesForReschedule.value = []
}

const fetchAvailableTimesForReschedule = async () => {
  if (!newDate.value || !rescheduleAppointment.value) return

  try {
    loadingReschedule.value = true

    // Mevcut randevuları çek (bu randevu hariç)
    const { data: existingAppointments, error: aptError } = await supabase
      .from('appointments')
      .select('appointment_time, service_id, services(duration)')
      .eq('employee_id', rescheduleAppointment.value.employee_id)
      .eq('appointment_date', newDate.value)
      .neq('id', rescheduleAppointment.value.id)
      .in('status', ['pending', 'confirmed'])

    if (aptError) throw aptError

    // Hizmet süresini bul
    const service = services.value.find(s => s.id === rescheduleAppointment.value.service_id)
    const duration = service?.duration || 30

    // Varsayılan çalışma saatleri
    const startHour = 9
    const endHour = 19

    // Tüm olası saatleri oluştur
    const times = []
    let currentHour = startHour
    let currentMinute = 0

    while (currentHour < endHour) {
      const timeStr = `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`

      // Bu saat müsait mi kontrol et
      const isAvailable = !existingAppointments?.some(apt => {
        const aptTime = apt.appointment_time.substring(0, 5)
        const aptDuration = apt.services?.duration || 30

        const [aptHour, aptMinute] = aptTime.split(':').map(Number)
        const aptStart = aptHour * 60 + aptMinute
        const aptEnd = aptStart + aptDuration

        const checkTime = currentHour * 60 + currentMinute
        const checkEnd = checkTime + duration

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

    availableTimesForReschedule.value = times
  } catch (err) {
    console.error('Müsait saatler hesaplanırken hata:', err)
  } finally {
    loadingReschedule.value = false
  }
}

const saveReschedule = async () => {
  if (!newDate.value || !newTime.value) {
    await showWarning('Lütfen yeni tarih ve saat seçin.', 'Eksik Bilgi')
    return
  }

  try {
    const { error } = await supabase
      .from('appointments')
      .update({
        appointment_date: newDate.value,
        appointment_time: newTime.value + ':00'
      })
      .eq('id', rescheduleAppointment.value.id)

    if (error) throw error

    await fetchData()
    showSuccessNotification('Randevu başarıyla ertelendi.')
    cancelReschedule()
  } catch (err) {
    await showError(`Randevu ertelenirken hata oluştu:\n\n${err.message}`)
  }
}

// Randevu düzenleme fonksiyonları
const startEditAppointment = (appointment) => {
  editingAppointment.value = appointment.id
  appointmentForm.value = {
    employee_id: appointment.employee_id,
    service_id: appointment.service_id,
    appointment_date: appointment.appointment_date,
    appointment_time: appointment.appointment_time.substring(0, 5),
    customer_name: appointment.customer_name,
    customer_phone: appointment.customer_phone,
    notes: appointment.notes || '',
    status: appointment.status
  }
}

const cancelEditAppointment = () => {
  editingAppointment.value = null
  appointmentForm.value = {
    employee_id: '',
    service_id: '',
    appointment_date: '',
    appointment_time: '',
    customer_name: '',
    customer_phone: '',
    notes: '',
    status: 'pending'
  }
}

const saveAppointmentEdit = async () => {
  if (!appointmentForm.value.employee_id || !appointmentForm.value.service_id ||
      !appointmentForm.value.appointment_date || !appointmentForm.value.appointment_time ||
      !appointmentForm.value.customer_name || !appointmentForm.value.customer_phone) {
    await showWarning('Lütfen tüm zorunlu alanları doldurun.', 'Eksik Bilgi')
    return
  }

  try {
    const { error } = await supabase
      .from('appointments')
      .update({
        employee_id: appointmentForm.value.employee_id,
        service_id: appointmentForm.value.service_id,
        appointment_date: appointmentForm.value.appointment_date,
        appointment_time: appointmentForm.value.appointment_time + ':00',
        customer_name: appointmentForm.value.customer_name,
        customer_phone: appointmentForm.value.customer_phone,
        notes: appointmentForm.value.notes,
        status: appointmentForm.value.status
      })
      .eq('id', editingAppointment.value)

    if (error) throw error

    await fetchData()
    showSuccessNotification('Randevu başarıyla güncellendi.')
    cancelEditAppointment()
  } catch (err) {
    await showError(`Randevu güncellenirken hata oluştu:\n\n${err.message}`)
  }
}

// Toplu işlem fonksiyonları
const toggleSelectAll = () => {
  if (selectAll.value) {
    selectedAppointments.value = filteredAppointments.value.map(apt => apt.id)
  } else {
    selectedAppointments.value = []
  }
}

const toggleSelectAppointment = (appointmentId) => {
  const index = selectedAppointments.value.indexOf(appointmentId)
  if (index > -1) {
    selectedAppointments.value.splice(index, 1)
  } else {
    selectedAppointments.value.push(appointmentId)
  }
  selectAll.value = selectedAppointments.value.length === filteredAppointments.value.length
}

const bulkDelete = async () => {
  if (selectedAppointments.value.length === 0) {
    await showWarning('Lütfen en az bir randevu seçin.', 'Randevu Seçilmedi')
    return
  }

  const confirmed = await showConfirm({
    type: 'warning',
    title: 'Toplu Silme',
    message: `${selectedAppointments.value.length} randevuyu kalıcı olarak silmek istediğinizden emin misiniz?\n\n⚠️ Bu işlem geri alınamaz!`,
    confirmText: 'Sil',
    cancelText: 'İptal'
  })

  if (!confirmed) return

  try {
    const { error } = await supabase
      .from('appointments')
      .delete()
      .in('id', selectedAppointments.value)

    if (error) throw error

    await fetchData()
    await showSuccess(`${selectedAppointments.value.length} randevu başarıyla silindi.`, 'Toplu Silme Başarılı')
    selectedAppointments.value = []
    selectAll.value = false
  } catch (err) {
    await showError(`Randevular silinirken hata oluştu:\n\n${err.message}`)
  }
}

const bulkUpdateStatus = async (newStatus) => {
  if (selectedAppointments.value.length === 0) {
    await showWarning('Lütfen en az bir randevu seçin.', 'Randevu Seçilmedi')
    return
  }

  try {
    const { error } = await supabase
      .from('appointments')
      .update({ status: newStatus })
      .in('id', selectedAppointments.value)

    if (error) throw error

    await fetchData()
    showSuccessNotification(`${selectedAppointments.value.length} randevunun durumu başarıyla güncellendi.`)
    selectedAppointments.value = []
    selectAll.value = false
  } catch (err) {
    await showError(`Randevu durumları güncellenirken hata oluştu:\n\n${err.message}`)
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Başlık -->
    <div class="bg-gradient-to-r from-indigo-600 to-purple-600 rounded-xl shadow-lg p-6 text-white">
      <h2 class="text-3xl font-bold mb-2">
        {{ isAdmin ? 'Yönetim Paneli' : `Hoş Geldiniz, ${employeeUser?.name}` }}
      </h2>
      <p class="text-indigo-100">
        {{ isAdmin ? 'Tüm randevuları, hizmetleri ve çalışanları yönetin' : 'Randevularınızı görüntüleyin ve yönetin' }}
      </p>
    </div>

    <!-- Tab Menüsü (Sadece admin için tüm tablar) -->
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
            v-if="isAdmin"
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
            v-if="isAdmin"
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

          <button
            v-if="isAdmin"
            @click="activeTab = 'working-hours'"
            :class="[
              'flex-1 py-4 px-6 text-center font-medium text-sm transition-colors',
              activeTab === 'working-hours'
                ? 'border-b-2 border-indigo-600 text-indigo-600 bg-indigo-50'
                : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
            ]"
          >
            <div class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>Çalışma Saatleri</span>
            </div>
          </button>
        </nav>
      </div>
    </div>

    <!-- Randevular Sekmesi -->
    <div v-if="activeTab === 'appointments'" class="space-y-6">
      <!-- İstatistikler (Sadece Admin) -->
      <div v-if="isAdmin && stats" class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div class="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg shadow-md p-4 text-white">
          <p class="text-sm opacity-90">Toplam Randevu</p>
          <p class="text-3xl font-bold mt-1">{{ stats.total }}</p>
        </div>
        <div class="bg-gradient-to-br from-green-500 to-green-600 rounded-lg shadow-md p-4 text-white">
          <p class="text-sm opacity-90">Bugün</p>
          <p class="text-3xl font-bold mt-1">{{ stats.today }}</p>
        </div>
        <div class="bg-gradient-to-br from-yellow-500 to-yellow-600 rounded-lg shadow-md p-4 text-white">
          <p class="text-sm opacity-90">Beklemede</p>
          <p class="text-3xl font-bold mt-1">{{ stats.pending }}</p>
        </div>
        <div class="bg-gradient-to-br from-indigo-500 to-indigo-600 rounded-lg shadow-md p-4 text-white">
          <p class="text-sm opacity-90">Onaylandı</p>
          <p class="text-3xl font-bold mt-1">{{ stats.confirmed }}</p>
        </div>
        <div class="bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg shadow-md p-4 text-white">
          <p class="text-sm opacity-90">Tamamlandı</p>
          <p class="text-3xl font-bold mt-1">{{ stats.completed }}</p>
        </div>
        <div class="bg-gradient-to-br from-red-500 to-red-600 rounded-lg shadow-md p-4 text-white">
          <p class="text-sm opacity-90">İptal Edildi</p>
          <p class="text-3xl font-bold mt-1">{{ stats.cancelled }}</p>
        </div>
      </div>

      <!-- Başlık ve Filtreler -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900">Randevu Yönetimi</h2>
          <p class="text-gray-600 mt-1">Tüm randevuları görüntüleyin ve yönetin</p>
        </div>

        <!-- Filtreler -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
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

          <!-- Çalışan Filtresi (Sadece Admin) -->
          <div v-if="isAdmin">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Çalışan
            </label>
            <select
              v-model="selectedEmployeeFilter"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            >
              <option value="">Tüm Çalışanlar</option>
              <option v-for="employee in employees" :key="employee.id" :value="employee.id">
                {{ employee.name }}
              </option>
            </select>
          </div>

          <!-- Durum Filtresi -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Durum
            </label>
            <select
              v-model="selectedStatusFilter"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            >
              <option value="">Tüm Durumlar</option>
              <option value="pending">Beklemede</option>
              <option value="confirmed">Onaylandı</option>
              <option value="completed">Tamamlandı</option>
              <option value="cancelled">İptal Edildi</option>
            </select>
          </div>
        </div>

        <!-- Filtreleri Temizle Butonu -->
        <div v-if="selectedEmployeeFilter || selectedStatusFilter" class="mt-4">
          <button
            @click="selectedEmployeeFilter = ''; selectedStatusFilter = ''"
            class="px-4 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Filtreleri Temizle
          </button>
        </div>
      </div>

      <!-- Toplu İşlem Araç Çubuğu (Sadece Admin) -->
      <div v-if="isAdmin && filteredAppointments.length > 0" class="bg-white rounded-lg shadow-md p-4">
        <div class="flex items-center justify-between flex-wrap gap-4">
          <div class="flex items-center gap-3">
            <input
              type="checkbox"
              :checked="selectAll"
              @change="toggleSelectAll"
              class="w-5 h-5 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
            />
            <span class="text-sm font-medium text-gray-700">
              {{ selectedAppointments.length > 0 ? `${selectedAppointments.length} randevu seçildi` : 'Tümünü Seç' }}
            </span>
          </div>

          <div v-if="selectedAppointments.length > 0" class="flex items-center gap-2 flex-wrap">
            <button
              @click="bulkUpdateStatus('confirmed')"
              class="px-4 py-2 text-sm bg-green-100 text-green-700 rounded-lg hover:bg-green-200 transition-colors"
            >
              Onayla
            </button>
            <button
              @click="bulkUpdateStatus('completed')"
              class="px-4 py-2 text-sm bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors"
            >
              Tamamlandı İşaretle
            </button>
            <button
              @click="bulkUpdateStatus('cancelled')"
              class="px-4 py-2 text-sm bg-yellow-100 text-yellow-700 rounded-lg hover:bg-yellow-200 transition-colors"
            >
              İptal Et
            </button>
            <button
              @click="bulkDelete"
              class="px-4 py-2 text-sm bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors"
            >
              Sil
            </button>
          </div>
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
          <div class="flex items-start gap-4">
            <!-- Checkbox (Sadece Admin) -->
            <div v-if="isAdmin" class="pt-1">
              <input
                type="checkbox"
                :checked="selectedAppointments.includes(appointment.id)"
                @change="toggleSelectAppointment(appointment.id)"
                class="w-5 h-5 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
              />
            </div>

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

            <!-- Randevu İşlemleri -->
            <div class="ml-4 flex flex-col gap-2">
              <!-- Admin İşlemleri -->
              <div v-if="isAdmin" class="flex flex-col gap-2">
                <!-- Düzenle Butonu -->
                <button
                  @click="startEditAppointment(appointment)"
                  class="px-4 py-2 text-sm bg-indigo-50 text-indigo-700 rounded-lg hover:bg-indigo-100 transition-colors flex items-center gap-2"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                  Düzenle
                </button>

                <!-- Durum Değiştirme -->
                <select
                  :value="appointment.status"
                  @change="updateAppointmentStatus(appointment.id, $event.target.value)"
                  class="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                >
                  <option value="pending">Beklemede</option>
                  <option value="confirmed">Onaylandı</option>
                  <option value="completed">Tamamlandı</option>
                  <option value="cancelled">İptal Edildi</option>
                </select>
              </div>

              <!-- Çalışan butonları -->
              <div v-if="!isAdmin && appointment.status !== 'cancelled' && appointment.status !== 'completed'" class="flex flex-col gap-2">
                <!-- Erteleme Butonu -->
                <button
                  @click="startReschedule(appointment)"
                  class="px-4 py-2 text-sm bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors flex items-center gap-2"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  Ertele
                </button>

                <!-- İptal Butonu -->
                <button
                  @click="cancelAppointment(appointment.id)"
                  class="px-4 py-2 text-sm bg-red-50 text-red-700 rounded-lg hover:bg-red-100 transition-colors flex items-center gap-2"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                  İptal Et
                </button>
              </div>

              <!-- Silme Butonu (Sadece Admin) -->
              <button
                v-if="isAdmin"
                @click="deleteAppointment(appointment.id)"
                class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Randevuyu Sil"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
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

    <!-- Çalışma Saatleri Sekmesi -->
    <div v-if="activeTab === 'working-hours'">
      <WorkingHoursManagement />
    </div>

    <!-- Randevu Düzenleme Modalı (Admin) -->
    <div v-if="editingAppointment" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-2xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div class="p-6">
          <!-- Modal Başlık -->
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-2xl font-bold text-gray-900">Randevuyu Düzenle</h3>
            <button @click="cancelEditAppointment" class="text-gray-400 hover:text-gray-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Düzenleme Formu -->
          <div class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Çalışan Seçimi -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Çalışan *</label>
                <select
                  v-model="appointmentForm.employee_id"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                >
                  <option value="">Çalışan Seçin</option>
                  <option v-for="employee in employees" :key="employee.id" :value="employee.id">
                    {{ employee.name }}
                  </option>
                </select>
              </div>

              <!-- Hizmet Seçimi -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Hizmet *</label>
                <select
                  v-model="appointmentForm.service_id"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                >
                  <option value="">Hizmet Seçin</option>
                  <option v-for="service in services" :key="service.id" :value="service.id">
                    {{ service.name }} - {{ service.price }} TL
                  </option>
                </select>
              </div>

              <!-- Tarih -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Tarih *</label>
                <input
                  v-model="appointmentForm.appointment_date"
                  type="date"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
              </div>

              <!-- Saat -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Saat *</label>
                <input
                  v-model="appointmentForm.appointment_time"
                  type="time"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
              </div>

              <!-- Müşteri Adı -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Müşteri Adı *</label>
                <input
                  v-model="appointmentForm.customer_name"
                  type="text"
                  placeholder="Ad Soyad"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
              </div>

              <!-- Telefon -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Telefon *</label>
                <input
                  v-model="appointmentForm.customer_phone"
                  type="tel"
                  placeholder="0555 555 55 55"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
              </div>

              <!-- Durum -->
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-2">Durum *</label>
                <select
                  v-model="appointmentForm.status"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                >
                  <option value="pending">Beklemede</option>
                  <option value="confirmed">Onaylandı</option>
                  <option value="completed">Tamamlandı</option>
                  <option value="cancelled">İptal Edildi</option>
                </select>
              </div>

              <!-- Notlar -->
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-2">Notlar</label>
                <textarea
                  v-model="appointmentForm.notes"
                  rows="3"
                  placeholder="Randevu hakkında notlar..."
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                ></textarea>
              </div>
            </div>
          </div>

          <!-- Butonlar -->
          <div class="flex gap-3 mt-6">
            <button
              @click="saveAppointmentEdit"
              class="flex-1 px-6 py-3 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-lg hover:from-indigo-700 hover:to-purple-700 transition-all shadow-md hover:shadow-lg font-semibold"
            >
              Değişiklikleri Kaydet
            </button>
            <button
              @click="cancelEditAppointment"
              class="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-semibold"
            >
              İptal
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Randevu Erteleme Modalı -->
    <div v-if="rescheduleAppointment" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div class="p-6">
          <!-- Modal Başlık -->
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-2xl font-bold text-gray-900">Randevuyu Ertele</h3>
            <button @click="cancelReschedule" class="text-gray-400 hover:text-gray-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Mevcut Randevu Bilgisi -->
          <div class="bg-gray-50 p-4 rounded-lg mb-6">
            <h4 class="font-semibold text-gray-900 mb-2">Mevcut Randevu</h4>
            <div class="grid grid-cols-2 gap-3 text-sm">
              <div>
                <p class="text-gray-600">Müşteri</p>
                <p class="font-semibold">{{ rescheduleAppointment.customer_name }}</p>
              </div>
              <div>
                <p class="text-gray-600">Hizmet</p>
                <p class="font-semibold">{{ getServiceName(rescheduleAppointment.service_id) }}</p>
              </div>
              <div>
                <p class="text-gray-600">Mevcut Tarih</p>
                <p class="font-semibold">{{ formatDate(rescheduleAppointment.appointment_date) }}</p>
              </div>
              <div>
                <p class="text-gray-600">Mevcut Saat</p>
                <p class="font-semibold">{{ formatTime(rescheduleAppointment.appointment_time) }}</p>
              </div>
            </div>
          </div>

          <!-- Yeni Tarih Seçimi -->
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Yeni Tarih</label>
              <input
                v-model="newDate"
                @change="fetchAvailableTimesForReschedule"
                type="date"
                :min="minDateForReschedule"
                :max="maxDateForReschedule"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <!-- Yeni Saat Seçimi -->
            <div v-if="newDate">
              <label class="block text-sm font-medium text-gray-700 mb-2">Yeni Saat</label>
              <div v-if="loadingReschedule" class="text-center py-8">
                <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                <p class="text-gray-600 mt-2">Müsait saatler yükleniyor...</p>
              </div>
              <div v-else-if="availableTimesForReschedule.length === 0" class="text-center py-8 bg-red-50 rounded-lg">
                <p class="text-red-800">Bu tarihte müsait saat bulunmamaktadır.</p>
              </div>
              <div v-else class="grid grid-cols-3 md:grid-cols-4 gap-3 max-h-64 overflow-y-auto p-2">
                <button
                  v-for="time in availableTimesForReschedule"
                  :key="time"
                  @click="newTime = time"
                  :class="[
                    'px-4 py-3 border-2 rounded-lg font-semibold transition-all',
                    newTime === time
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-200 hover:border-blue-300 hover:bg-blue-50'
                  ]"
                >
                  {{ time }}
                </button>
              </div>
            </div>
          </div>

          <!-- Butonlar -->
          <div class="flex gap-3 mt-6">
            <button
              @click="saveReschedule"
              :disabled="!newDate || !newTime"
              class="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed font-semibold"
            >
              Randevuyu Ertele
            </button>
            <button
              @click="cancelReschedule"
              class="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-semibold"
            >
              İptal
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
