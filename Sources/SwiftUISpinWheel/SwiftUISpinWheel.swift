import SwiftUI

@available(iOS 14.0, *)
/// A circle view that divided into color sectors and can spin.
public struct WheelView<Data, ID, Label>: View where Data: RandomAccessCollection, ID: Hashable, Label: View  {

    private typealias EnumerationElement = EnumeratedSequence<Data>.Element

    // MARK: - Private Properties

    @Binding private var selectedIndex: Int

    @State private var startingRotation: Double = 0
    @State private var translation: Double = 0
    @State private var isStartedSpinnig: Bool = false

    private let data: Data
    private let idKeypath: KeyPath<Data.Element, ID>
    private let action: ((Data.Element) -> Void)?
    private let label: ((Int) -> (Label))?
    private let manualSpining: (() -> (Int))?
    private let colors: [Color]

    private var enumeratedData: [EnumerationElement] {
        return Array (data.enumerated())
    }

    private var enumeratedDataIDKeyPath: KeyPath<EnumerationElement, ID> {
        return (\EnumerationElement.element).appending(path: idKeypath)
    }

    private var sliceSize: Angle {
        return .degrees(360 / Double (data.count))
    }

    // MARK: - Initializer

    /// Initializer view.
    /// - Parameters:
    ///   - data: Data for choosing wheel.
    ///   - selectedIndex: Selected index sector by wheel.
    ///   - manualSpining: Closure for setting select sector index when the user spin wheel someself.
    ///   - colors: Colors sectors of wheel.
    ///   - label: Closure for setting view on each sector. Default set text label with index if you dont set.
    ///   - action: Closure receive information about selected sector index.
    public init(
        _ data: Data,
        selectedIndex: Binding<Int> = .constant(0),
        manualSpining: (() -> (Int))? = nil,
        colors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .pink],
        label: ((Int) -> (Label))? = nil,
        action: ((Data.Element) -> Void)? = nil
    ) where Data.Element: Identifiable, ID == Data.Element.ID {
        self.data = data
        self._selectedIndex = selectedIndex
        self.manualSpining = manualSpining
        self.colors = colors
        self.label = label
        self.idKeypath = \.id
        self.action = action
    }

    /// Initializer view.
    /// - Parameters:
    ///   - data: Data for choosing wheel.
    ///   - id: The key path to the provided data’s identifier.
    ///   - selectedIndex: Selected index sector by wheel.
    ///   - manualSpining: Closure for setting select sector index when the user spin wheel someself.
    ///   - colors: Colors sectors of wheel.
    ///   - label: Closure for setting view on each sector. Default set text label with index if you dont set.
    ///   - action: Closure receive information about selected sector index.
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        selectedIndex: Binding<Int> = .constant(0),
        manualSpining: (() -> (Int))? = nil,
        colors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .pink],
        label: ((Int) -> (Label))? = nil,
        action: ((Data.Element) -> Void)? = nil
    ) {
        self.data = data
        self.idKeypath = id
        self._selectedIndex = selectedIndex
        self.manualSpining = manualSpining
        self.colors = colors
        self.label = label
        self.action = action
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.gray)
                    .shadow(color: Color.black.opacity(0.3),
                            radius: geometry.size.height / 15,
                            x:0, y: 0)
                ForEach(enumeratedData, id: enumeratedDataIDKeyPath) { (index, item) in
                    let color = colors[index % colors.count]
                    let includeOverlap = !(index == data.count - 1)
                    WheelSlice(size: sliceSize, color: color, includeOverlap: includeOverlap) {
                        if let label = label {
                            label(index)
                        } else {
                            Text ("\(index + 1)")
                                .font (.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor (.white)
                        }
                    }
                    .rotationEffect(sliceSize * Double (index))
                }
                .rotationEffect(.degrees (startingRotation) + .degrees (translation / geometry.size.height * 180))

                WheelPointer()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity (0.3),
                            radius: geometry.size.height / 50,
                            x: 0, y: 0)
                    .frame(width: geometry.size.width / 12, height: geometry.size.height / 6, alignment: .center)
            }
            .onChange(of: selectedIndex, perform: { value in
                guard
                    !isStartedSpinnig,
                    value < data.count
                else { return }

                isStartedSpinnig = true

                rotateWheel(
                    predictedEndTranslationHeight: Double.random(in: 1500...2500),
                    translationHeight: 0,
                    height: geometry.size.height,
                    selectedIndex: value)
            })
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isStartedSpinnig else { return }

                        startingRotation = startingRotation.truncatingRemainder(dividingBy: 360)
                        translation = value.translation.height
                    }
                    .onEnded { value in
                        guard !isStartedSpinnig else { return }

                        isStartedSpinnig = true

                        if let selectedIndex = manualSpining?() {
                            rotateWheel(
                                predictedEndTranslationHeight: Double.random(in: 1500...2500),
                                translationHeight: value.translation.height,
                                height: geometry.size.height,
                                selectedIndex: selectedIndex
                            )
                            return
                        }

                        rotateWheel(
                            predictedEndTranslationHeight: value.predictedEndTranslation.height,
                            translationHeight: value.translation.height,
                            height: geometry.size.height
                        )
                    }
                )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Private Methods

    private func rotateWheel(
        predictedEndTranslationHeight: Double,
        translationHeight: Double,
        height: CGFloat,
        selectedIndex: Int? = nil
    ) {
        let velocity = abs(predictedEndTranslationHeight - translationHeight) / 400
        let angularTranslation = (predictedEndTranslationHeight / height) * CGFloat(180)
        let desiredEndRotation = startingRotation + angularTranslation * (1 + velocity)
        var nearestStop = round(desiredEndRotation / sliceSize.degrees) * sliceSize.degrees
        var sliceIndex = (data.count - Int(round(desiredEndRotation.truncatingRemainder(dividingBy: 360) / sliceSize.degrees))) % data.count
        _ = sliceIndex

        if let selectedIndex = selectedIndex {
            let newIndex = selectedIndex - sliceIndex
            nearestStop -= sliceSize.degrees * Double(newIndex)
            sliceIndex = selectedIndex
        }

        let (animation, duration) = animation(for: velocity)

        withAnimation(animation) {
            startingRotation = nearestStop
            translation = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            let index = data.index(data.startIndex, offsetBy: sliceIndex)
            action?(data[index])
            isStartedSpinnig = false
        }

    }

    private func animation(for velocity: Double) -> (Animation, Double) {
        let duration = max(velocity, 0.2)
        return (Animation.easeOut(duration: duration), duration)
    }

}

@available(iOS 14.0, *)
struct WheelView_Previews: PreviewProvider {
    static let items: [String] = ["item1", "item2", "item3", "item4", "item5", "item6"]
    static var previews: some View {
        WheelView(
            items,
            id: \.self,
            label: { index in
                Text (items[index])
                    .font (.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor (.white)
            }
        ) { item in
            print(item)
        }.padding()
    }
}
