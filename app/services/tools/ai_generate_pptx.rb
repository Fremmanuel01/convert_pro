require 'zip'
require 'json'

module Tools
  class AiGeneratePptx < BaseTool
    CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
    CLAUDE_MODEL   = "claude-opus-4-6"

    # Slide dimensions: 16:9 widescreen in EMU (1 inch = 914400 EMU)
    W = 12192000  # 13.33 inches
    H =  6858000  # 7.5 inches

    # Brand palette
    C_DARK   = "0F172A"  # slate-950
    C_INDIGO = "4F46E5"  # indigo-600
    C_WHITE  = "FFFFFF"
    C_SLATE  = "1E293B"  # slate-800
    C_MID    = "94A3B8"  # slate-400
    C_BAR    = "818CF8"  # indigo-400
    C_BG     = "F8FAFC"  # slate-50

    protected

    def process(input_paths)
      prompt = @conversion.options&.dig('prompt')
      raise ExecutionError, "Please describe the presentation you'd like to create." if prompt.blank?

      data     = call_claude_api(prompt)
      title    = data['title']    || prompt
      subtitle = data['subtitle'] || 'AI-Generated Presentation'
      slides   = Array(data['slides'])

      raise ExecutionError, "AI returned no slides. Please try a more specific topic." if slides.empty?

      safe_name  = title.gsub(/[^a-zA-Z0-9 ]/, '').strip.gsub(/\s+/, '_').first(40).presence || 'presentation'
      output_path = tmp_path("#{safe_name}.pptx")

      build_pptx(title, subtitle, slides, output_path)
      output_path
    end

    private

    # ── Claude API ─────────────────────────────────────────────────────────────

    def call_claude_api(topic)
      api_key = ENV['ANTHROPIC_API_KEY']
      raise ExecutionError, "Anthropic API key not configured (ANTHROPIC_API_KEY)." if api_key.blank?

      user_prompt = <<~PROMPT
        Create a professional PowerPoint presentation about: #{topic}

        Return ONLY valid JSON (no markdown fences, no explanation) with this exact structure:
        {
          "title": "Presentation Title",
          "subtitle": "Brief subtitle or tagline",
          "slides": [
            { "title": "Slide Title", "bullets": ["Point one", "Point two", "Point three"] }
          ]
        }

        Requirements:
        - 6 to 9 content slides
        - 3 to 5 concise bullet points per slide (max 12 words each)
        - First content slide: overview or agenda
        - Last slide: conclusion or call to action
        - Professional, insightful, well-structured content
      PROMPT

      response = HTTParty.post(
        CLAUDE_API_URL,
        headers: {
          'Content-Type'    => 'application/json',
          'x-api-key'       => api_key,
          'anthropic-version' => '2023-06-01'
        },
        body: {
          model:      CLAUDE_MODEL,
          max_tokens: 4096,
          messages:   [{ role: 'user', content: user_prompt }]
        }.to_json,
        timeout: 90
      )

      unless response.success?
        msg = response.dig('error', 'message') || "HTTP #{response.code}"
        raise ExecutionError, "Claude API error: #{msg}"
      end

      raw = response.dig('content', 0, 'text').to_s.strip
      raw = raw.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '').strip
      JSON.parse(raw)
    rescue JSON::ParserError => e
      raise ExecutionError, "Could not parse AI response as JSON: #{e.message}"
    rescue HTTParty::Error, Net::ReadTimeout, SocketError => e
      raise ExecutionError, "Network error connecting to Claude API: #{e.message}"
    end

    # ── PPTX Builder ───────────────────────────────────────────────────────────

    def build_pptx(title, subtitle, slides, output_path)
      total = slides.length + 1  # +1 for title slide

      Zip::OutputStream.open(output_path) do |zip|
        write_content_types(zip, total)
        write_root_rels(zip)
        write_presentation(zip, total)
        write_presentation_rels(zip, total)
        write_theme(zip)
        write_slide_master(zip)
        write_slide_master_rels(zip)
        write_slide_layouts(zip)

        # Slide 1: title
        write_title_slide(zip, 1, title, subtitle)
        write_slide_rels(zip, 1, 1)

        # Slides 2+: content
        slides.each_with_index do |slide, i|
          n = i + 2
          write_content_slide(zip, n, slide['title'].to_s, Array(slide['bullets']))
          write_slide_rels(zip, n, 2)
        end
      end
    end

    def write_content_types(zip, slide_count)
      overrides = (1..slide_count).map { |i|
        %(<Override PartName="/ppt/slides/slide#{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>)
      }.join("\n  ")

      zip.put_next_entry('[Content_Types].xml')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
          <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
          <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
          <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
          <Override PartName="/ppt/slideLayouts/slideLayout2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
          #{overrides}
        </Types>
      XML
    end

    def write_root_rels(zip)
      zip.put_next_entry('_rels/.rels')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
        </Relationships>
      XML
    end

    def write_presentation(zip, slide_count)
      slide_ids = (1..slide_count).map.with_index(2) { |i, rIdx|
        %(<p:sldId id="#{255 + i}" r:id="rId#{rIdx}"/>)
      }.join("\n    ")

      zip.put_next_entry('ppt/presentation.xml')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
                        xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                        saveSubsetFonts="1">
          <p:sldMasterIdLst>
            <p:sldMasterId id="2147483648" r:id="rId1"/>
          </p:sldMasterIdLst>
          <p:sldIdLst>
            #{slide_ids}
          </p:sldIdLst>
          <p:sldSz cx="#{W}" cy="#{H}" type="custom"/>
          <p:notesSz cx="6858000" cy="9144000"/>
        </p:presentation>
      XML
    end

    def write_presentation_rels(zip, slide_count)
      slide_rels = (1..slide_count).map { |i|
        %(<Relationship Id="rId#{i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide#{i}.xml"/>)
      }.join("\n  ")

      zip.put_next_entry('ppt/_rels/presentation.xml.rels')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
          #{slide_rels}
        </Relationships>
      XML
    end

    def write_theme(zip)
      zip.put_next_entry('ppt/theme/theme1.xml')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="OfficedocTools">
          <a:themeElements>
            <a:clrScheme name="OfficedocTools">
              <a:dk1><a:srgbClr val="#{C_DARK}"/></a:dk1>
              <a:lt1><a:srgbClr val="#{C_WHITE}"/></a:lt1>
              <a:dk2><a:srgbClr val="#{C_SLATE}"/></a:dk2>
              <a:lt2><a:srgbClr val="F1F5F9"/></a:lt2>
              <a:accent1><a:srgbClr val="#{C_INDIGO}"/></a:accent1>
              <a:accent2><a:srgbClr val="#{C_BAR}"/></a:accent2>
              <a:accent3><a:srgbClr val="06B6D4"/></a:accent3>
              <a:accent4><a:srgbClr val="10B981"/></a:accent4>
              <a:accent5><a:srgbClr val="F59E0B"/></a:accent5>
              <a:accent6><a:srgbClr val="EF4444"/></a:accent6>
              <a:hlink><a:srgbClr val="6366F1"/></a:hlink>
              <a:folHlink><a:srgbClr val="4338CA"/></a:folHlink>
            </a:clrScheme>
            <a:fontScheme name="OfficedocTools">
              <a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>
              <a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>
            </a:fontScheme>
            <a:fmtScheme name="OfficedocTools">
              <a:fillStyleLst>
                <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
                <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
                <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
              </a:fillStyleLst>
              <a:lnStyleLst>
                <a:ln w="6350" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>
                <a:ln w="12700" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>
                <a:ln w="19050" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>
              </a:lnStyleLst>
              <a:effectStyleLst>
                <a:effectStyle><a:effectLst/></a:effectStyle>
                <a:effectStyle><a:effectLst/></a:effectStyle>
                <a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="35000"/></a:srgbClr></a:outerShdw></a:effectLst></a:effectStyle>
              </a:effectStyleLst>
              <a:bgFillStyleLst>
                <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
                <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
                <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
              </a:bgFillStyleLst>
            </a:fmtScheme>
          </a:themeElements>
        </a:theme>
      XML
    end

    def write_slide_master(zip)
      zip.put_next_entry('ppt/slideMasters/slideMaster1.xml')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sldMaster xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
                     xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                     xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <p:cSld>
            <p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg>
            <p:spTree>
              <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
              <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="#{W}" cy="#{H}"/><a:chOff x="0" y="0"/><a:chExt cx="#{W}" cy="#{H}"/></a:xfrm></p:grpSpPr>
            </p:spTree>
          </p:cSld>
          <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
          <p:sldLayoutIdLst>
            <p:sldLayoutId id="2147483649" r:id="rId1"/>
            <p:sldLayoutId id="2147483650" r:id="rId2"/>
          </p:sldLayoutIdLst>
          <p:txStyles>
            <p:titleStyle><a:lvl1pPr algn="l"><a:defRPr lang="en-US" sz="3200" dirty="0"/></a:lvl1pPr></p:titleStyle>
            <p:bodyStyle><a:lvl1pPr marL="342900" indent="-342900"><a:defRPr lang="en-US" sz="2000" dirty="0"/></a:lvl1pPr></p:bodyStyle>
            <p:otherStyle><a:defPPr><a:defRPr lang="en-US" dirty="0"/></a:defPPr></p:otherStyle>
          </p:txStyles>
        </p:sldMaster>
      XML
    end

    def write_slide_master_rels(zip)
      zip.put_next_entry('ppt/slideMasters/_rels/slideMaster1.xml.rels')
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout2.xml"/>
          <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
        </Relationships>
      XML
    end

    def write_slide_layouts(zip)
      [1, 2].each do |n|
        zip.put_next_entry("ppt/slideLayouts/slideLayout#{n}.xml")
        zip.write(<<~XML.strip)
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <p:sldLayout xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
                       xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                       xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                       type="obj">
            <p:cSld>
              <p:spTree>
                <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
                <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="#{W}" cy="#{H}"/><a:chOff x="0" y="0"/><a:chExt cx="#{W}" cy="#{H}"/></a:xfrm></p:grpSpPr>
              </p:spTree>
            </p:cSld>
            <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
          </p:sldLayout>
        XML

        zip.put_next_entry("ppt/slideLayouts/_rels/slideLayout#{n}.xml.rels")
        zip.write(<<~XML.strip)
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
          </Relationships>
        XML
      end
    end

    def write_slide_rels(zip, slide_num, layout_num)
      zip.put_next_entry("ppt/slides/_rels/slide#{slide_num}.xml.rels")
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout#{layout_num}.xml"/>
        </Relationships>
      XML
    end

    # ── Slide Templates ────────────────────────────────────────────────────────

    def write_title_slide(zip, n, title, subtitle)
      zip.put_next_entry("ppt/slides/slide#{n}.xml")
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
               xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
               xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <p:cSld>
            <p:bg>
              <p:bgPr><a:solidFill><a:srgbClr val="#{C_DARK}"/></a:solidFill><a:effectLst/></p:bgPr>
            </p:bg>
            <p:spTree>
              <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
              <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="#{W}" cy="#{H}"/><a:chOff x="0" y="0"/><a:chExt cx="#{W}" cy="#{H}"/></a:xfrm></p:grpSpPr>
              #{solid_rect(2, "LeftBar", 0, 0, 180000, H, C_INDIGO)}
              #{solid_rect(3, "BottomBar", 0, H - 120000, W, 120000, C_INDIGO)}
              #{text_box(4, "Title", 457200, 1500000, W - 914400, 2400000, xe(title), C_WHITE, 4800, true, "l")}
              #{text_box(5, "Subtitle", 457200, 4000000, W - 914400, 900000, xe(subtitle), C_BAR, 2400, false, "l")}
              #{text_box(6, "Brand", 457200, H - 380000, 3000000, 280000, "OfficedocTools", C_MID, 1400, false, "l")}
            </p:spTree>
          </p:cSld>
          <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
        </p:sld>
      XML
    end

    def write_content_slide(zip, n, title, bullets)
      zip.put_next_entry("ppt/slides/slide#{n}.xml")
      zip.write(<<~XML.strip)
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
               xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
               xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <p:cSld>
            <p:bg>
              <p:bgPr><a:solidFill><a:srgbClr val="#{C_BG}"/></a:solidFill><a:effectLst/></p:bgPr>
            </p:bg>
            <p:spTree>
              <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
              <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="#{W}" cy="#{H}"/><a:chOff x="0" y="0"/><a:chExt cx="#{W}" cy="#{H}"/></a:xfrm></p:grpSpPr>
              #{solid_rect(2, "Header", 0, 0, W, 1143000, C_DARK)}
              #{solid_rect(3, "AccentBar", 0, 1143000, W, 80000, C_INDIGO)}
              #{text_box(4, "Title", 457200, 228600, W - 914400, 685800, xe(title), C_WHITE, 3000, true, "l")}
              #{bullets_box(5, 457200, 1350000, W - 914400, H - 1550000, bullets)}
              #{text_box(6, "SlideNum", W - 600000, H - 300000, 457200, 228600, (n - 1).to_s, C_MID, 1400, false, "r")}
            </p:spTree>
          </p:cSld>
          <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
        </p:sld>
      XML
    end

    # ── Shape Helpers ──────────────────────────────────────────────────────────

    def solid_rect(id, name, x, y, cx, cy, color)
      <<~XML
        <p:sp>
          <p:nvSpPr>
            <p:cNvPr id="#{id}" name="#{name}"/>
            <p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>
            <p:nvPr/>
          </p:nvSpPr>
          <p:spPr>
            <a:xfrm><a:off x="#{x}" y="#{y}"/><a:ext cx="#{cx}" cy="#{cy}"/></a:xfrm>
            <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
            <a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>
            <a:ln><a:noFill/></a:ln>
          </p:spPr>
          <p:txBody><a:bodyPr/><a:lstStyle/><a:p/></p:txBody>
        </p:sp>
      XML
    end

    def text_box(id, name, x, y, cx, cy, text, color, sz, bold, align)
      b = bold ? "<a:b/>" : ""
      <<~XML
        <p:sp>
          <p:nvSpPr>
            <p:cNvPr id="#{id}" name="#{name}"/>
            <p:cNvSpPr txBox="1"><a:spLocks noGrp="1"/></p:cNvSpPr>
            <p:nvPr/>
          </p:nvSpPr>
          <p:spPr>
            <a:xfrm><a:off x="#{x}" y="#{y}"/><a:ext cx="#{cx}" cy="#{cy}"/></a:xfrm>
            <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
            <a:noFill/>
          </p:spPr>
          <p:txBody>
            <a:bodyPr wrap="square" lIns="0" rIns="0" tIns="0" bIns="0" anchor="ctr"/>
            <a:lstStyle/>
            <a:p>
              <a:pPr algn="#{align}"/>
              <a:r>
                <a:rPr lang="en-US" sz="#{sz}" dirty="0">
                  #{b}
                  <a:solidFill><a:srgbClr val="#{color}"/></a:solidFill>
                </a:rPr>
                <a:t>#{text}</a:t>
              </a:r>
            </a:p>
          </p:txBody>
        </p:sp>
      XML
    end

    def bullets_box(id, x, y, cx, cy, bullets)
      paras = bullets.map { |b|
        <<~XML
          <a:p>
            <a:pPr>
              <a:lnSpc><a:spcPct val="115%"/></a:lnSpc>
              <a:spcBef><a:spcPts val="600"/></a:spcBef>
            </a:pPr>
            <a:r>
              <a:rPr lang="en-US" sz="2200" dirty="0">
                <a:solidFill><a:srgbClr val="#{C_SLATE}"/></a:solidFill>
              </a:rPr>
              <a:t>#{xe("▸  #{b.to_s}")}</a:t>
            </a:r>
          </a:p>
        XML
      }.join

      <<~XML
        <p:sp>
          <p:nvSpPr>
            <p:cNvPr id="#{id}" name="Content"/>
            <p:cNvSpPr txBox="1"><a:spLocks noGrp="1"/></p:cNvSpPr>
            <p:nvPr/>
          </p:nvSpPr>
          <p:spPr>
            <a:xfrm><a:off x="#{x}" y="#{y}"/><a:ext cx="#{cx}" cy="#{cy}"/></a:xfrm>
            <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
            <a:noFill/>
          </p:spPr>
          <p:txBody>
            <a:bodyPr wrap="square" lIns="91440" rIns="91440" tIns="91440" bIns="91440" anchor="t"/>
            <a:lstStyle/>
            #{paras}
          </p:txBody>
        </p:sp>
      XML
    end

    def xe(str)
      str.to_s
         .gsub('&', '&amp;')
         .gsub('<', '&lt;')
         .gsub('>', '&gt;')
         .gsub('"', '&quot;')
    end
  end
end
