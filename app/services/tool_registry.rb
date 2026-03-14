class ToolRegistry
  cattr_accessor :tools
  
  self.tools = [
    {
      id: 'merge_pdf',
      name: 'Merge PDF',
      description: 'Combine multiple PDF documents into one single file.',
      category: 'PDF Tools',
      icon: 'call_merge',
      accepts_multiple: true,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::MergePdf'
    },
    {
      id: 'split_pdf',
      name: 'Split PDF',
      description: 'Extract pages from your PDF into a zip file.',
      category: 'PDF Tools',
      icon: 'call_split',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::SplitPdf'
    },
    {
      id: 'compress_pdf',
      name: 'Compress PDF',
      description: 'Reduce the file size of your PDF document.',
      category: 'PDF Tools',
      icon: 'compress',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::CompressPdf'
    },
    {
      id: 'docx_to_pdf',
      name: 'Word to PDF',
      description: 'Convert DOCX files to PDF documents exactly as they appear.',
      category: 'PDF Tools',
      icon: 'description',
      accepts_multiple: false,
      accepted_types: ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword'],
      class_name: 'Tools::DocxToPdf'
    },
    {
      id: 'pdf_to_docx',
      name: 'PDF to Word',
      description: 'Convert your PDF into an editable Word document.',
      category: 'PDF Tools',
      icon: 'picture_as_pdf',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::PdfToDocx'
    },
    {
      id: 'protect_pdf',
      name: 'Protect PDF',
      description: 'Add a password to encrypt your PDF securely.',
      category: 'PDF Tools',
      icon: 'lock',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::ProtectPdf'
    },
    {
      id: 'unlock_pdf',
      name: 'Unlock PDF',
      description: 'Remove password protection from encrypted PDFs.',
      category: 'PDF Tools',
      icon: 'lock_open',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::UnlockPdf'
    },
    {
      id: 'images_to_pdf',
      name: 'Images to PDF',
      description: 'Combine JPG or PNG files into a clean PDF document.',
      category: 'Image Tools',
      icon: 'imagesmode',
      accepts_multiple: true,
      accepted_types: ['image/jpeg', 'image/png'],
      class_name: 'Tools::ImagesToPdf'
    },
    {
      id: 'pdf_to_images',
      name: 'PDF to Images',
      description: 'Extract pages of a PDF into individual JPEG files.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::PdfToImages'
    },
    {
      id: 'webpage_to_pdf',
      name: 'Webpage to PDF',
      description: 'Convert any public URL layout perfectly into a PDF.',
      category: 'PDF Tools',
      icon: 'language',
      accepts_multiple: false,
      accepted_types: [], # We will need to handle this specially in the UI, or just create a specific URL input
      class_name: 'Tools::WebpageToPdf'
    },
    {
      id: 'ocr_pdf',
      name: 'OCR PDF',
      description: 'Make a scanned image-based PDF fully searchable.',
      category: 'PDF Tools',
      icon: 'document_scanner',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::OcrPdf'
    },
    {
      id: 'redact_pdf',
      name: 'Redact PDF',
      description: 'Flatten files to securely drop hidden text blocks.',
      category: 'PDF Tools',
      icon: 'ink_eraser',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::RedactPdf'
    },
    {
      id: 'summarize_pdf',
      name: 'Summarize PDF (AI)',
      description: 'Use AI to instantly condense massive documents into executive summaries.',
      category: 'AI Tools',
      icon: 'auto_awesome',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::SummarizePdf'
    },
    {
      id: 'heic_to_jpg',
      name: 'HEIC to JPG',
      description: 'Convert HEIC images to standard JPG format.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['image/heic'],
      class_name: 'Tools::HeicToJpg'
    },
    {
      id: 'heic_to_png',
      name: 'HEIC to PNG',
      description: 'Convert HEIC images to transparent PNG format.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['image/heic'],
      class_name: 'Tools::HeicToPng'
    },
    {
      id: 'webp_to_jpg',
      name: 'WEBP to JPG',
      description: 'Convert WEBP images to standard JPG format.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['image/webp'],
      class_name: 'Tools::WebpToJpg'
    },
    {
      id: 'webp_to_png',
      name: 'WEBP to PNG',
      description: 'Convert WEBP images to transparent PNG format.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['image/webp'],
      class_name: 'Tools::WebpToPng'
    },
    {
      id: 'xlsx_to_pdf',
      name: 'Excel to PDF',
      description: 'Convert Excel spreadsheets (.xlsx, .xls) to PDF documents.',
      category: 'PDF Tools',
      icon: 'table_chart',
      accepts_multiple: false,
      accepted_types: [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-excel'
      ],
      class_name: 'Tools::XlsxToPdf'
    },
    {
      id: 'pptx_to_pdf',
      name: 'PowerPoint to PDF',
      description: 'Convert PowerPoint presentations (.pptx, .ppt) to PDF documents.',
      category: 'PDF Tools',
      icon: 'slideshow',
      accepts_multiple: false,
      accepted_types: [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/vnd.ms-powerpoint'
      ],
      class_name: 'Tools::PptxToPdf'
    },
    {
      id: 'rotate_pdf',
      name: 'Rotate PDF',
      description: 'Rotate all pages in a PDF by 90, 180, or 270 degrees.',
      category: 'PDF Tools',
      icon: 'rotate_right',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::RotatePdf'
    },
    {
      id: 'jpg_to_png',
      name: 'JPG to PNG',
      description: 'Convert JPG/JPEG images to PNG format with full quality.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['image/jpeg'],
      class_name: 'Tools::JpgToPng'
    },
    {
      id: 'png_to_jpg',
      name: 'PNG to JPG',
      description: 'Convert PNG images to JPG format, flattening transparency.',
      category: 'Image Tools',
      icon: 'image',
      accepts_multiple: false,
      accepted_types: ['image/png'],
      class_name: 'Tools::PngToJpg'
    },
    {
      id: 'pdf_to_text',
      name: 'PDF to Text',
      description: 'Extract all text content from a PDF into a plain .txt file.',
      category: 'PDF Tools',
      icon: 'text_snippet',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::PdfToText'
    },
    {
      id: 'ai_generate_pptx',
      name: 'AI Generate Presentation',
      description: 'Describe any topic and Claude AI will create a complete, beautifully styled PowerPoint presentation.',
      category: 'AI Tools',
      icon: 'slideshow',
      accepts_multiple: false,
      accepted_types: [],
      input_type: :prompt,
      class_name: 'Tools::AiGeneratePptx'
    },
    {
      id: 'ai_generate_docx',
      name: 'AI Generate Document',
      description: 'Describe any topic and Claude AI will write a fully structured professional Word document.',
      category: 'AI Tools',
      icon: 'edit_document',
      accepts_multiple: false,
      accepted_types: [],
      input_type: :prompt,
      class_name: 'Tools::AiGenerateDocx'
    },
    {
      id: 'watermark_pdf',
      name: 'Watermark PDF',
      description: 'Add a custom diagonal text watermark (e.g. CONFIDENTIAL, DRAFT) to every page.',
      category: 'PDF Tools',
      icon: 'branding_watermark',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::WatermarkPdf'
    },
    {
      id: 'ai_translate_pdf',
      name: 'AI Translate PDF',
      description: 'Translate a PDF document into 15 languages using Claude AI, preserving structure.',
      category: 'AI Tools',
      icon: 'translate',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::AiTranslatePdf'
    }
  ]

  def self.all
    tools
  end

  def self.find(tool_id)
    tools.find { |t| t[:id] == tool_id }
  end

  def self.categories
    tools.group_by { |t| t[:category] }
  end
end
