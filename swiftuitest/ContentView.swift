//
//  ContentView.swift
//  swiftuitest
//
//  Created by V8 on 11/1/22.
//

import SwiftUI
import Photos

class ViewModel : ObservableObject
{
    var isFirstTimeLoading = true
}

struct TopBaView : View
{
    var body: some View
    {
        HStack {
            Group {
                Text("Album")
                    .padding()
                Button("Btn")
                {
                    
                }
            }
            
            Spacer()
        }
        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
               idealWidth: .infinity,
               maxWidth: .infinity,
               minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
               idealHeight: 54,
               maxHeight: 54,
               alignment: .top)
    }
}

struct PhotoImageView : View
{
    var asset : PHAsset
    
    @State private var image : UIImage?
    @EnvironmentObject var customPhoto : CustomPhotoPicker
    
    var body: some View
    {
        Group {
            if let img = image
            {
                Image(uiImage: img)
            } else
            {
                Rectangle()
                    .background(Color.red)
            }
        }
        .onAppear(perform: {
            customPhoto.requestAsset(asset: asset) { (img) in
                self.image = img
            }
        })
    }
}

struct ContentView: View {
    private let numColumns = 3
    private let cellWidth: CGFloat
    private let cellHeight: CGFloat
    
    private var colummns: [GridItem]
    @StateObject private var viewModel = ViewModel()
    @StateObject private var customPhoto = CustomPhotoPicker()
    
    init() {
        let screenSize = UIScreen.main.bounds.size
        cellWidth = screenSize.width / CGFloat(numColumns)
        cellHeight = cellWidth
                
        colummns = [GridItem]()
        for _ in 1 ... numColumns {
            colummns.append(GridItem(.fixed(cellWidth)))
        }

    }
    
    var body: some View {
        VStack{
            TopBaView()
            ScrollView
            {
                LazyVGrid(columns: colummns, alignment: .center, spacing: 1, pinnedViews: [], content: {
                    ForEach(customPhoto.assets, id: \.self) {asset in
                        PhotoImageView(asset: asset)
                    }
//                    ForEach(0..<$customPhoto.assets.count) { idx in
//                        let asset = customPhoto.assets[idx]
//
//                    }
//                    ForEach(customPhoto.test, id: \.self) { asset in
//                        Text(asset)
//                            .onAppear(perform: {
//                                print("\(asset)")
//                            })
//                    }
                })
            }
            .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
                   idealWidth: .infinity,
                   maxWidth: .infinity,
                   minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
                   idealHeight: .infinity,
                   maxHeight: .infinity,
                   alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }
        .environmentObject(customPhoto)
        .onAppear(perform: {
            if (viewModel.isFirstTimeLoading)
            {
                viewModel.isFirstTimeLoading = false
                
                customPhoto.cachingSize = CGSize(width: cellWidth, height: cellHeight)
                customPhoto.grantPermission { (status) in
                    if (status == .authorized || status == .limited)
                    {
                        customPhoto.fetchAssets()
//                        customPhoto.fetchCollections()
//                        for idx in 1...1000 {
//                            customPhoto.test.append("\(idx)")
//                        }
                    }
                }
            }
            
        })
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
