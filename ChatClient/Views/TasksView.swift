import SwiftUI

struct TasksView: View {
    var body: some View {
        VStack {
            Text("Страница задач")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("В разработке")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        TasksView()
    }
} 