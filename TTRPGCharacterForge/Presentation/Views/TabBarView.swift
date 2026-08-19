//
//  TabBarView.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 12-11-25.
//

import SwiftUI

struct TabBarView: View {

    var tabbarItems: [String]
    @Binding var selectedIndex: Int
    @Namespace private var menuItemTransition

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(tabbarItems.indices, id: \.self) { index in

                        TabbarItem(name: tabbarItems[index], isActive: selectedIndex == index, namespace: menuItemTransition)
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedIndex = index
                                }
                            }
                        
                    }
                }
            }
            .onChange(of: selectedIndex) { _, index in
                withAnimation(.easeInOut) {
                    scrollView.scrollTo(index, anchor: .center)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(25)

        }
    }
}

#Preview {
    TabBarView(tabbarItems: ["foo", "bar", "biz"], selectedIndex: .constant(0))
}
