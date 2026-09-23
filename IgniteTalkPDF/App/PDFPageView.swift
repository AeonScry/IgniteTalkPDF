import PDFKit
import SwiftUI

struct PDFPageView: NSViewRepresentable {
    let document: PDFDocument
    let pageIndex: Int

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.displayMode = .singlePage
        view.displayDirection = .horizontal
        view.displaysPageBreaks = false
        view.autoScales = true
        view.backgroundColor = .black
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        if view.document !== document {
            view.document = document
        }
        guard let page = document.page(at: pageIndex), view.currentPage !== page else {
            return
        }
        view.go(to: page)
    }
}
