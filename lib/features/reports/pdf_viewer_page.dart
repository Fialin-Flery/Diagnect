import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:diagnect/app/theme/app_colors.dart';

class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  final String filePath;
  final String title;

  @override
  Widget build(
      BuildContext context,
      ) {
    final file =
    File(filePath);

    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style:
          const TextStyle(
            color:
            AppColors.primaryText,
            fontSize: 19,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body: FutureBuilder<bool>(
        future: file.exists(),
        builder:
            (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.data != true) {
            return const Center(
              child: Padding(
                padding:
                EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .error_outline_rounded,
                      size: 52,
                      color:
                      AppColors.error,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'PDF file not found.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        AppColors
                            .primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SfPdfViewer.file(
            file,
          );
        },
      ),
    );
  }
}