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
      accepted_types: [],
      input_type: :url,
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

  # ── User-facing information architecture (Sprint 2) ────────────────────────
  # One group per tool, using language office users understand. Ordered.
  GROUPS = {
    "PDF Tools"     => %w[merge_pdf split_pdf compress_pdf rotate_pdf protect_pdf unlock_pdf watermark_pdf redact_pdf],
    "Convert"       => %w[docx_to_pdf xlsx_to_pdf pptx_to_pdf images_to_pdf webpage_to_pdf pdf_to_docx pdf_to_images pdf_to_text],
    "Images"        => %w[heic_to_jpg heic_to_png webp_to_jpg webp_to_png jpg_to_png png_to_jpg],
    "Scan & OCR"    => %w[ocr_pdf],
    "AI Documents"  => %w[summarize_pdf ai_translate_pdf ai_generate_docx ai_generate_pptx]
  }.freeze

  GROUP_ICONS = {
    "PDF Tools"    => "picture_as_pdf",
    "Convert"      => "sync_alt",
    "Images"       => "image",
    "Scan & OCR"   => "document_scanner",
    "AI Documents" => "auto_awesome"
  }.freeze

  def self.group_names
    GROUPS.keys
  end

  def self.group_for(tool_id)
    GROUPS.find { |_name, ids| ids.include?(tool_id) }&.first || "Other"
  end

  # Ordered { group_name => [tool, ...] } for browsing.
  def self.groups
    GROUPS.each_with_object({}) do |(name, ids), acc|
      acc[name] = ids.filter_map { |id| find(id) }
    end
  end

  # Compact index for the client-side "identify my file" homepage uploader.
  # Only file-accepting tools (excludes prompt/URL tools).
  def self.file_tool_index
    tools.filter_map do |t|
      next if t[:input_type] == :prompt || Array(t[:accepted_types]).empty?
      {
        id:       t[:id],
        name:     t[:name],
        icon:     t[:icon],
        category: group_for(t[:id]),
        accepts:  t[:accepted_types],
        exts:     t[:accepted_types].flat_map { |m| Array(Marcel::TYPE_EXTS[m]) }.uniq
      }
    end
  end

  # ── Tool-specific options as DATA (Sprint 2.6) ─────────────────────────────
  # The tool page renders these declaratively — no per-tool markup branches.
  # Each option: { key:, label:, type: (:select/:text/:number/:password),
  #   choices: [[label,value]], default:, hint:, placeholder:, required:, half:,
  #   group:, target: (extra stimulus target on the field) }.
  PAGE_LAYOUT = [
    { key: :page_size, label: "Page size", type: :select, half: true, group: "Page layout",
      choices: [["Keep original", ""], ["A4 (International)", "A4"], ["A3 (Large)", "A3"], ["US Letter", "Letter"], ["US Legal", "Legal"]] },
    { key: :page_orientation, label: "Orientation", type: :select, half: true, group: "Page layout",
      choices: [["Keep original", ""], ["Portrait", "portrait"], ["Landscape", "landscape"]] }
  ].freeze

  TOOL_OPTIONS = {
    "docx_to_pdf" => PAGE_LAYOUT,
    "xlsx_to_pdf" => PAGE_LAYOUT,
    "pptx_to_pdf" => PAGE_LAYOUT,
    "images_to_pdf" => PAGE_LAYOUT + [
      { key: :fit_mode, label: "Fit mode", type: :select, half: true, group: "Image placement", default: "fit",
        choices: [["Fit to page (keep ratio)", "fit"], ["Centre (original size)", "center"], ["Stretch to fill", "stretch"]] },
      { key: :margin, label: "Page margin", type: :select, half: true, group: "Image placement", default: "0",
        choices: [["None", "0"], ["Small", "20"], ["Normal", "40"], ["Wide", "72"]] }
    ],
    "compress_pdf" => [
      { key: :quality, label: "Compression level", type: :select, default: "ebook", hint: "Higher quality means a larger file.",
        choices: [["Smallest file (72 dpi)", "screen"], ["Balanced (150 dpi)", "ebook"], ["High quality (300 dpi)", "printer"], ["Best quality (300 dpi + colour)", "prepress"]] }
    ],
    "pdf_to_images" => [
      { key: :dpi, label: "Resolution", type: :select, half: true, group: "Image settings", default: "150",
        choices: [["72 dpi — web / preview", "72"], ["150 dpi — standard", "150"], ["300 dpi — print", "300"]] },
      { key: :image_format, label: "Output format", type: :select, half: true, group: "Image settings", default: "jpg",
        choices: [["JPG (smaller)", "jpg"], ["PNG (transparency)", "png"]] }
    ],
    "ocr_pdf" => [
      { key: :language, label: "Document language", type: :select, default: "eng",
        choices: [["English", "eng"], ["Spanish", "spa"], ["French", "fra"], ["German", "deu"], ["Portuguese", "por"], ["Italian", "ita"], ["Chinese (Simplified)", "chi_sim"], ["Japanese", "jpn"], ["Arabic", "ara"]] }
    ],
    "rotate_pdf" => [
      { key: :rotation, label: "Rotation", type: :select,
        choices: [["90° clockwise", "90"], ["180°", "180"], ["270° clockwise", "270"]] }
    ],
    "protect_pdf" => [
      { key: :password, label: "Encryption password", type: :password, required: true, target: "passwordInput",
        placeholder: "Choose a strong password", hint: "You'll need this password to open the PDF afterwards." }
    ],
    "unlock_pdf" => [
      { key: :password, label: "Current password", type: :password, required: true, target: "passwordInput",
        placeholder: "The PDF's current password" }
    ],
    "watermark_pdf" => [
      { key: :watermark, label: "Watermark text", type: :text, default: "CONFIDENTIAL", placeholder: "e.g. CONFIDENTIAL, DRAFT", group: "Watermark" },
      { key: :watermark_position, label: "Position", type: :select, half: true, group: "Watermark", default: "diagonal",
        choices: [["Diagonal (centre)", "diagonal"], ["Centre", "center"], ["Header (top)", "header"], ["Footer (bottom)", "footer"]] },
      { key: :opacity, label: "Opacity", type: :select, half: true, group: "Watermark", default: "15",
        choices: [["Light (10%)", "10"], ["Standard (15%)", "15"], ["Medium (25%)", "25"], ["Bold (40%)", "40"]] }
    ],
    "ai_translate_pdf" => [
      { key: :target_language, label: "Translate to", type: :select, default: "es",
        choices: [["Spanish", "es"], ["French", "fr"], ["German", "de"], ["Portuguese", "pt"], ["Italian", "it"], ["Dutch", "nl"], ["Polish", "pl"], ["Russian", "ru"], ["Chinese (Simplified)", "zh"], ["Japanese", "ja"], ["Arabic", "ar"], ["Hindi", "hi"], ["Korean", "ko"], ["Turkish", "tr"], ["English", "en"]] }
    ],
    "ai_generate_pptx" => [
      { key: :slide_count, label: "Slides", type: :select, half: true, group: "Presentation", default: "8",
        choices: [["5 slides", "5"], ["8 slides", "8"], ["10 slides", "10"], ["15 slides", "15"]] },
      { key: :tone, label: "Tone", type: :select, half: true, group: "Presentation", default: "professional",
        choices: [["Professional", "professional"], ["Executive / board", "executive"], ["Creative", "creative"], ["Educational", "educational"], ["Sales pitch", "persuasive sales pitch"]] },
      { key: :audience, label: "Target audience", type: :text, placeholder: "e.g. C-suite executives, students", group: "Presentation" }
    ],
    "ai_generate_docx" => [
      { key: :doc_type, label: "Document type", type: :select, half: true, group: "Document", default: "report",
        choices: [["Business report", "report"], ["Proposal", "proposal"], ["Cover letter", "cover letter"], ["Executive summary", "executive summary"], ["Policy document", "policy document"], ["Article", "article"], ["Research brief", "research brief"]] },
      { key: :tone, label: "Tone", type: :select, half: true, group: "Document", default: "professional",
        choices: [["Professional", "professional"], ["Formal", "formal"], ["Friendly", "friendly"], ["Persuasive", "persuasive"], ["Academic", "academic"]] },
      { key: :page_count, label: "Approximate length", type: :select, group: "Document", default: "3",
        choices: [["1 page", "1"], ["2–3 pages", "3"], ["5 pages", "5"], ["10 pages", "10"]] }
    ],
    "split_pdf" => [
      { key: :from_page, label: "From page", type: :number, half: true, placeholder: "1", group: "Page range" },
      { key: :to_page, label: "To page", type: :number, half: true, placeholder: "Last", group: "Page range" }
    ],
    "summarize_pdf" => [
      { key: :page_count, label: "Summary length", type: :select, half: true, group: "Summary", default: "3",
        choices: [["Brief (1 page)", "1"], ["Standard (2–3 pages)", "3"], ["Detailed (5 pages)", "5"]] },
      { key: :tone, label: "Tone", type: :select, half: true, group: "Summary", default: "professional",
        choices: [["Professional", "professional"], ["Academic", "academic"], ["Simple & clear", "simple"], ["Executive briefing", "executive"]] }
    ],
    "merge_pdf" => [
      { key: :page_size, label: "Output page size", type: :select, default: "",
        choices: [["Keep original sizes", ""], ["Standardise to A4", "A4"], ["Standardise to US Letter", "Letter"]] }
    ]
  }.tap do |opts|
    quality = [{ key: :quality, label: "Output quality", type: :select, default: "90", hint: "Higher quality means a larger file.",
                 choices: [["Maximum (largest file)", "100"], ["High", "90"], ["Balanced", "75"], ["Compressed", "60"]] }]
    %w[jpg_to_png png_to_jpg heic_to_jpg webp_to_jpg].each { |id| opts[id] = quality }
  end.freeze

  def self.options_for(tool_id)
    TOOL_OPTIONS.fetch(tool_id, [])
  end

  # ── Semantic search aliases (Sprint 2.6) ───────────────────────────────────
  # Everyday phrasings mapped to tool ids so users don't need our terminology.
  # Deterministic — no LLM. Consumed client-side by the search index.
  SEARCH_ALIASES = {
    "compress_pdf"  => ["make pdf smaller", "reduce pdf size", "shrink pdf", "compress document", "smaller file"],
    "merge_pdf"     => ["combine documents", "join pdf", "combine pdf", "put pdfs together", "merge files"],
    "split_pdf"     => ["separate pdf pages", "extract pages", "break pdf apart", "split document"],
    "ocr_pdf"       => ["scan to text", "searchable scan", "read scanned document", "make scan searchable", "text recognition"],
    "images_to_pdf" => ["photo to pdf", "picture to pdf", "jpg to pdf", "images into pdf", "convert photos to pdf"],
    "pdf_to_images" => ["pdf pages as pictures", "pdf to jpg", "export pdf pages", "pdf to png"],
    "pdf_to_docx"   => ["pdf to editable", "edit pdf in word", "pdf to word document"],
    "docx_to_pdf"   => ["word to pdf", "doc to pdf", "save word as pdf"],
    "protect_pdf"   => ["password protect pdf", "encrypt pdf", "lock pdf", "secure pdf"],
    "unlock_pdf"    => ["remove pdf password", "decrypt pdf", "open locked pdf"],
    "watermark_pdf" => ["add watermark", "stamp confidential", "mark as draft"],
    "heic_to_jpg"   => ["iphone photo to jpg", "convert heic", "heic to jpeg"],
    "summarize_pdf" => ["summarise document", "tldr pdf", "shorten document"],
    "ai_translate_pdf" => ["translate document", "translate pdf to spanish", "translate pdf"]
  }.freeze

  def self.search_terms(tool_id)
    SEARCH_ALIASES.fetch(tool_id, [])
  end
end
