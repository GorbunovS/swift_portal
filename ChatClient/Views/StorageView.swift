import SwiftUI

struct StorageView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "all"
    @State private var showUploadDialog = false
    @State private var files: [StorageFile] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя часть с заголовком и кнопкой добавления
            HStack {
                Text("Хранилище файлов")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showUploadDialog = true
                }) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
            
            // Поиск и фильтры
            VStack(spacing: 12) {
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Поиск файлов", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Фильтры
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(title: "Все", filter: "all", selectedFilter: $selectedFilter)
                        FilterButton(title: "Документы", filter: "document", selectedFilter: $selectedFilter)
                        FilterButton(title: "Презентации", filter: "presentation", selectedFilter: $selectedFilter)
                        FilterButton(title: "Таблицы", filter: "spreadsheet", selectedFilter: $selectedFilter)
                        FilterButton(title: "Изображения", filter: "image", selectedFilter: $selectedFilter)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            
            // Заглушка
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "folder")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                
                Text("Функция хранилища в разработке")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .sheet(isPresented: $showUploadDialog) {
            UploadFileView()
        }
    }
}

struct FilterButton: View {
    let title: String
    let filter: String
    @Binding var selectedFilter: String
    
    var body: some View {
        Button(action: {
            selectedFilter = filter
        }) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(selectedFilter == filter ? Color.blue : Color(.systemGray6))
                .foregroundColor(selectedFilter == filter ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct StorageFile: Identifiable {
    let id: Int
    let name: String
    let type: String
    let size: String
    let createdAt: Date
    let ownerId: Int
}

struct UploadFileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSource = 0
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Выбор источника файла
                Picker("Источник", selection: $selectedSource) {
                    Text("Галерея").tag(0)
                    Text("Камера").tag(1)
                    Text("Файлы").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Информация
                VStack {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                        .padding()
                    
                    Text("Выберите файл для загрузки")
                        .font(.headline)
                    
                    Text("Поддерживаемые форматы: DOC, PDF, JPG, PNG, XLS, PPT")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                
                Spacer()
                
                // Кнопки действий
                VStack(spacing: 16) {
                    Button(action: {
                        // Имитация загрузки файла
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isLoading = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text("Выбрать файл")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isLoading)
                    
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationTitle("Загрузка файла")
        }
    }
}

struct StorageView_Previews: PreviewProvider {
    static var previews: some View {
        StorageView()
    }
} 