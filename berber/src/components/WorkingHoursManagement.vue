<script setup>
import { ref, onMounted, computed } from 'vue'
import { supabase } from '../supabase'

const employees = ref([])
const workingDays = ref([])
const loading = ref(true)
const error = ref(null)
const selectedEmployee = ref(null)
const editingDay = ref(null)

const dayNames = {
  0: 'Pazar',
  1: 'Pazartesi',
  2: 'Salı',
  3: 'Çarşamba',
  4: 'Perşembe',
  5: 'Cuma',
  6: 'Cumartesi'
}

onMounted(async () => {
  await fetchEmployees()
})

const fetchEmployees = async () => {
  try {
    loading.value = true
    const { data, error: fetchError } = await supabase
      .from('employees')
      .select('*')
      .eq('is_active', true)
      .order('name')

    if (fetchError) throw fetchError
    employees.value = data || []
  } catch (err) {
    error.value = err.message
    console.error('Çalışanlar yüklenirken hata:', err)
  } finally {
    loading.value = false
  }
}

const fetchWorkingDays = async (employeeId) => {
  try {
    loading.value = true
    const { data, error: fetchError } = await supabase
      .from('employee_working_days')
      .select('*')
      .eq('employee_id', employeeId)
      .order('day_of_week')

    if (fetchError) throw fetchError
    workingDays.value = data || []
  } catch (err) {
    error.value = err.message
    console.error('Çalışma günleri yüklenirken hata:', err)
  } finally {
    loading.value = false
  }
}

const selectEmployee = async (employee) => {
  selectedEmployee.value = employee
  await fetchWorkingDays(employee.id)
}

const getWorkingDay = (dayOfWeek) => {
  return workingDays.value.find(wd => wd.day_of_week === dayOfWeek)
}

const toggleWorkingDay = async (dayOfWeek) => {
  if (!selectedEmployee.value) return

  const existingDay = getWorkingDay(dayOfWeek)

  try {
    if (existingDay) {
      // Mevcut günü aktif/pasif yap
      const { error: updateError } = await supabase
        .from('employee_working_days')
        .update({ is_active: !existingDay.is_active })
        .eq('id', existingDay.id)

      if (updateError) throw updateError
    } else {
      // Yeni çalışma günü ekle
      const { error: insertError } = await supabase
        .from('employee_working_days')
        .insert({
          employee_id: selectedEmployee.value.id,
          day_of_week: dayOfWeek,
          start_time: '09:00',
          end_time: '19:00',
          is_active: true
        })

      if (insertError) throw insertError
    }

    await fetchWorkingDays(selectedEmployee.value.id)
  } catch (err) {
    alert('Çalışma günü güncellenirken hata: ' + err.message)
  }
}

const startEditDay = (dayOfWeek) => {
  const workingDay = getWorkingDay(dayOfWeek)
  if (workingDay && workingDay.is_active) {
    editingDay.value = {
      day_of_week: dayOfWeek,
      start_time: workingDay.start_time.substring(0, 5),
      end_time: workingDay.end_time.substring(0, 5),
      id: workingDay.id
    }
  }
}

const cancelEdit = () => {
  editingDay.value = null
}

const saveWorkingHours = async () => {
  if (!editingDay.value) return

  try {
    const { error: updateError } = await supabase
      .from('employee_working_days')
      .update({
        start_time: editingDay.value.start_time + ':00',
        end_time: editingDay.value.end_time + ':00'
      })
      .eq('id', editingDay.value.id)

    if (updateError) throw updateError

    await fetchWorkingDays(selectedEmployee.value.id)
    alert('Çalışma saatleri başarıyla güncellendi!')
    cancelEdit()
  } catch (err) {
    alert('Çalışma saatleri güncellenirken hata: ' + err.message)
  }
}

const isWorking = (dayOfWeek) => {
  const workingDay = getWorkingDay(dayOfWeek)
  return workingDay && workingDay.is_active
}

const getWorkingHours = (dayOfWeek) => {
  const workingDay = getWorkingDay(dayOfWeek)
  if (workingDay && workingDay.is_active) {
    return `${workingDay.start_time.substring(0, 5)} - ${workingDay.end_time.substring(0, 5)}`
  }
  return 'Çalışmıyor'
}
</script>

<template>
  <div class="space-y-6">
    <div class="bg-gradient-to-r from-indigo-600 to-purple-600 rounded-xl shadow-lg p-6 text-white">
      <h2 class="text-3xl font-bold mb-2">Çalışma Saatleri Yönetimi</h2>
      <p class="text-indigo-100">Çalışanların hangi günlerde ve saatlerde çalışacağını belirleyin</p>
    </div>

    <!-- Çalışan Seçimi -->
    <div class="bg-white rounded-lg shadow-md p-6">
      <h3 class="text-xl font-bold text-gray-900 mb-4">Çalışan Seçin</h3>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <button
          v-for="employee in employees"
          :key="employee.id"
          @click="selectEmployee(employee)"
          :class="[
            'p-4 rounded-lg border-2 text-left transition-all',
            selectedEmployee?.id === employee.id
              ? 'border-indigo-600 bg-indigo-50'
              : 'border-gray-200 hover:border-indigo-300 hover:bg-gray-50'
          ]"
        >
          <p class="font-bold text-gray-900">{{ employee.name }}</p>
          <p class="text-sm text-gray-600">{{ employee.specialty || 'Uzman' }}</p>
        </button>
      </div>

      <div v-if="employees.length === 0" class="text-center py-8 text-gray-500">
        Aktif çalışan bulunamadı
      </div>
    </div>

    <!-- Çalışma Günleri ve Saatleri -->
    <div v-if="selectedEmployee" class="bg-white rounded-lg shadow-md p-6">
      <h3 class="text-xl font-bold text-gray-900 mb-4">
        {{ selectedEmployee.name }} - Çalışma Günleri
      </h3>

      <div class="space-y-3">
        <div
          v-for="day in [1, 2, 3, 4, 5, 6, 0]"
          :key="day"
          class="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
        >
          <div class="flex items-center gap-4 flex-1">
            <!-- Checkbox -->
            <label class="flex items-center cursor-pointer">
              <input
                type="checkbox"
                :checked="isWorking(day)"
                @change="toggleWorkingDay(day)"
                class="w-5 h-5 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
              />
              <span class="ml-3 text-lg font-medium text-gray-900 w-24">
                {{ dayNames[day] }}
              </span>
            </label>

            <!-- Çalışma Saatleri -->
            <div class="flex-1">
              <span
                v-if="isWorking(day)"
                class="text-gray-700 font-medium"
              >
                {{ getWorkingHours(day) }}
              </span>
              <span v-else class="text-gray-400">
                Çalışmıyor
              </span>
            </div>

            <!-- Saat Düzenleme Butonu -->
            <button
              v-if="isWorking(day)"
              @click="startEditDay(day)"
              class="px-4 py-2 text-sm bg-indigo-100 text-indigo-700 rounded-lg hover:bg-indigo-200 transition-colors"
            >
              Saatleri Düzenle
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Saat Düzenleme Modalı -->
    <div v-if="editingDay" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-2xl max-w-md w-full">
        <div class="p-6">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-2xl font-bold text-gray-900">
              {{ dayNames[editingDay.day_of_week] }} - Çalışma Saatleri
            </h3>
            <button @click="cancelEdit" class="text-gray-400 hover:text-gray-600">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Başlangıç Saati</label>
              <input
                v-model="editingDay.start_time"
                type="time"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Bitiş Saati</label>
              <input
                v-model="editingDay.end_time"
                type="time"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
          </div>

          <div class="flex gap-3 mt-6">
            <button
              @click="saveWorkingHours"
              class="flex-1 px-6 py-3 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-lg hover:from-indigo-700 hover:to-purple-700 transition-all shadow-md hover:shadow-lg font-semibold"
            >
              Kaydet
            </button>
            <button
              @click="cancelEdit"
              class="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-semibold"
            >
              İptal
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Yükleniyor -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Yükleniyor...</p>
    </div>
  </div>
</template>
