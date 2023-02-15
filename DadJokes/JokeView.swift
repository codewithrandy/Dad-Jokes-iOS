//
//  JokeView.swift
//  DadJokes
//
//  Created by Randy McKown on 2/13/23.
//

import SwiftUI

struct JokeView: View {
    @State private var showingMenu = false
    @State var leftData = SliderData(side: .left)
    @State var rightData = SliderData(side: .right)
    
    @State var pageIndex = 0
    @State var topSlider = SliderDirection.right
    @State var sliderOffset: CGFloat = 0
    
    @State var jokes = [Joke]()
    @State var datafetched = false
        
    
    var body: some View {
        NavigationStack {
            if datafetched {
                ZStack {
                    content()
                    slider(data: $leftData)
                    slider(data: $rightData)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .task {
            await fetchData()
        }
    }
    
    
    func content() -> some View {
        return  ZStack {
            Rectangle().foregroundColor(Config.colors[pageIndex])
            VStack {
                Spacer()
                VStack {
                    Text(jokes[pageIndex].setup)
                        .font(.largeTitle)
                        .padding()
                    Text(jokes[pageIndex].punchline)
                        .font(.title)
                }
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                Spacer()
                HStack {
                    Button {
                        showingMenu.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .scaleEffect(2)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .sheet(isPresented: $showingMenu) {
                        CategoryView()
                    }
                    
                    Button {
                        showingMenu.toggle()
                    } label: {
                        Image(systemName: "square.grid.3x3.fill")
                            .scaleEffect(2)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .sheet(isPresented: $showingMenu) {
                        CategoryView()
                    }
                }
            }
            .padding(30)
        }
    }
    
    func fetchData() async {
        guard let url = URL(string: "https://dadjokes.randymckown.com/dadjokes/") else {
            print("bad url")
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decodedResponse = try? JSONDecoder().decode([Joke].self, from: data) {
                jokes = decodedResponse
            }
            datafetched = true
        } catch {
            print("Failed to fetch dad jokes")
        }
    }
    
    private func index(of data: SliderData) -> Int {
        let last = Config.colors.count - 1
        if data.side == .left {
            return pageIndex == 0 ? last : pageIndex - 1
            
        } else {
            return pageIndex == last ? 0 : pageIndex + 1
        }
    }
    
    private func swipe(data: Binding<SliderData>) {
        withAnimation() {
            data.wrappedValue = data.wrappedValue.final()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.pageIndex = self.index(of: data.wrappedValue)
            self.leftData = self.leftData.initial()
            self.rightData = self.rightData.initial()
            
            self.sliderOffset = 100
            withAnimation(.spring(dampingFraction: 0.5)) {
                self.sliderOffset = 0
            }
        }
    }
    
    func wave(data: Binding<SliderData>) -> some View {
        let gesture = DragGesture().onChanged {
            self.topSlider = data.wrappedValue.side
            data.wrappedValue = data.wrappedValue.drag(value: $0)
        }
        .onEnded {
            if data.wrappedValue.isCancelled(value: $0) {
                withAnimation(.spring(dampingFraction: 0.5)) {
                    data.wrappedValue = data.wrappedValue.initial()
                }
            } else {
                self.swipe(data: data)
            }
        }
        .simultaneously(with: TapGesture().onEnded {
            self.topSlider = data.wrappedValue.side
            self.swipe(data: data)
        })
        return WaveView(data: data.wrappedValue).gesture(gesture)
            .foregroundColor(Config.colors[index(of: data.wrappedValue)])
    }
    
    private func circle(radius: Double) -> Path {
        
        return Path { path in
            path.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        }
    }
    
    private func polyLine(_ values: Double...) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: values[0], y: values[1]))
            for i in stride(from: 2, to: values.count, by: 2) {
                path.addLine(to: CGPoint(x: values[i], y: values[i + 1]))
            }
        }
    }
    func  button(data: SliderData) -> some View {
        let arrowWidth = (data.side == .left ? 1 : -1) * Config.arrowWidth / 2
        let arrowHeight = Config.arrowHeight / 2
        
        return ZStack {
            circle(radius: Config.buttonRadius).stroke().opacity(0.2)
            polyLine(-arrowWidth, -arrowHeight, arrowWidth, 0, -arrowWidth, arrowHeight).stroke(Color.white, lineWidth: 2)
        }
        .offset(data.buttonOffset)
        .opacity(data.buttonOpacity)
    }
    
    func slider(data: Binding<SliderData>) -> some View {
        let value = data.wrappedValue
        
        return ZStack {
            wave(data: data)
            button(data: value)
        }
        .zIndex(topSlider == value.side ? 1 : 0)
        .offset(x: value.side == .left ? -sliderOffset : sliderOffset)
    }
}

struct JokeView_Previews: PreviewProvider {
    static var previews: some View {
        JokeView()
    }
}
