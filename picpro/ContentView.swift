//
//  ContentView.swift
//  picpro
//
//  Created by mica dai on 2024/7/15.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // @State 就是一种双向绑定的方式，代码中如果修改。那么界面中对应也会修改
    @State private var message = "Hello, World!"
    
    @State private var selectedImage: NSImage? = nil
    @State private var isImagePickerPresented: Bool = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                    } label: {
                        Text(item.timestamp!, formatter: itemFormatter)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
        
        
        
        VStack {
            Text("Welcome to the Image Upload App")
                .font(.largeTitle)
                .padding()
            
            UploadImageView()
            
            Spacer()
        }
        .padding()
        
        
        //        VStack {
        //            if let selectedImage = selectedImage {
        //                Image(nsImage: selectedImage)
        //                    .resizable()
        //                    .scaledToFit()
        //                    .frame(width: 300, height: 300)
        //                    .clipShape(RoundedRectangle(cornerRadius: 10))
        //                    .shadow(radius: 10)
        //                    .padding()
        //            } else {
        //                Image(systemName: "photo")
        //                    .resizable()
        //                    .scaledToFit()
        //                    .frame(width: 300, height: 300)
        //                    .foregroundColor(.gray)
        //                    .padding()
        //            }
        //
        //            Button(action: {
        //                isImagePickerPresented = true
        //            }) {
        //                Text("Select Image")
        //                    .foregroundColor(.white)
        //                    .padding()
        //                    .background(Color.blue)
        //                    .cornerRadius(10)
        //            }
        //            .padding()
        //            .sheet(isPresented: $isImagePickerPresented) {
        //                ImagePicker(selectedImage: $selectedImage, isPresented: $isImagePickerPresented)
        //            }
        //        }
        
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
