import SwiftUI

// 1. Definir un PreferenceKey personalizado para transmitir el valor de opacidad
struct OpacityPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 1.0

    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

// 2. Vista hija que establecerá la opacidad de la vista padre
struct ChildView: View {
    @State private var sliderValue: Double = 1.0

    var body: some View {
        VStack {
            Text("Vista Hija")
                .font(.headline)
                .padding()

            Slider(value: $sliderValue, in: 0...1)
                .padding(.horizontal)

            Text("Valor de opacidad: \(sliderValue, specifier: "%.2f")")
                .padding()

            // Aquí establecemos la preferencia que se propagará hacia arriba
            Color.blue
                .frame(height: 100)
                .cornerRadius(10)
                .padding()
                .preference(key: OpacityPreferenceKey.self, value: sliderValue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
}

// 3. Vista padre que lee la preferencia y aplica la opacidad
struct ParentView: View {
    @State private var parentOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Fondo con la opacidad controlada por la vista hija
            Color.red
                .opacity(parentOpacity)
                .edgesIgnoringSafeArea(.all)

            ChildView()
                .frame(width: 300)
                // Observamos los cambios en la preferencia
                .onPreferenceChange(OpacityPreferenceKey.self) { newOpacity in
                    withAnimation {
                        parentOpacity = newOpacity
                    }
                }
        }
    }
}

// Vista para mostrar en el Preview
struct PreferenceKeyDemo: View {
    var body: some View {
        ParentView()
    }
}

#Preview {
    PreferenceKeyDemo()
}
