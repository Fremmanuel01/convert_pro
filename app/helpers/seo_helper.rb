module SeoHelper
  # Canonical host for absolute URLs (sitemap, canonical, OG). Overridable so
  # the same build works on staging/prod without hardcoding into templates.
  def canonical_host
    ENV.fetch("CANONICAL_HOST", "https://officedoctools.com").chomp("/")
  end

  # Absolute canonical URL for a path (query stripped — canonicals must be clean).
  def canonical_url(path = nil)
    path ||= request.path
    "#{canonical_host}#{path.split('?').first}"
  end

  def og_image_url
    "#{canonical_host}/og-image.png"
  end

  # Per-tool SEO bundle, generated from the registry so all 27 pages are covered
  # without hand-maintaining 27 metadata blocks. Refine individual tools later
  # by special-casing here.
  def tool_seo(tool)
    name = tool[:name]
    free = ConversionLimiter::FREE_LIMIT
    client = ToolsController::CLIENT_SIDE_IDS.include?(tool[:id])
    privacy = client ?
      "This tool runs entirely in your browser — your file never leaves your device." :
      "Files are processed over an encrypted connection and deleted automatically after processing."

    {
      title:       "#{name} Online — Free & Secure | OfficedocTools",
      description:  "#{tool[:description]} Free, fast and private — no signup needed. #{privacy}".squish.truncate(158),
      keywords:     ([name.downcase] + Array(ToolRegistry.search_terms(tool[:id]))).join(", "),
      intro:        "#{tool[:description]} #{name} is free to use with no software to install — it works right in your browser. #{privacy} Most files are ready in seconds.",
      faq: [
        ["Is #{name} free?",
         "Yes. #{name} is free to use — every account gets #{free} free conversions to start, and Pro unlocks unlimited conversions and larger files."],
        ["Do I need to create an account or install software?",
         "No. #{name} runs in your browser with nothing to download. You can start converting without an account."],
        ["Are my files safe?",
         privacy],
        ["How do I use #{name}?",
         "Add your file, choose any options for this tool, then process and download the result — usually in a few seconds."]
      ]
    }
  end

  # Renders a <script type="application/ld+json"> block from a Ruby hash.
  def json_ld(data)
    content_tag(:script, raw(data.to_json), type: "application/ld+json")
  end

  def breadcrumb_schema(crumbs)
    {
      "@context" => "https://schema.org",
      "@type"    => "BreadcrumbList",
      "itemListElement" => crumbs.each_with_index.map do |(label, url), i|
        { "@type" => "ListItem", "position" => i + 1, "name" => label, "item" => url }
      end
    }
  end

  def faq_schema(pairs)
    {
      "@context" => "https://schema.org",
      "@type"    => "FAQPage",
      "mainEntity" => pairs.map do |q, a|
        { "@type" => "Question", "name" => q,
          "acceptedAnswer" => { "@type" => "Answer", "text" => a } }
      end
    }
  end
end
