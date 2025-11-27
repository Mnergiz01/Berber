<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'

const services = ref([])
const loading = ref(true)
const error = ref(null)
const editingService = ref(null)
const isAddingNew = ref(false)

const serviceForm = ref({
  name: '',
  duration: 30,
  price: 0,
  description: ''
})

onMounted(async () => {
  await fetchServices()
})

const fetchServices = async () => {
  try {
    loading.value = true
    error.value = null

    const { data, error: fetchError } = await supabase
      .from('services')
      .select('*')
      .order('name', { ascending: true })

    if (fetchError) throw fetchError

    services.value = data || []
  } catch (err) {
    error.value = err.message
    console.error('Hizmetler yüklenirken hata:', err)
  } finally {
    loading.value = false
  }
}

const startAdd = () => {
  isAddingNew.value = true
  serviceForm.value = {
    name: '',
    duration: 30,
    price: 0,
    description: ''
  }
}

const startEdit = (service) => {
  editingService.value = service.id
  serviceForm.value = {
    name: service.name,
    duration: service.duration,
    price: service.price,
    description: service.description || ''
  }
}

const cancelEdit = () => {
  editingService.value = null
  isAddingNew.value = false
  serviceForm.value = {
    name: '',
    duration: 30,
    price: 0,
    description: ''
  }
}

const saveService = async () => {
  try {
    if (!serviceForm.value.name || serviceForm.value.duration <= 0 || serviceForm.value.price < 0) {
      alert('Lütfen tüm zorunlu alanları doldurun!')
      return
    }

    if (isAddingNew.value) {
      // Yeni hizmet ekle
      const { error: insertError } = await supabase
        .from('services')
        .insert({
          name: serviceForm.value.name,
          duration: serviceForm.value.duration,
          price: serviceForm.value.price,
          description: serviceForm.value.description
        })

      if (insertError) throw insertError
      alert('Hizmet başarıyla eklendi!')
    } else {
      // Mevcut hizmeti güncelle
      const { error: updateError } = await supabase
        .from('services')
        .update({
          name: serviceForm.value.name,
          duration: serviceForm.value.duration,
          price: serviceForm.value.price,
          description: serviceForm.value.description
        })
        .eq('id', editingService.value)

      if (updateError) throw updateError
      alert('Hizmet başarıyla güncellendi!')
    }

    cancelEdit()
    await fetchServices()
  } catch (err) {
    alert('Hata: ' + err.message)
    console.error('Hizmet kaydedilirken hata:', err)
  }
}

const deleteService = async (serviceId) => {
  if (!confirm('Bu hizmeti silmek istediğinizden emin misiniz?')) {
    return
  }

  try {
    const { error: deleteError } = await supabase
      .from('services')
      .delete()
      .eq('id', serviceId)

    if (deleteError) throw deleteError

    alert('Hizmet başarıyla silindi!')
    await fetchServices()
  } catch (err) {
    alert('Hizmet silinirken hata oluştu: ' + err.message)
    console.error('Hizmet silme hatası:', err)
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Başlık ve Yeni Hizmet Butonu -->
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-xl font-bold text-gray-900">Hizmet Yönetimi</h3>
        <p class="text-sm text-gray-600 mt-1">Hizmetleri düzenleyin, ekleyin veya silin</p>
      </div>
      <button
        v-if="!isAddingNew && !editingService"
        @click="startAdd"
        class="px-4 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 transition-all shadow-md hover:shadow-lg flex items-center gap-2"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Yeni Hizmet
      </button>
    </div>

    <!-- Yükleniyor -->
    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Hizmetler yükleniyor...</p>
    </div>

    <!-- Hata -->
    <div v-else-if="error" class="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
      <p class="text-red-800">Hata: {{ error }}</p>
      <button
        @click="fetchServices"
        class="mt-4 bg-red-600 text-white px-6 py-2 rounded-lg hover:bg-red-700 transition-colors"
      >
        Tekrar Dene
      </button>
    </div>

    <!-- Yeni Hizmet Ekleme Formu -->
    <div v-else-if="isAddingNew" class="bg-white rounded-lg shadow-md p-6 border-2 border-green-200">
      <h4 class="text-lg font-bold text-gray-900 mb-4">Yeni Hizmet Ekle</h4>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Hizmet Adı *</label>
          <input
            v-model="serviceForm.name"
            type="text"
            placeholder="Örn: Saç Kesimi"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Süre (dakika) *</label>
          <input
            v-model.number="serviceForm.duration"
            type="number"
            min="5"
            step="5"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Fiyat (TL) *</label>
          <input
            v-model.number="serviceForm.price"
            type="number"
            min="0"
            step="0.01"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">Açıklama</label>
          <input
            v-model="serviceForm.description"
            type="text"
            placeholder="Hizmet hakkında kısa açıklama"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
      </div>
      <div class="flex gap-3 mt-6">
        <button
          @click="saveService"
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

    <!-- Hizmetler Listesi -->
    <div v-else class="space-y-4">
      <div
        v-for="service in services"
        :key="service.id"
        class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
      >
        <!-- Düzenleme Modu -->
        <div v-if="editingService === service.id" class="space-y-4">
          <h4 class="text-lg font-bold text-gray-900 mb-4">Hizmeti Düzenle</h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Hizmet Adı *</label>
              <input
                v-model="serviceForm.name"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Süre (dakika) *</label>
              <input
                v-model.number="serviceForm.duration"
                type="number"
                min="5"
                step="5"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Fiyat (TL) *</label>
              <input
                v-model.number="serviceForm.price"
                type="number"
                min="0"
                step="0.01"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Açıklama</label>
              <input
                v-model="serviceForm.description"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
          </div>
          <div class="flex gap-3">
            <button
              @click="saveService"
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
            <h4 class="text-lg font-bold text-gray-900">{{ service.name }}</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-3 text-sm">
              <div>
                <p class="text-gray-600">Süre</p>
                <p class="font-semibold text-gray-900">{{ service.duration }} dakika</p>
              </div>
              <div>
                <p class="text-gray-600">Fiyat</p>
                <p class="font-semibold text-gray-900">{{ service.price }} TL</p>
              </div>
              <div v-if="service.description">
                <p class="text-gray-600">Açıklama</p>
                <p class="font-semibold text-gray-900">{{ service.description }}</p>
              </div>
            </div>
          </div>
          <div class="flex gap-2 ml-4">
            <button
              @click="startEdit(service)"
              class="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
              title="Düzenle"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
            </button>
            <button
              @click="deleteService(service.id)"
              class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              title="Sil"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Boş Durum -->
      <div v-if="services.length === 0" class="text-center py-12 bg-gray-50 rounded-lg">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 mx-auto text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
        </svg>
        <p class="mt-4 text-lg text-gray-600">Henüz hizmet eklenmemiş</p>
        <p class="text-gray-500">Yukarıdaki "Yeni Hizmet" butonuna tıklayarak başlayın</p>
      </div>
    </div>
  </div>
</template>
