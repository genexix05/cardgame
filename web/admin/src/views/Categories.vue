<template>
  <div class="categories-view">
    <!-- Encabezado -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Gestión de Categorías</h1>
        <p class="text-gray-600 mt-1">Administra las categorías de las cartas</p>
      </div>
      <button class="btn-primary" @click="showNewCategoryModal = true">
        <i class="fas fa-plus-circle mr-2"></i>Nueva Categoría
      </button>
    </div>

    <!-- Lista de categorías -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="error" class="bg-red-50 border-l-4 border-red-400 p-4 mb-6">
      <div class="flex">
        <div class="flex-shrink-0">
          <i class="fas fa-exclamation-circle text-red-400"></i>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-700">{{ error }}</p>
        </div>
        <div class="ml-auto pl-3">
          <button class="btn-outline-danger" @click="loadCategories">Reintentar</button>
        </div>
      </div>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="category in categories" :key="category.id" class="card shadow-sm">
        <div class="card-body">
          <div class="flex justify-between items-start">
            <h5 class="card-title">{{ category.name }}</h5>
            <div class="flex space-x-2">
              <button class="btn-outline-primary btn-sm" @click="editCategory(category)">
                <i class="fas fa-edit"></i>
              </button>
              <button class="btn-outline-danger btn-sm" @click="confirmDelete(category)">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
          <p class="text-gray-600 mt-2">{{ category.description || 'Sin descripción' }}</p>
          <div class="mt-4">
            <span class="badge bg-primary">
              {{ category.cardCount || 0 }} cartas
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal para nueva/editar categoría -->
    <div v-if="showNewCategoryModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">{{ isEditing ? 'Editar' : 'Nueva' }} Categoría</h5>
          <button class="modal-close" @click="closeModal">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="saveCategory">
            <div class="mb-4">
              <label for="categoryName" class="form-label">Nombre *</label>
              <input 
                type="text" 
                class="form-control" 
                id="categoryName" 
                v-model="categoryData.name" 
                required
                :class="{'is-invalid': formErrors.name}"
              >
              <div class="invalid-feedback" v-if="formErrors.name">
                {{ formErrors.name }}
              </div>
            </div>
            
            <div class="mb-4">
              <label for="categoryDescription" class="form-label">Descripción</label>
              <textarea 
                class="form-control" 
                id="categoryDescription" 
                v-model="categoryData.description" 
                rows="3"
              ></textarea>
            </div>
            
            <div class="alert alert-danger" v-if="submitError">
              {{ submitError }}
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button class="btn-outline-secondary" @click="closeModal">Cancelar</button>
          <button class="btn-primary" @click="saveCategory" :disabled="isSubmitting">
            {{ isEditing ? 'Guardar' : 'Crear' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal de confirmación para eliminar -->
    <div v-if="showDeleteModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Confirmar Eliminación</h5>
          <button class="modal-close" @click="showDeleteModal = false">&times;</button>
        </div>
        <div class="modal-body">
          <p>¿Estás seguro de que deseas eliminar la categoría "{{ selectedCategory?.name }}"?</p>
          <p class="text-danger">Esta acción no se puede deshacer.</p>
        </div>
        <div class="modal-footer">
          <button class="btn-outline-secondary" @click="showDeleteModal = false">Cancelar</button>
          <button class="btn-danger" @click="deleteCategory" :disabled="isDeleting">
            Eliminar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { getFirestore, collection, getDocs, addDoc, updateDoc, deleteDoc, doc, query, where, getDocs as getDocsQuery } from 'firebase/firestore';

export default {
  name: 'CategoriesView',
  setup() {
    const store = useStore();
    const db = getFirestore();
    
    const loading = ref(false);
    const error = ref(null);
    const categories = ref([]);
    
    const showNewCategoryModal = ref(false);
    const showDeleteModal = ref(false);
    const isEditing = ref(false);
    const isSubmitting = ref(false);
    const isDeleting = ref(false);
    const submitError = ref('');
    const formErrors = reactive({});
    
    const selectedCategory = ref(null);
    
    const categoryData = reactive({
      name: '',
      description: '',
      cardCount: 0
    });
    
    const loadCategories = async () => {
      loading.value = true;
      error.value = null;
      try {
        const categoriesRef = collection(db, 'categories');
        const querySnapshot = await getDocs(categoriesRef);
        
        categories.value = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
      } catch (err) {
        console.error('Error al cargar categorías:', err);
        error.value = 'Error al cargar las categorías. Por favor, inténtalo de nuevo.';
      } finally {
        loading.value = false;
      }
    };
    
    const saveCategory = async () => {
      isSubmitting.value = true;
      submitError.value = '';
      formErrors.name = '';
      
      try {
        // Validación básica
        if (!categoryData.name.trim()) {
          formErrors.name = 'El nombre es requerido';
          return;
        }
        
        const categoriesRef = collection(db, 'categories');
        
        if (isEditing.value && selectedCategory.value) {
          // Actualizar categoría existente
          const categoryRef = doc(db, 'categories', selectedCategory.value.id);
          await updateDoc(categoryRef, {
            name: categoryData.name,
            description: categoryData.description
          });
        } else {
          // Crear nueva categoría
          await addDoc(categoriesRef, {
            name: categoryData.name,
            description: categoryData.description,
            cardCount: 0,
            createdAt: new Date()
          });
        }
        
        closeModal();
        loadCategories();
      } catch (err) {
        console.error('Error al guardar categoría:', err);
        submitError.value = 'Error al guardar la categoría. Por favor, inténtalo de nuevo.';
      } finally {
        isSubmitting.value = false;
      }
    };
    
    const editCategory = (category) => {
      isEditing.value = true;
      selectedCategory.value = category;
      categoryData.name = category.name;
      categoryData.description = category.description || '';
      showNewCategoryModal.value = true;
    };
    
    const confirmDelete = (category) => {
      selectedCategory.value = category;
      showDeleteModal.value = true;
    };
    
    const deleteCategory = async () => {
      if (!selectedCategory.value) return;
      
      isDeleting.value = true;
      try {
        // Verificar si hay cartas usando esta categoría
        const cardsRef = collection(db, 'cards');
        const q = query(cardsRef, where('categories', 'array-contains', selectedCategory.value.id));
        const querySnapshot = await getDocsQuery(q);
        
        if (!querySnapshot.empty) {
          submitError.value = 'No se puede eliminar la categoría porque hay cartas que la están usando.';
          return;
        }
        
        // Eliminar la categoría
        const categoryRef = doc(db, 'categories', selectedCategory.value.id);
        await deleteDoc(categoryRef);
        
        showDeleteModal.value = false;
        selectedCategory.value = null;
        loadCategories();
      } catch (err) {
        console.error('Error al eliminar categoría:', err);
        submitError.value = 'Error al eliminar la categoría. Por favor, inténtalo de nuevo.';
      } finally {
        isDeleting.value = false;
      }
    };
    
    const closeModal = () => {
      showNewCategoryModal.value = false;
      isEditing.value = false;
      selectedCategory.value = null;
      categoryData.name = '';
      categoryData.description = '';
      submitError.value = '';
      formErrors.name = '';
    };
    
    onMounted(() => {
      loadCategories();
    });
    
    return {
      loading,
      error,
      categories,
      showNewCategoryModal,
      showDeleteModal,
      isEditing,
      isSubmitting,
      isDeleting,
      submitError,
      formErrors,
      selectedCategory,
      categoryData,
      loadCategories,
      saveCategory,
      editCategory,
      confirmDelete,
      deleteCategory,
      closeModal
    };
  }
};
</script>

<style scoped>
.categories-view {
  @apply p-6;
}

.card {
  @apply bg-white rounded-lg shadow-sm transition-all duration-300 hover:shadow-md;
}

.modal {
  @apply fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50;
}

.modal-content {
  @apply bg-white rounded-lg shadow-xl max-w-md w-full;
}

.modal-header {
  @apply flex justify-between items-center p-4 border-b;
}

.modal-body {
  @apply p-4;
}

.modal-footer {
  @apply flex justify-end space-x-3 p-4 border-t;
}

.modal-close {
  @apply text-gray-400 hover:text-gray-500;
}
</style> 