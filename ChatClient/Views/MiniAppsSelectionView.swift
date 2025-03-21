import SwiftUI

struct MiniAppsSelectionView: View {
    @Binding var selectedMiniApps: [MiniApp]
    
    var body: some View {
        MiniAppsView(selectedMiniApps: $selectedMiniApps)
    }
}

struct MiniAppsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MiniAppsSelectionView(selectedMiniApps: .constant([]))
    }
}
