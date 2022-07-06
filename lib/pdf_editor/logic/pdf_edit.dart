import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';

import '../bloc/edit_pdf_bloc.dart';

class PdfEdit {
  void savePdf({
    required EditPdfSuccess? state,
    required GlobalKey? key,
    required BuildContext? context,
  }) async {
    final pdfFile = pw.Document();
    final boundary =
        key!.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final image = await boundary?.toImage();
    final byteData = await image?.toByteData(format: ImageByteFormat.png);
    final imageBytes = byteData?.buffer.asUint8List();
    if (imageBytes != null) {
      for (var item in state!.list!) {
        pdfFile.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat(
              getSize(key).width,
              getSize(key).height,
            ),
            build: (context) {
              return pw.Container(
                padding: pw.EdgeInsets.zero,
                margin: pw.EdgeInsets.zero,
                width: getSize(key).width,
                height: getSize(key).height,
                decoration: pw.BoxDecoration(
                  image: pw.DecorationImage(
                    image: pw.MemoryImage(
                      item.isHaveQrCode! ? imageBytes : item.imageByte!,
                    ),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        );
      }
      Uint8List _file = await pdfFile.save();
      Navigator.pop(context!, {'pdf': _file});
    } else {}
  }

  Size getSize(GlobalKey key) {
    return key.currentContext!.size!;
  }

  void getPdfToImage({BuildContext? context, Uint8List? pdf}) async {
    List<QrCodePostion> _list = [];
    final document = await PdfDocument.openData(pdf!);

    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      _list.add(QrCodePostion(
        imageByte: pageImage!.bytes,
        dx: 100,
        dy: 100,
        isHaveQrCode: false,
      ));
      await page.close();
    }
    BlocProvider.of<EditPdfBloc>(context!).add(InitilPdf(list: _list));
    document.close();
  }
}