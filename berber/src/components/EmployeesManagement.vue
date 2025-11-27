<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'

const employees = ref([])
const services = ref([])
const loading = ref(true)
const error = ref(null)
const editingEmployee = ref(null)
const isAddingNew = ref(false)

const employeeForm = ref({
  name: '',
  specialty: '',
  phone: '',
  email: '',
  workStartTime: '09:00',
  workEndTime: '19:00',
  bio: '',
  selectedServices: []
})

onMounted(async () => {
  await fetchData()
})

const fetchData = async () => {
  try {
    loading.value = true
    error.value = null

    const [
      { data: employeesData, error: employeesError },
      { data: servicesData, error: servicesError }
    ] = await Promise.all([
      supabase.from('employees').select('*').eq('is_active', true).order('name', { ascending: true }),
      supabase.from('services').select('*').order('name', { ascending: true })
    ])

    if (employeesError) throw employeesError
    if (servicesError) throw servicesError

    services.value = servicesData || []

    // Her çalışan için hizmetlerini yükle
    const employeesWithServices = await Promise.all(
      (employeesData || []).map(async (employee) => {
        const { data: empServicesData } = await supabase
          .from('employee_services')
          .select('service_id')
          .eq('employee_id', employee.id)

        return {
          ...employee,
          serviceIds: empServicesData?.map(es => es.service_id) || []
        }
      })
    )

    employees.value = employeesWithServices
  } catch (err) {
    error.value = err.message
    console.error('Veri yüklenirken hata:', err)
  } finally {
    loading.value = false
  }
}

const startAdd = () => {
  isAddingNew.value = true
  employeeForm.value = {
    name: '',
    specialty: '',
    phone: '',
    email: '',
    workStartTime: '09:00',
    workEndTime: '19:00',
    bio: '',
    selectedServices: []
  }
}

const startEdit = (employee) => {
  editingEmployee.value = employee.id
  employeeForm.value = {
    name: employee.name,
    specialty: employee.specialty || '',
    phone: employee.phone || '',
    email: employee.email || '',
    workStartTime: employee.work_start_time || '09:00',
    workEndTime: employee.work_end_time || '19:00',
    bio: employee.bio || '',
    selectedServices: [...employee.serviceIds]
  }
}

const cancelEdit = () => {
  editingEmployee.value = null
  isAddingNew.value = false
  employeeForm.value = {
    name: '',
    specialty: '',
    phone: '',
    email: '',
    workStartTime: '09:00',
    workEndTime: '19:00',
    bio: '',
    selectedServices: []
  }
}

const saveEmployee = async () => {
  try {
    if (!employeeForm.value.name) {
      alert('Lütfen çalışan adını girin!')
      return
    }

    let employeeId

    if (isAddingNew.value) {
      // Yeni çalışan ekle
      const { data: newEmployee, error: insertError } = await supabase
        .from('employees')
        .insert({
          name: employeeForm.value.name,
          specialty: employeeForm.value.specialty,
          phone: employeeForm.value.phone,
          email: employeeForm.value.email,
          work_start_time: employeeForm.value.workStartTime,
          work_end_time: employeeForm.value.workEndTime,
          bio: employeeForm.value.bio,
          is_active: true
        })
        .select()
        .single()

      if (insertError) throw insertError
      employeeId = newEmployee.id
      alert('Çalışan başarıyla eklendi!')
    } else {
      // Mevcut çalışanı güncelle
      const { error: updateError } = await supabase
        .from('employees')
        .update({
          name: employeeForm.value.name,
          specialty: employeeForm.value.specialty,
          phone: employeeForm.value.phone,
          email: employeeForm.value.email,
          work_start_time: employeeForm.value.workStartTime,
          work_end_time: employeeForm.value.workEndTime,
          bio: employeeForm.value.bio
        })
        .eq('id', editingEmployee.value)

      if (updateError) throw updateError
      employeeId = editingEmployee.value
      alert('Çalışan başarıyla güncellendi!')
    }

    // Hizmetleri güncelle - önce mevcut ilişkileri sil, sonra yenilerini ekle
    await supabase
      .from('employee_services')
      .delete()
      .eq('employee_id', employeeId)

    if (employeeForm.value.selectedServices.length > 0) {
      const employeeServices = employeeForm.value.selectedServices.map(serviceId => ({
        employee_id: employeeId,
        service_id: serviceId
      }))

      const { error: servicesError } = await supabase
        .from('employee_services')
        .insert(employeeServices)

      if (servicesError) throw servicesError
    }

    cancelEdit()
    await fetchData()
  } catch (err) {
    alert('Hata: ' + err.message)
    console.error('Çalışan kaydedilirken hata:', err)
  }
}

const deleteEmployee = async (employeeId) => {
  if (!confirm('Bu çalışanı pasif hale getirmek istediğinizden emin misiniz?')) {
    return
  }

  try {
    const { error: updateError } = await supabase
      .from('employees')
      .update({ is_active: false })
      .eq('id', employeeId)

    if (updateError) throw updateError

    alert('Çalışan başarıyla pasif hale getirildi!')
    await fetchData()
  } catch (err) {
    alert('Çalışan silinirken hata oluştu: ' + err.message)
    console.error('Çalışan silme hatası:', err)
  }
}

const getServiceName = (serviceId) => {
  const service = services.value.find(s => s.id === serviceId)
  return service ? service.name : 'Bilinmiyor'
}
</script>

<template>
  <div class="space-y-6">
    <!-- Başlık ve Yeni Çalışan Butonu -->
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-xl font-bold text-gray-900">Çalışan Yönetimi</h3>
        <p class="text-sm text-gray-600 mt-1">Çalışanları düzenleyin, ekleyin veya pasif hale getirin</p>
      </div>
      <button
        v-if="!isAddingNew && !editingEmployee"
        @click="startAdd"
        class="px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 transition-all shadow-md hover:shadow-lg flex items-center gap-2"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Yeni Çalışan
      </button>
    </div>

    <!-- Yükleniyor -->
    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Çalışanlar yükleniyor...</p>
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

    <!-- Yeni Çalışan Ekleme Formu -->
    <div v-else-if="isAddingNew" class="bg-white rounded-lg shadow-md p-6 border-2 border-green-200">
      <h4 class="text-lg font-bold text-gray-900 mb-4">Yeni Çalışan Ekle</h4>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Ad Soyad *</label>
          <input
            v-model="employeeForm.name"
            type="text"
            placeholder="Örn: Ahmet Yılmaz"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Uzmanlık</label>
          <input
            v-model="employeeForm.specialty"
            type="text"
            placeholder="Örn: Saç Kesimi & Sakal"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Telefon</label>
          <input
            v-model="employeeForm.phone"
            type="tel"
            placeholder="Örn: 0555 555 55 55"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">E-posta</label>
          <input
            v-model="employeeForm.email"
            type="email"
            placeholder="Örn: ahmet@example.com"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Başlangıç Saati</label>
          <input
            v-model="employeeForm.workStartTime"
            type="time"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Bitiş Saati</label>
          <input
            v-model="employeeForm.workEndTime"
            type="time"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-2">Hakkında</label>
          <textarea
            v-model="employeeForm.bio"
            rows="3"
            placeholder="Çalışan hakkında kısa bilgi"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          ></textarea>
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-2">Yapabildiği Hizmetler</label>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3 max-h-48 overflow-y-auto border border-gray-200 rounded-lg p-4">
            <label
              v-for="service in services"
              :key="service.id"
              class="flex items-center space-x-2 cursor-pointer"
            >
              <input
                type="checkbox"
                :value="service.id"
                v-model="employeeForm.selectedServices"
                class="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
              />
              <span class="text-sm text-gray-700">{{ service.name }}</span>
            </label>
          </div>
        </div>
      </div>
      <div class="flex gap-3 mt-6">
        <button
          @click="saveEmployee"
          class="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
        >
          Kaydet
        </button>
        <button
          @click="cancelEdit"
          class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-medium"
        >
          İptal
        </button>
      </div>
    </div>

    <!-- Çalışanlar Listesi -->
    <div v-else class="space-y-4">
      <div
        v-for="employee in employees"
        :key="employee.id"
        class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
      >
        <!-- Düzenleme Modu -->
        <div v-if="editingEmployee === employee.id" class="space-y-4">
          <h4 class="text-lg font-bold text-gray-900 mb-4">Çalışanı Düzenle</h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Ad Soyad *</label>
              <input
                v-model="employeeForm.name"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Uzmanlık</label>
              <input
                v-model="employeeForm.specialty"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Telefon</label>
              <input
                v-model="employeeForm.phone"
                type="tel"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">E-posta</label>
              <input
                v-model="employeeForm.email"
                type="email"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Başlangıç Saati</label>
              <input
                v-model="employeeForm.workStartTime"
                type="time"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Bitiş Saati</label>
              <input
                v-model="employeeForm.workEndTime"
                type="time"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm font-medium text-gray-700 mb-2">Hakkında</label>
              <textarea
                v-model="employeeForm.bio"
                rows="3"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              ></textarea>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm font-medium text-gray-700 mb-2">Yapabildiği Hizmetler</label>
              <div class="grid grid-cols-2 md:grid-cols-3 gap-3 max-h-48 overflow-y-auto border border-gray-200 rounded-lg p-4">
                <label
                  v-for="service in services"
                  :key="service.id"
                  class="flex items-center space-x-2 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    :value="service.id"
                    v-model="employeeForm.selectedServices"
                    class="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
                  />
                  <span class="text-sm text-gray-700">{{ service.name }}</span>
                </label>
              </div>
            </div>
          </div>
          <div class="flex gap-3">
            <button
              @click="saveEmployee"
              class="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium"
            >
              Kaydet
            </button>
            <button
              @click="cancelEdit"
              class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-medium"
            >
              İptal
            </button>
          </div>
        </div>

        <!-- Görüntüleme Modu -->
        <div v-else class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-3 mb-3">
              <h4 class="text-lg font-bold text-gray-900">{{ employee.name }}</h4>
              <span v-if="employee.specialty" class="px-3 py-1 bg-indigo-100 text-indigo-800 text-xs font-semibold rounded-full">
                {{ employee.specialty }}
              </span>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 text-sm">
              <div v-if="employee.phone">
                <p class="text-gray-600">Telefon</p>
                <p class="font-semibold text-gray-900">{{ employee.phone }}</p>
              </div>
              <div v-if="employee.email">
                <p class="text-gray-600">E-posta</p>
                <p class="font-semibold text-gray-900">{{ employee.email }}</p>
              </div>
              <div>
                <p class="text-gray-600">Çalışma Saatleri</p>
                <p class="font-semibold text-gray-900">
                  {{ employee.work_start_time?.substring(0, 5) }} - {{ employee.work_end_time?.substring(0, 5) }}
                </p>
              </div>
            </div>

            <div v-if="employee.bio" class="mt-4 text-sm text-gray-600 bg-gray-50 p-3 rounded">
              {{ employee.bio }}
            </div>

            <div v-if="employee.serviceIds.length > 0" class="mt-4">
              <p class="text-sm text-gray-600 mb-2">Yapabildiği Hizmetler:</p>
              <div class="flex flex-wrap gap-2">
                <span
                  v-for="serviceId in employee.serviceIds"
                  :key="serviceId"
                  class="px-3 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full"
                >
                  {{ getServiceName(serviceId) }}
                </span>
              </div>
            </div>
          </div>

          <div class="flex gap-2 ml-4">
            <button
              @click="startEdit(employee)"
              class="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
              title="Düzenle"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button
              @click="deleteEmployee(employee.id)"
              class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              title="Pasif Yap"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Boş Durum -->
      <div v-if="employees.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <p class="mt-4 text-lg text-gray-600">Henüz çalışan eklenmemiş</p>
        <p class="text-gray-500">Yukarıdaki "Yeni Çalışan" butonuna tıklayarak başlayın</p>
      </div>
    </div>
  </div>
</template>
