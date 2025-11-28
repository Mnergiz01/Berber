<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'

const emit = defineEmits(['employee-selected'])

const barbers = ref([])
const loading = ref(true)
const error = ref(null)

onMounted(async () => {
  await fetchBarbers()
})

const fetchBarbers = async () => {
  try {
    loading.value = true
    error.value = null

    const { data, error: fetchError } = await supabase
      .from('employees')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true })

    if (fetchError) throw fetchError

    barbers.value = data || []
  } catch (err) {
    error.value = err.message
    console.error('Çalışanlar yüklenirken hata:', err)
  } finally {
    loading.value = false
  }
}

// Çalışana tıklandığında seçili çalışanı emit et ve randevu formuna kaydır
const selectEmployee = (employee) => {
  // Seçili çalışanı parent component'e gönder
  emit('employee-selected', employee)

  // Randevu formuna kaydır
  setTimeout(() => {
    const appointmentForm = document.querySelector('#appointment-form')
    if (appointmentForm) {
      appointmentForm.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }, 300)
}
</script>

<template>
  <div class="space-y-6">
    <!-- Başlık -->
    <div class="text-center">
      <h2 class="text-3xl font-bold text-gray-900 mb-2">Çalışanlarımız</h2>
      <p class="text-gray-600">Randevu almak istediğiniz çalışanı seçin</p>
    </div>

    <!-- Yükleniyor -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
    </div>

    <!-- Hata -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
      <p class="text-red-800">Hata: {{ error }}</p>
      <button
        @click="fetchBarbers"
        class="mt-4 bg-red-600 text-white px-6 py-2 rounded-lg hover:bg-red-700 transition-colors"
      >
        Tekrar Dene
      </button>
    </div>

    <!-- Çalışanlar Listesi -->
    <div v-else-if="barbers.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="barber in barbers"
        :key="barber.id"
        @click="selectEmployee(barber)"
        class="bg-white rounded-xl shadow-md hover:shadow-xl transition-all duration-300 cursor-pointer transform hover:-translate-y-1 overflow-hidden"
      >
        <!-- Fotoğraf Alanı -->
        <div class="h-48 bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
          <div class="w-32 h-32 rounded-full bg-white flex items-center justify-center shadow-lg">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-20 w-20 text-indigo-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
        </div>

        <!-- Bilgiler -->
        <div class="p-6 text-center">
          <h3 class="text-xl font-bold text-gray-900 mb-2">{{ barber.name }}</h3>
          <p class="text-indigo-600 font-medium">{{ barber.specialty || 'Uzman' }}</p>

          <!-- Çalışma Saatleri -->
          <div v-if="barber.work_start_time && barber.work_end_time" class="mt-4 text-sm text-gray-600">
            <p class="flex items-center justify-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {{ barber.work_start_time.substring(0, 5) }} - {{ barber.work_end_time.substring(0, 5) }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Boş Durum -->
    <div v-else class="text-center py-12 bg-gray-50 rounded-lg">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
      </svg>
      <p class="mt-4 text-lg text-gray-600">Şu anda aktif çalışan bulunmamaktadır</p>
    </div>
  </div>
</template>
