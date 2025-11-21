import SwiftUI

struct ListingCardView: View {
    enum Mode {
        case compact
        case primary
    }
    
    private var mode: Mode
    private var title: String
    private var realtorName: String
    private var listingTypeChip: String
    
    init(mode: Mode, title: String, realtorName: String, listingTypeChip: String) {
        self.mode = mode
        self.title = title
        self.realtorName = realtorName
        self.listingTypeChip = listingTypeChip
    }
    
    private var compactContent: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer()
        }
    }
    
    private var primaryContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title.weight(.semibold))
                .lineLimit(2)
            Text(realtorName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(listingTypeChip)
                .font(.caption)
                .padding(4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
    }
    
    var body: some View {
        Group {
            switch mode {
            case .compact:
                compactContent
            case .primary:
                primaryContent
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct ListingCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ListingCardView(mode: .compact, title: "Beautiful Family Home with Modern Amenities", realtorName: "John Doe", listingTypeChip: "For Sale")
            ListingCardView(mode: .primary, title: "Beautiful Family Home with Modern Amenities", realtorName: "John Doe", listingTypeChip: "For Sale")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
